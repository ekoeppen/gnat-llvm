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

with System;        use System;
with System.OS_Lib; use System.OS_Lib;

with Table;

package GNATLLVM.Codegen is

   Filename        : String_Access  := new String'("");
   --  Filename to compile.

   type Code_Generation_Kind is
     (Dump_IR, Write_IR, Write_BC, Write_Assembly, Write_Object, Write_C,
      None);

   Code_Generation : Code_Generation_Kind := Write_Object;
   --  Type of code generation we're doing

   Emit_C          : Boolean        := False;
   --  True if -emit-c was specified

   CPU             : String_Access  := new String'("generic");
   --  Name of the specific CPU for this compilation.

   Features        : String_Access  := new String'("");
   --  Features to enable or disable for this target

   Target_Triple   : String_Access  := new String'(Get_Default_Target_Triple);
   --  Name of the target for this compilation

   Code_Gen_Level  : Code_Gen_Opt_Level_T := Code_Gen_Level_None;
   --  Optimization level for codegen

   Code_Model      : Code_Model_T   := Code_Model_Default;
   Reloc_Mode      : Reloc_Mode_T   := Reloc_Default;
   --  Code generation options

   Code_Opt_Level  : Int            := 0;
   Size_Opt_Level  : Int            := 0;
   --  Optimization levels

   DSO_Preemptable : Boolean        := False;
   --  Indicates that the function or variable may be replaced by a symbol
   --  from outside the linkage unit at runtime.  clang derives this from
   --  a complex set of machine-dependent criterial, but the need for
   --  this is rare enough that we'll just provide a switch instead.

   No_Strict_Aliasing_Flag : Boolean := False;
   C_Style_Aliasing        : Boolean := False;
   No_Inlining             : Boolean := False;
   No_Unroll_Loops         : Boolean := False;
   No_Loop_Vectorization   : Boolean := False;
   No_SLP_Vectorization    : Boolean := False;
   Merge_Functions         : Boolean := True;
   PrepareForThinLTO       : Boolean := False;
   PrepareForLTO           : Boolean := False;
   RerollLoops             : Boolean := False;
   No_Tail_Calls           : Boolean := False;
   --  Switch options for optimization

   Force_Activation_Record_Parameter : Boolean := False;
   --  Indicates that we need to force all subprograms to have an activation
   --  record parameter.  We need to do this for targets, such as WebAssembly,
   --  that require strict parameter agreement between calls and declarations.

   Optimize_IR           : Boolean := True;
   --  True if we should optimize IR before writing it out when optimization
   --  is enabled.

   package Switch_Table is new Table.Table
     (Table_Component_Type => String_Access,
      Table_Index_Type     => Interfaces.C.int,
      Table_Low_Bound      => 1,
      Table_Initial        => 5,
      Table_Increment      => 1,
      Table_Name           => "Switch_Table");

   procedure Scan_Command_Line;
   --  Scan operands relevant to code generation

   procedure Initialize_LLVM_Target;
   --  Initialize all the data structures specific to the LLVM target code
   --  generation.

   procedure Generate_Code (GNAT_Root : Node_Id);
   --  Generate LLVM code from what we've compiled with a node for error
   --  messages.

   function Is_Back_End_Switch (Switch : String) return Boolean;
   --  Return True if Switch is a switch known to the back end

end GNATLLVM.Codegen;
