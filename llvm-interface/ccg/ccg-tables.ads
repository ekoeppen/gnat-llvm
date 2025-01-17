------------------------------------------------------------------------------
--                              C C G                                       --
--                                                                          --
--                     Copyright (C) 2020-2021, AdaCore                     --
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

with LLVM.Core; use LLVM.Core;

with CCG.Helper; use CCG.Helper;
with CCG.Strs;   use CCG.Strs;

package CCG.Tables is

   --  This package contains the tables used by CCG to record data about
   --  LLVM values and the subprograms used to access and set such data.

   --  Get and set attributes we record of LLVM values, types, and
   --  basic blocks.

   function Get_C_Value             (V : Value_T) return Str
     with Pre => Present (V), Inline;
   --  If Present, a string that represents the value of the Value_T

   function Get_Is_Variable         (V : Value_T) return Boolean
   --  True if V represents a variable declared at source level
     with Pre => Present (V), Inline;

   function Get_Is_Decl_Output      (V : Value_T) return Boolean
     with Pre => Present (V), Inline;
   --  True if we wrote any needed decl for this value

   function Get_Is_Temp_Decl_Output (V : Value_T) return Boolean
     with Pre => Is_APHI_Node (V), Inline;
   --  Likewise, but applies to the temporary needed for a PHI instruction

   function Get_Is_LHS              (V : Value_T) return Boolean
     with Pre => Present (V), Inline;
   --  True if this value represents an LHS. This is usually either a
   --  global variable or an alloca in the entry block. In that case, from
   --  a C perspective, a use of a value in LLVM IR represents the address
   --  of the value; only "load" or "store" instruction actually accesses
   --  the value. It can also be the result of a GEP instruction.

   function Get_Is_Constant         (V : Value_T) return Boolean
     with Pre => Present (V), Inline;
   --  True if this value is a constant and was declared that way
   --  in C.

   function Get_Is_Unsigned         (V : Value_T) return Boolean
     with Pre => Present (V), Inline;
   --  True if this value represents a variable that's unsigned

   function Get_Is_Used             (V : Value_T) return Boolean
     with Pre => Present (V), Inline;
   --  True if this value represents a variable that has been used in an
   --  expression.

   procedure Set_C_Value            (V : Value_T; S : Str)
     with Pre => Present (V), Post => Get_C_Value (V) = S, Inline;
   procedure Set_Is_Variable        (V : Value_T; B : Boolean := True)
     with Pre  => Present (V), Post => Get_Is_Variable (V) = B, Inline;
   procedure Set_Is_Decl_Output      (V : Value_T; B : Boolean := True)
     with Pre => Present (V), Post => Get_Is_Decl_Output (V) = B, Inline;
   procedure Set_Is_Temp_Decl_Output (V : Value_T; B : Boolean := True)
     with Pre => Is_APHI_Node (V), Post => Get_Is_Temp_Decl_Output (V) = B,
          Inline;
   procedure Set_Is_LHS              (V : Value_T; B : Boolean := True)
     with Pre => Present (V), Post => Get_Is_LHS (V) = B, Inline;
   procedure Set_Is_Constant         (V : Value_T; B : Boolean := True)
     with Pre => Present (V), Post => Get_Is_Constant (V) = B, Inline;
   procedure Set_Is_Unsigned        (V : Value_T; B : Boolean := True)
     with Pre => Present (V), Post => Get_Is_Unsigned (V) = B, Inline;
   procedure Set_Is_Used             (V : Value_T; B : Boolean := True)
     with Pre => Present (V), Post => Get_Is_Used (V) = B, Inline;

   function Get_Is_Typedef_Output        (T : Type_T) return Boolean
     with Pre => Present (T), Inline;
   --  True if this is a type either for which we don't write a typedef
   --  or if it is and we've written that typedef previously.

   function Get_Is_Return_Typedef_Output (T : Type_T) return Boolean
     with Pre => Present (T), Inline;
   --  True if this is an array type and we've written the struct type
   --  that we use for the return type of a function returning this type.

   function Get_Is_Incomplete_Output     (T : Type_T) return Boolean
     with Pre => Present (T), Inline;
   --  True if this is a struct type and we've just written the struct
   --  definition without fields (an incomplete type).

   function Get_Are_Writing_Typedef      (T : Type_T) return Boolean
     with Pre => Present (T), Inline;
   --  True if we're in the process of writing a typedef

   procedure Set_Is_Typedef_Output        (T : Type_T; B : Boolean := True)
     with Pre  => Present (T), Post => Get_Is_Typedef_Output (T) = B, Inline;
   procedure Set_Is_Return_Typedef_Output (T : Type_T; B : Boolean := True)
     with Pre  => Present (T), Post => Get_Is_Return_Typedef_Output (T) = B,
          Inline;
   procedure Set_Is_Incomplete_Output     (T : Type_T; B : Boolean := True)
     with Pre  => Present (T), Post => Get_Is_Incomplete_Output (T) = B,
          Inline;
   procedure Set_Are_Writing_Typedef      (T : Type_T; B : Boolean := True)
     with Pre  => Present (T), Post => Get_Are_Writing_Typedef (T) = B, Inline;

   function Get_Was_Output (BB : Basic_Block_T) return Boolean
     with Pre => Present (BB), Inline;
   procedure Set_Was_Output (BB : Basic_Block_T; B : Boolean := True)
     with Pre  => Present (BB), Post => Get_Was_Output (BB) = B, Inline;

   procedure Delete_Value_Info (V : Value_T) with Convention => C;
   --  Delete all information previously stored for V

   --  Define functions to return (and possibly create) an ordinal to use
   --  as part of the name for a value, type, or basic block.

   function Get_Output_Idx (V : Value_T) return Nat
     with Pre => Present (V), Post => Get_Output_Idx'Result /= 0, Inline;
   function Get_Output_Idx (T : Type_T) return Nat
     with Pre => Present (T), Post => Get_Output_Idx'Result /= 0, Inline;
   function Get_Output_Idx (BB : Basic_Block_T) return Nat
     with Pre => Present (BB), Post => Get_Output_Idx'Result /= 0, Inline;
   function Get_Output_Idx                      return Nat
     with Post => Get_Output_Idx'Result /= 0, Inline;

   procedure Maybe_Write_Typedef (T : Type_T; Incomplete : Boolean := False)
     with Pre  => Present (T),
          Post => Get_Is_Typedef_Output (T) or else Get_Are_Writing_Typedef (T)
                  or else (Incomplete and then Get_Is_Incomplete_Output (T));
   --  See if we need to write a typedef for T and write one if so. If
   --  Incomplete is True, all we need is the initial portion of a struct
   --  definition.

   --  Provide a set of functions to reference an Str that contains just
   --  a value or contains exactly one value.

   function Contains_One_Value (S : Str) return Boolean is
     (Present (Single_Value (S)))
     with Pre => Present (S);
   function "+" (S : Str) return Value_T is
     (Single_Value (S))
     with Pre => Contains_One_Value (S), Inline;
   function Get_Is_LHS (S : Str) return Boolean is
     (Get_Is_LHS (+S))
     with Pre => Contains_One_Value (S);
   function Get_Is_Constant (S : Str) return Boolean is
     (Get_Is_Constant (+S))
     with Pre => Contains_One_Value (S);
   function Get_C_Value (S : Str) return Str is
     (Get_C_Value (+S))
     with Pre => Contains_One_Value (S);
   function Type_Of (S : Str) return Type_T is
     (Type_Of (+S))
     with Pre => Contains_One_Value (S);
   function Get_Type_Kind (S : Str) return Type_Kind_T is
     (Get_Type_Kind (Type_Of (S)))
     with Pre => Contains_One_Value (S);

end CCG.Tables;
