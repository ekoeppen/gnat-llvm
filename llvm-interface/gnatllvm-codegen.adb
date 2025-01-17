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

with Ada.Command_Line; use Ada.Command_Line;
with Ada.Directories;
with Interfaces;
with Interfaces.C;     use Interfaces.C;

with LLVM.Analysis;   use LLVM.Analysis;
with LLVM.Bit_Writer; use LLVM.Bit_Writer;
with LLVM.Core;       use LLVM.Core;
with LLVM.Debug_Info; use LLVM.Debug_Info;
with LLVM.Support;    use LLVM.Support;

with CCG; use CCG;

with Debug;   use Debug;
with Errout;  use Errout;
with Lib;     use Lib;
with Opt;     use Opt;
with Osint.C; use Osint.C;
with Output;  use Output;
with Switch;  use Switch;

with GNATLLVM.Wrapper; use GNATLLVM.Wrapper;

package body GNATLLVM.Codegen is

   Output_Assembly : Boolean := False;
   --  True if -S was specified

   Emit_LLVM       : Boolean := False;
   --  True if -emit-llvm was specified

   function Output_File_Name (Extension : String) return String;
   --  Return the name of the output file, using the given Extension

   procedure Process_Switch (Switch : String);
   --  Process one command-line switch

   function Get_LLVM_Error_Msg (Msg : Ptr_Err_Msg_Type) return String;
   --  Get the LLVM error message that was stored in Msg

   --------------------
   -- Process_Switch --
   --------------------

   procedure Process_Switch (Switch : String) is
      First   : constant Integer := Switch'First;
      Last    : constant Integer := Switch_Last (Switch);
      Len     : constant Integer := Last - First + 1;
      To_Free : String_Access    := null;

      function Starts_With (S : String) return Boolean is
        (Len > S'Length and then Switch (First .. First + S'Length - 1) = S);
      --  Return True if Switch starts with S

      function Switch_Value (S : String) return String is
        (Switch (S'Length + First .. Last));
      --  Returns the value of a switch known to start with S

      function Add_Maybe_With_Comma (S1, S2 : String) return String is
        ((if S1 = "" then S1 else S1 & ",") & S2);
      --  Concatenate S1 and S2, putting a comma in between if S1 is empty

   begin
      --  ??? At some point, this and Is_Back_End_Switch need to have
      --  some sort of common code.

      if Len > 0 and then Switch (First) /= '-' then
         if Is_Regular_File (Switch) then
            Free (Filename);
            Filename := new String'(Switch);
         end if;

      elsif Switch = "--dump-ir" then
         Code_Generation := Dump_IR;
      elsif Switch = "--dump-bc" or else Switch = "--write-bc" then
         Code_Generation := Write_BC;
      elsif Switch = "-emit-c" then
         Emit_C := True;

         --  Building static dispatch tables causes circular references
         --  in initializers, which there's no way to handle in C.

         Building_Static_Dispatch_Tables := False;

         --  Disable 128bits support for C code generation for now

         Debug_Flag_Dot_HH := True;

         --  Use a simple 32bits target by default for C code generation

         To_Free       := Target_Triple;
         Target_Triple := new String'("i386-linux");

      elsif Switch = "-emit-llvm" then
         Emit_LLVM := True;
      elsif Switch = "-S" then
         Output_Assembly := True;
      elsif Switch = "-g"
        or else (Starts_With ("-g") and then not Starts_With ("-gnat"))
      then
         Emit_Debug_Info := True;
      elsif Switch = "-fstack-check" then
         Do_Stack_Check := True;
      elsif Switch = "-fshort-enums" then
         Short_Enums := True;
      elsif Switch = "-foptimize-ir" then
         Optimize_IR := True;
      elsif Switch = "-fno-optimize-ir" then
         Optimize_IR := False;
      elsif Starts_With ("--target=") then
         To_Free       := Target_Triple;
         Target_Triple := new String'(Switch_Value ("--target="));
      elsif Starts_With ("-mtriple=") then
         To_Free       := Target_Triple;
         Target_Triple := new String'(Switch_Value ("-mtriple="));

      --  -march= and -mcpu= set the CPU to be used. -mtune= does likewise,
      --  but only if we haven't already seen one of the previous two switches

      elsif Starts_With ("-march=") then
         To_Free       := CPU;
         CPU           := new String'(Switch_Value ("-march="));
      elsif Starts_With ("-mcpu=") then
         To_Free       := CPU;
         CPU           := new String'(Switch_Value ("-mcpu="));
      elsif Starts_With ("-mtune=") then
         if CPU.all = "generic" then
            To_Free    := CPU;
            CPU        := new String'(Switch_Value ("-march="));
         end if;

      --  We support -mXXX and -mno-XXX by adding +XXX or -XXX, respectively,
      --  to the list of features.

      elsif Starts_With ("-mno-") then
         To_Free       := Features;
         Features      :=
           new String'(Add_Maybe_With_Comma (Features.all,
                                       "-" & Switch_Value ("-mno-")));
      elsif Starts_With ("-m") then
         To_Free       := Features;
         Features      :=
           new String'(Add_Maybe_With_Comma (Features.all,
                                             "+" & Switch_Value ("-m")));
      elsif Switch = "-O" then
            Code_Opt_Level := 1;
            Code_Gen_Level := Code_Gen_Level_Less;
      elsif Starts_With ("-O") then
         case Switch (First + 2) is
            when '1' =>
               Code_Gen_Level := Code_Gen_Level_Less;
               Code_Opt_Level := 1;
            when '2'  =>
               Code_Gen_Level := Code_Gen_Level_Default;
               Code_Opt_Level := 2;
            when '3' =>
               Code_Gen_Level := Code_Gen_Level_Aggressive;
               Code_Opt_Level := 3;
            when '0' =>
               Code_Gen_Level := Code_Gen_Level_None;
               Code_Opt_Level := 0;
            when 's' =>
               Code_Gen_Level := Code_Gen_Level_Default;
               Code_Opt_Level := 2;
               Size_Opt_Level := 1;
            when 'z' =>
               Code_Gen_Level := Code_Gen_Level_Default;
               Code_Opt_Level := 2;
               Size_Opt_Level := 2;
            when 'f' =>
               if Switch_Value ("-O") = "fast" then
                  Code_Gen_Level := Code_Gen_Level_Aggressive;
                  Code_Opt_Level := 3;
               end if;
            when others =>
               null;
         end case;
      elsif Switch = "-fno-strict-aliasing" then
         No_Strict_Aliasing_Flag := True;
      elsif Switch = "-fc-style-aliasing" then
         C_Style_Aliasing := True;
      elsif Switch = "-fno-unroll-loops" then
         No_Unroll_Loops := True;
      elsif Switch = "-funroll-loops" then
         No_Unroll_Loops := False;
      elsif Switch = "-fno-vectorize" then
         No_Loop_Vectorization := True;
      elsif Switch = "-fvectorize" then
         No_Loop_Vectorization := False;
      elsif Switch = "-fno-slp-vectorize" then
         No_SLP_Vectorization := True;
      elsif Switch = "-fslp-vectorize" then
         No_SLP_Vectorization := False;
      elsif Switch = "-fno-inline" then
         No_Inlining := True;
      elsif Switch = "-fmerge-functions" then
         Merge_Functions := True;
      elsif Switch = "-fno-merge-functions" then
         Merge_Functions := False;
      elsif Switch = "-fno-lto" then
         PrepareForThinLTO := False;
         PrepareForLTO     := False;
      elsif Switch = "-flto" or else Switch = "-flto=full" then
         PrepareForThinLTO := False;
         PrepareForLTO     := True;
      elsif Switch = "-flto=thin" then
         PrepareForThinLTO := True;
         PrepareForLTO     := False;
      elsif Switch = "-freroll-loops" then
         RerollLoops := True;
      elsif Switch = "-fno-reroll-loops" then
         RerollLoops := False;
      elsif Switch = "-fno-optimize-sibling-calls" then
         No_Tail_Calls := True;
      elsif Switch = "-fforce-activation-record-parameter" then
         Force_Activation_Record_Parameter := True;
      elsif Switch = "-fno-force-activation-record-parameter" then
         Force_Activation_Record_Parameter := False;
      elsif Switch = "-mdso-preemptable" then
         DSO_Preemptable := True;
      elsif Switch = "-mdso-local" then
         DSO_Preemptable := False;
      elsif Switch = "-mcode-model=small" then
         Code_Model := Code_Model_Small;
      elsif Switch = "-mcode-model=kernel" then
         Code_Model := Code_Model_Kernel;
      elsif Switch = "-mcode-model=medium" then
         Code_Model := Code_Model_Medium;
      elsif Switch = "-mcode-model=large" then
         Code_Model := Code_Model_Large;
      elsif Switch = "-mcode-model=default" then
         Code_Model := Code_Model_Default;
      elsif Switch = "-mrelocation-model=static" then
         Reloc_Mode := Reloc_Static;
      elsif Switch = "-fPIC" or else Switch = "-mrelocation-model=pic" then
         Reloc_Mode := Reloc_PIC;
      elsif Switch = "-mrelocation-model=dynamic-no-pic" then
         Reloc_Mode := Reloc_Dynamic_No_Pic;
      elsif Switch = "-mrelocation-model=default" then
         Reloc_Mode := Reloc_Default;
      elsif Starts_With ("-llvm-") then
         Switch_Table.Append (new String'(Switch_Value ("-llvm")));
      end if;

      --  Free string that we replaced above, if any

      Free (To_Free);

   end Process_Switch;

   -----------------------
   -- Scan_Command_Line --
   -----------------------

   procedure Scan_Command_Line is
   begin
      --  Scan command line for relevant switches and initialize LLVM
      --  target.

      for J in 1 .. Argument_Count loop
         Process_Switch (Argument (J));
      end loop;
   end Scan_Command_Line;

   ------------------------
   -- Get_LLVM_Error_Msg --
   ------------------------

   function Get_LLVM_Error_Msg (Msg : Ptr_Err_Msg_Type) return String is
      Err_Msg_Length : Integer := Msg'Length;
   begin
      for J in Err_Msg_Type'Range loop
         if Msg (J) = ASCII.NUL then
            Err_Msg_Length := J - 1;
            exit;
         end if;
      end loop;

      return Msg (1 .. Err_Msg_Length);
   end Get_LLVM_Error_Msg;

   ----------------------------
   -- Initialize_LLVM_Target --
   ----------------------------

   procedure Initialize_LLVM_Target is
      Num_Builtin : constant := 3;

      type    Addr_Arr     is array (Interfaces.C.int range <>) of Address;
      subtype Switch_Addrs is Addr_Arr (1 .. Switch_Table.Last + Num_Builtin);

      Opt0        : constant String   := "filename" & ASCII.NUL;
      Opt1        : constant String   := "-enable-shrink-wrap=0" & ASCII.NUL;
      Opt2        : constant String   :=
        "-generate-arange-section" & ASCII.NUL;
      Addrs       : Switch_Addrs      :=
        (1 => Opt0'Address, 2 => Opt1'Address, 3 => Opt2'Address,
         others => <>);
      Ptr_Err_Msg : aliased Ptr_Err_Msg_Type;
      TT_First    : constant Integer  := Target_Triple'First;

   begin
      --  Add any LLVM parameters to the list of switches

      for J in 1 .. Switch_Table.Last loop
         Addrs (J + Num_Builtin) := Switch_Table.Table (J).all'Address;
      end loop;

      Parse_Command_Line_Options (Switch_Table.Last + Num_Builtin,
                                  Addrs'Address, "");

      --  Finalize our compilation mode now that all switches are parsed

      if Emit_LLVM then
         Code_Generation := (if Output_Assembly then Write_IR else Write_BC);
      elsif Output_Assembly then
         Code_Generation := Write_Assembly;
      elsif Emit_C then
         Code_Generation := Write_C;

         --  -g when emitting C means to write #line directives, not to
         --  write LLVM debug information.
         --  ??? So for now, just turn it off.

         Emit_Debug_Info := False;
      end if;

      --  Initialize the translation environment

      Initialize_LLVM;
      Context        := Get_Global_Context;
      IR_Builder     := Create_Builder_In_Context (Context);
      MD_Builder     := Create_MDBuilder_In_Context (Context);
      Module         :=
        Module_Create_With_Name_In_Context (Filename.all, Context);
      Convert_Module :=
        Module_Create_With_Name_In_Context ("Convert_Constant", Context);

      if Get_Target_From_Triple
        (Target_Triple.all, LLVM_Target'Address, Ptr_Err_Msg'Address)
      then
         Write_Str
           ("cannot set target to " & Target_Triple.all & ": " &
            Get_LLVM_Error_Msg (Ptr_Err_Msg));
         Write_Eol;
         OS_Exit (4);
      end if;

      Target_Machine    :=
        Create_Target_Machine
          (T          => LLVM_Target,
           Triple     => Target_Triple.all,
           CPU        => CPU.all,
           Features   => Features.all,
           Level      => Code_Gen_Level,
           Reloc      => Reloc_Mode,
           Code_Model => Code_Model);

      Module_Data_Layout := Create_Target_Data_Layout (Target_Machine);
      Set_Target             (Module, Target_Triple.all);
      Set_Module_Data_Layout (Module, Module_Data_Layout);

      --  ??? Replace this by a parameter in system.ads or target.atp

      if Target_Triple (TT_First .. TT_First + 3) = "wasm" then
         Force_Activation_Record_Parameter := True;
      end if;
   end Initialize_LLVM_Target;

   -------------------
   -- Generate_Code --
   -------------------

   procedure Generate_Code (GNAT_Root : Node_Id) is
      Verified : Boolean := True;
      Err_Msg  : aliased Ptr_Err_Msg_Type;

   begin
      --  We always want to write IR, even if there were errors.
      --  First verify the translation unless we're just processing
      --  for decls.

      if not Decls_Only then
         Verified :=
           not Verify_Module (Module, Print_Message_Action, Null_Address);
      end if;

      --  Unless just writing IR, suppress doing anything else if it fails
      --  or there's an error.

      if (Serious_Errors_Detected /= 0 or else not Verified)
        and then Code_Generation not in Dump_IR | Write_IR | Write_BC
      then
         Code_Generation := None;
      end if;

      --  If we're generating code or being asked to optimize IR before
      --  writing it, perform optimization. But don't do this if just
      --  generating decls.

      if not Decls_Only
        and then (Code_Generation in Write_Assembly | Write_Object | Write_C
                    or else Optimize_IR)
      then
         LLVM_Optimize_Module
           (Module, Target_Machine,
            Code_Opt_Level        => Code_Opt_Level,
            Size_Opt_Level        => Size_Opt_Level,
            No_Inlining           => No_Inlining,
            No_Unroll_Loops       => No_Unroll_Loops,
            No_Loop_Vectorization => No_Loop_Vectorization,
            No_SLP_Vectorization  => No_SLP_Vectorization,
            Merge_Functions       => Merge_Functions,
            PrepareForThinLTO     => PrepareForThinLTO,
            PrepareForLTO         => PrepareForLTO,
            RerollLoops           => RerollLoops);
      end if;

      --  Output the translation

      case Code_Generation is
         when Dump_IR =>
            Dump_Module (Module);

         when Write_BC =>
            declare
               S : constant String := Output_File_Name (".bc");

            begin
               if Integer (Write_Bitcode_To_File (Module, S)) /= 0 then
                  Error_Msg_N ("could not write `" & S & "`", GNAT_Root);
               end if;
            end;

         when Write_IR =>
            declare
               S : constant String := Output_File_Name (".ll");

            begin
               if Print_Module_To_File (Module, S, Err_Msg'Address) then
                  Error_Msg_N
                    ("could not write `" & S & "`: " &
                       Get_LLVM_Error_Msg (Err_Msg),
                     GNAT_Root);
               end if;
            end;

         when Write_Assembly =>
            declare
               S : constant String := Output_File_Name (".s");

            begin
               if Target_Machine_Emit_To_File
                 (Target_Machine, Module, S, Assembly_File, Err_Msg'Address)
               then
                  Error_Msg_N
                    ("could not write `" & S & "`: " &
                       Get_LLVM_Error_Msg (Err_Msg), GNAT_Root);
               end if;
            end;

         when Write_Object =>
            declare
               S : constant String := Output_File_Name (".o");

            begin
               if Target_Machine_Emit_To_File (Target_Machine, Module, S,
                                               Object_File, Err_Msg'Address)
               then
                  Error_Msg_N
                    ("could not write `" & S & "`: " &
                       Get_LLVM_Error_Msg (Err_Msg), GNAT_Root);
               end if;
            end;

         when Write_C =>

            Write_C_Code (Module);

         when None =>
            null;
      end case;

      --  Release the environment

      if Emit_Debug_Info then
         Dispose_DI_Builder (DI_Builder);
      end if;

      Dispose_Builder (IR_Builder);
      Dispose_Module (Module);

      pragma Assert (Verified);
   end Generate_Code;

   ------------------------
   -- Is_Back_End_Switch --
   ------------------------

   First_Call : Boolean := True;

   function Is_Back_End_Switch (Switch : String) return Boolean is
      First : constant Integer := Switch'First;
      Last  : constant Integer  := Switch_Last (Switch);
      Len   : constant Integer  := Last - First + 1;

      function Starts_With (S : String) return Boolean is
        (Len > S'Length and then Switch (First .. First + S'Length - 1) = S);
      --  Return True if Switch starts with S

   begin
      if First_Call then
         First_Call := False;
      end if;

      if not Is_Switch (Switch) then
         return False;
      elsif Switch = "--dump-ir"
        or else Switch = "--dump-bc"
        or else Switch = "--write-bc"
        or else Switch = "-S"
        or else Switch = "-g"
        or else (Starts_With ("-g") and then not Starts_With ("-gnat"))
        or else Starts_With ("--target=")
        or else Starts_With ("-llvm-")
        or else Starts_With ("-emit-")
      then
         return True;
      end if;

      --  For now we allow the -f/-m/-W/-w, -nostdlib and -pipe switches,
      --  even though they will have no effect, though some are handled in
      --  Scan_Command_Line above.  This permits compatibility with
      --  existing scripts.

      return Switch (First + 1) in 'f' | 'm' | 'W' | 'w'
        or else Switch = "-nostdlib" or else Switch = "-pipe";
   end Is_Back_End_Switch;

   ----------------------
   -- Output_File_Name --
   ----------------------

   function Output_File_Name (Extension : String) return String is
   begin
      if not Output_File_Name_Present then
         return
           Ada.Directories.Base_Name
             (Get_Name_String (Name_Id (Unit_File_Name (Main_Unit))))
           & Extension;

      --  The Output file name was specified in the -o argument

      else
         --  Locate the last dot to remove the extension of native platforms
         --  (for example, file.o).

         declare
            S : constant String := Get_Output_Object_File_Name;
         begin
            for J in reverse S'Range loop
               if S (J) = '.' then
                  return S (S'First .. J - 1) & Extension;
               end if;
            end loop;

            return S & Extension;
         end;
      end if;
   end Output_File_Name;

end GNATLLVM.Codegen;
