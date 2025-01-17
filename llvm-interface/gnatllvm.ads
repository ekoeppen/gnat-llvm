------------------------------------------------------------------------------
--                             G N A T - L L V M                            --
--                                                                          --
--                     Copyright (C) 2013-2021, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with System;

with stdint_h; use stdint_h;

with Interfaces.C;
with Interfaces.C.Extensions;

with Atree;    use Atree;
with Einfo;    use Einfo;
with Namet;    use Namet;
with Types;    use Types;
with Uintp;    use Uintp;

with LLVM.Target;         use LLVM.Target;
with LLVM.Target_Machine; use LLVM.Target_Machine;
with LLVM.Types;          use LLVM.Types;

package GNATLLVM is

   --  This package and its children generate LLVM IR from the GNAT tree.
   --  They represent a complete implemention of the Ada language.
   --
   --  We directly call subprograms from the front end and access the data
   --  structures that it creates.  For the most part, our interface to
   --  LLVM is via its C API, which we've converted into Ada specs so we
   --  can call them directly.  However, there are some cases when we need
   --  to call things available only in the LLVM C++ API.  In those cases,
   --  we add functions to llvm_wrapper.cc, which are called from
   --  GNATLLVM.Wrapper.
   --
   --  In order to completely understand these packages, you need to
   --  understand both the structure of the Ada tree and the LLVM IR.
   --
   --  One way to find the right LLVM instruction to generate is to look at
   --  what Clang generates from the corresponding C or C++ code. This can
   --  be done online via http://ellcc.org/demo/index.cgi You can also look
   --  at DragonEgg sources for comparison on how GCC nodes are converted
   --  to LLVM nodes: http://llvm.org/svn/llvm-project/dragonegg/trunk
   --
   --  Unlike gigi, where we build a tree from the GNAT tree, we directly
   --  generate IR from the GNAT tree.  To do this effectively while tracking
   --  where we are, we do three things:
   --
   --  (1) The package GNATLLVM.Environment creates a linkage between GNAT
   --  objects and our objects (see below).
   --
   --  (2) The package GNATLLVM.GLType contains an abstraction that lets us
   --  create variants of types, corresponding to different representations
   --  of those types, such as when padding, biasing, or different
   --  alignment is needed.  We define functions on these GLTypes that
   --  correspond to the same accessors of the underlying GNAT type.
   --
   --  (3) The package GNATLLVM.GLValue defines the values that we pass
   --  around and act on.  This consists of an LLVM Value_T, the GLType
   --  that it's related to, and the nature of the relationship (data,
   --  bounds, address, etc.)  This contains functions to access both
   --  LLVM attributes of the Value_T, but also function to access attibutes
   --  of the related type, including those of the underlying GNAT tree type.
   --
   --  In general, subprograms that start with the name Emit take a GNAT tree
   --  node and generate LLVM IR from it and subprograms that start with
   --  Build take a GL_Value.
   --
   --  We heavily use binary operators on these types, for example to
   --  perform arithmetic operations on GLValues, and use unary + to
   --  convert a value from one form to another, e.g., to extract an LLVM
   --  Value_T or an integer constant from a GL_Value.
   --
   --  Note that it can be very easy to make the error of calling some
   --  function with multiple operands, each of which cause code generation
   --  (which can be something like X + Y if X and Y are non-constant
   --  GLValues).  This will generate correct code, but the precise code
   --  generated will depend on the parameter evaluation order, which is
   --  undefined in Ada.  This unpredictability can cause bootstrap
   --  failures.

   --  This specific package contains very low-level types, objects, and
   --  functions, mostly corresponding to LLVM objects and exists to avoid
   --  circular dependencies between other specs.

   --  Define unsigned and unsigned_long_long here instead of use'ing
   --  Interfaces.C because Int conflicts with the definition in the front end.

   subtype unsigned is Interfaces.C.unsigned;

   subtype unsigned_long_long is Interfaces.C.Extensions.unsigned_long_long;
   subtype ULL is unsigned_long_long;
   --  Define shorter alias name for easier reading

   subtype LLI is Long_Long_Integer;
   --  Define shorter alias name for easier reading

   function UI_From_LLI is new UI_From_Integral (LLI);
   --  And conversion routine from LLI to Uint

   function "+" (U : Uint) return Int  renames UI_To_Int;
   function "+" (J : LLI)  return Uint  renames UI_From_LLI;
   function "+" (J : Int)  return Uint renames UI_From_Int;
   --  Add operators to easily convert to and from Uints.

   --  The type Bool_T is used for the subprograms provided by the LLVM C
   --  API. But when we call into the C++ API, those use the C type "bool".
   --  So define that here as what it would be in C, a char, and use that,
   --  not Bool_T when calling the wrapper routines that we wrote.

   type LLVM_Bool is range -128 .. 127 with Convention => C;

   type MD_Builder_T is new System.Address;
   --  Metadata builder type: opaque for us

   type Value_Array        is array (Nat range <>) of Value_T;
   type Type_Array         is array (Nat range <>) of Type_T;
   type Basic_Block_Array  is array (Nat range <>) of Basic_Block_T;
   type Metadata_Array     is array (Nat range <>) of Metadata_T;
   type Index_Array        is array (Nat range <>) of unsigned;
   type ULL_Array          is array (Nat range <>) of ULL;
   type Access_Value_Array is access all Value_Array;

   No_Value_T    : constant Value_T       := Value_T (System.Null_Address);
   No_Type_T     : constant Type_T        := Type_T (System.Null_Address);
   No_BB_T       : constant Basic_Block_T :=
     Basic_Block_T (System.Null_Address);
   No_Metadata_T : constant Metadata_T    := Metadata_T (System.Null_Address);
   No_Builder_T  : constant Builder_T     := Builder_T (System.Null_Address);
   No_Module_T   : constant Module_T      := Module_T (System.Null_Address);
   No_Use_T      : constant Use_T         := Use_T (System.Null_Address);
   --  Constant for null objects of various types

   function No (V : Value_T)            return Boolean is (V = No_Value_T);
   function No (T : Type_T)             return Boolean is (T = No_Type_T);
   function No (B : Basic_Block_T)      return Boolean is (B = No_BB_T);
   function No (M : Metadata_T)         return Boolean is (M = No_Metadata_T);
   function No (M : Builder_T)          return Boolean is (M = No_Builder_T);
   function No (N : Name_Id)            return Boolean is (N = No_Name);

   function Present (V : Value_T)       return Boolean is (V /= No_Value_T);
   function Present (T : Type_T)        return Boolean is (T /= No_Type_T);
   function Present (B : Basic_Block_T) return Boolean is (B /= No_BB_T);
   function Present (M : Metadata_T)    return Boolean is (M /= No_Metadata_T);
   function Present (M : Builder_T)     return Boolean is (M /= No_Builder_T);
   function Present (U : Use_T)         return Boolean is (U /= No_Use_T);
   --  Test for presence and absence of fields of LLVM types

   function No      (U : Uint) return Boolean is (U = No_Uint);
   function Present (U : Uint) return Boolean is (U /= No_Uint);
   --  Add presence and absense functions for Uint for consistency

   function Is_Type_Or_Void (E : Entity_Id) return Boolean is
     (Ekind (E) = E_Void or else Is_Type (E));
   --  We can have Etype's that are E_Void for E_Procedure

   --  We have to define GL_Type here so it can be used in GNATLLVM.GLValue,
   --  which GNATLLVM.GLType must reference.

   GL_Type_Low_Bound  : constant := 700_000_000;
   GL_Type_High_Bound : constant := 799_999_999;
   type GL_Type is range GL_Type_Low_Bound .. GL_Type_High_Bound;
   No_GL_Type         : constant GL_Type := GL_Type_Low_Bound;

   function No      (GT : GL_Type) return Boolean is (GT =  No_GL_Type);
   function Present (GT : GL_Type) return Boolean is (GT /= No_GL_Type);

   --  When we tell CCG which fields are part of a struct, we have to
   --  create a unique Id to link the fields and the struct, so define
   --  a type for that purpose.

   Struct_Id_Low_Bound  : constant := 900_000_000;
   Struct_Id_High_Bound : constant := 999_999_999;
   type Struct_Id is range Struct_Id_Low_Bound .. Struct_Id_High_Bound;
   No_Struct_Id         : constant Struct_Id := Struct_Id_Low_Bound;

   type Word_Array is array (Nat range <>) of aliased uint64_t;
   --  Array of words for LLVM construction functions

   Context            : Context_T;
   --  The current LLVM Context

   IR_Builder         : Builder_T;
   --  The current LLVM Instruction builder

   DI_Builder          : DI_Builder_T;
   --  The current LLVM Debug Info builder

   Module             : Module_T;
   --  The LLVM Module being compiled

   LLVM_Target        : Target_T;
   --  The LLVM target for our module

   Target_Machine     : Target_Machine_T;
   --  The LLVM target machine for our module

   MD_Builder         : MD_Builder_T;
   --  The current LLVM Metadata builder

   Module_Data_Layout : Target_Data_T;
   --  LLVM current module data layout.

   Convert_Module     : Module_T;
   --  The module use by Convert_Nonsymbolic_Constant

   Size_GL_Type       : GL_Type   := No_GL_Type;
   Size_T             : Type_T    := No_Type_T;
   --  Types to use for sizes

   Fat_Pointer_Size   : Nat;
   Thin_Pointer_Size  : Nat;
   --  Sizes of fat and thin pointers

   Void_Ptr_T         : Type_T := No_Type_T;
   --  Pointer to arbitrary memory (we use i8 *); equivalent of
   --  Standard_A_Char.

   A_Char_GL_Type    : GL_Type := No_GL_Type;
   Boolean_GL_Type   : GL_Type := No_GL_Type;
   SSI_GL_Type       : GL_Type := No_GL_Type;
   SI_GL_Type        : GL_Type := No_GL_Type;
   Integer_GL_Type   : GL_Type := No_GL_Type;
   LI_GL_Type        : GL_Type := No_GL_Type;
   LLI_GL_Type       : GL_Type := No_GL_Type;
   Void_GL_Type      : GL_Type := No_GL_Type;
   Any_Array_GL_Type : GL_Type := No_GL_Type;
   --  GL_Types for builtin types

   Int_32_GL_Type    : GL_Type := No_GL_Type;
   Int_32_T          : Type_T  := No_Type_T;
   --  Type for 32-bit integers (for GEP indexes)

   Int_64_GL_Type    : GL_Type := No_GL_Type;
   Int_64_T          : Type_T  := No_Type_T;
   --  Type for 64-bit integers, used for lifetime functions.  This may
   --  not be present, in which case we don't generate lifetime function
   --  calls.

   BPU                : Nat;
   UBPU               : ULL;
   Bit_T              : Type_T := No_Type_T;
   Byte_T             : Type_T := No_Type_T;
   Max_Align          : Nat;
   Max_Valid_Align    : Nat;
   Max_Int_Size       : Uint;

   --  GNAT LLVM switches

   Decls_Only      : Boolean := False;
   --  True if just compiling to process and back-annotate decls

   Emit_Debug_Info : Boolean := False;
   --  Whether or not to emit debugging information (-g)

   Do_Stack_Check  : Boolean := False;
   --  If set, check for too-large allocation

   Short_Enums     : Boolean := False;
   --  True if we should use the RM_Size, not Esize, for enums

   subtype Err_Msg_Type is String (1 .. 10000);
   type Ptr_Err_Msg_Type is access all Err_Msg_Type;
   --  Used for LLVM error handling

   function Is_Field (E : Entity_Id) return Boolean is
     (Ekind (E) in E_Component | E_Discriminant)
     with Pre => Present (E);
   --  Return True if E is a field in a record

   --  For use in child packages:
   pragma Warnings (Off);
   use type Interfaces.C.Extensions.unsigned_long_long;
   use type Interfaces.C.unsigned;
   pragma Warnings (On);

end GNATLLVM;
