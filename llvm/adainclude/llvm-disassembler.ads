pragma Style_Checks (Off);

pragma Warnings (Off); with Interfaces.C; use Interfaces.C; pragma Warnings (On);
with Interfaces.C.Strings;
with System;
with LLVM.Disassembler_Types;
with stdint_h;
with stddef_h;

package LLVM.Disassembler is

   LLVMDisassembler_Option_UseMarkup : constant := 1;  --  llvm-11.0.1.src/include/llvm-c/Disassembler.h:75

   LLVMDisassembler_Option_PrintImmHex : constant := 2;  --  llvm-11.0.1.src/include/llvm-c/Disassembler.h:77

   LLVMDisassembler_Option_AsmPrinterVariant : constant := 4;  --  llvm-11.0.1.src/include/llvm-c/Disassembler.h:79

   LLVMDisassembler_Option_SetInstrComments : constant := 8;  --  llvm-11.0.1.src/include/llvm-c/Disassembler.h:81

   LLVMDisassembler_Option_PrintLatency : constant := 16;  --  llvm-11.0.1.src/include/llvm-c/Disassembler.h:83

  --===-- llvm-c/Disassembler.h - Disassembler Public C Interface ---*- C -*-===*|*                                                                            *|
  --|
  --|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
  --|* Exceptions.                                                                *|
  --|* See https://llvm.org/LICENSE.txt for license information.                  *|
  --|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
  --|*                                                                            *|
  --|*===----------------------------------------------------------------------===*|
  --|*                                                                            *|
  --|* This header provides a public interface to a disassembler library.         *|
  --|* LLVM provides an implementation of this interface.                         *|
  --|*                                                                            *|
  --\*===----------------------------------------------------------------------=== 

  --*
  -- * @defgroup LLVMCDisassembler Disassembler
  -- * @ingroup LLVMC
  -- *
  -- * @{
  --  

  --*
  -- * Create a disassembler for the TripleName.  Symbolic disassembly is supported
  -- * by passing a block of information in the DisInfo parameter and specifying the
  -- * TagType and callback functions as described above.  These can all be passed
  -- * as NULL.  If successful, this returns a disassembler context.  If not, it
  -- * returns NULL. This function is equivalent to calling
  -- * LLVMCreateDisasmCPUFeatures() with an empty CPU name and feature set.
  --  

function Create_Disasm
     (Triple_Name    : String;
      Dis_Info       : System.Address;
      Tag_Type       : int;
      Get_Op_Info    : LLVM.Disassembler_Types.Op_Info_Callback_T;
      Symbol_Look_Up : LLVM.Disassembler_Types.Symbol_Lookup_Callback_T)
      return LLVM.Disassembler_Types.Disasm_Context_T;
   function Create_Disasm_C
     (Triple_Name    : Interfaces.C.Strings.chars_ptr;
      Dis_Info       : System.Address;
      Tag_Type       : int;
      Get_Op_Info    : LLVM.Disassembler_Types.Op_Info_Callback_T;
      Symbol_Look_Up : LLVM.Disassembler_Types.Symbol_Lookup_Callback_T)
      return LLVM.Disassembler_Types.Disasm_Context_T;
   pragma Import (C, Create_Disasm_C, "LLVMCreateDisasm");

  --*
  -- * Create a disassembler for the TripleName and a specific CPU.  Symbolic
  -- * disassembly is supported by passing a block of information in the DisInfo
  -- * parameter and specifying the TagType and callback functions as described
  -- * above.  These can all be passed * as NULL.  If successful, this returns a
  -- * disassembler context.  If not, it returns NULL. This function is equivalent
  -- * to calling LLVMCreateDisasmCPUFeatures() with an empty feature set.
  --  

function Create_Disasm_CPU
     (Triple         : String;
      CPU            : String;
      Dis_Info       : System.Address;
      Tag_Type       : int;
      Get_Op_Info    : LLVM.Disassembler_Types.Op_Info_Callback_T;
      Symbol_Look_Up : LLVM.Disassembler_Types.Symbol_Lookup_Callback_T)
      return LLVM.Disassembler_Types.Disasm_Context_T;
   function Create_Disasm_CPU_C
     (Triple         : Interfaces.C.Strings.chars_ptr;
      CPU            : Interfaces.C.Strings.chars_ptr;
      Dis_Info       : System.Address;
      Tag_Type       : int;
      Get_Op_Info    : LLVM.Disassembler_Types.Op_Info_Callback_T;
      Symbol_Look_Up : LLVM.Disassembler_Types.Symbol_Lookup_Callback_T)
      return LLVM.Disassembler_Types.Disasm_Context_T;
   pragma Import (C, Create_Disasm_CPU_C, "LLVMCreateDisasmCPU");

  --*
  -- * Create a disassembler for the TripleName, a specific CPU and specific feature
  -- * string.  Symbolic disassembly is supported by passing a block of information
  -- * in the DisInfo parameter and specifying the TagType and callback functions as
  -- * described above.  These can all be passed * as NULL.  If successful, this
  -- * returns a disassembler context.  If not, it returns NULL.
  --  

function Create_Disasm_CPU_Features
     (Triple         : String;
      CPU            : String;
      Features       : String;
      Dis_Info       : System.Address;
      Tag_Type       : int;
      Get_Op_Info    : LLVM.Disassembler_Types.Op_Info_Callback_T;
      Symbol_Look_Up : LLVM.Disassembler_Types.Symbol_Lookup_Callback_T)
      return LLVM.Disassembler_Types.Disasm_Context_T;
   function Create_Disasm_CPU_Features_C
     (Triple         : Interfaces.C.Strings.chars_ptr;
      CPU            : Interfaces.C.Strings.chars_ptr;
      Features       : Interfaces.C.Strings.chars_ptr;
      Dis_Info       : System.Address;
      Tag_Type       : int;
      Get_Op_Info    : LLVM.Disassembler_Types.Op_Info_Callback_T;
      Symbol_Look_Up : LLVM.Disassembler_Types.Symbol_Lookup_Callback_T)
      return LLVM.Disassembler_Types.Disasm_Context_T;
   pragma Import (C, Create_Disasm_CPU_Features_C, "LLVMCreateDisasmCPUFeatures");

  --*
  -- * Set the disassembler's options.  Returns 1 if it can set the Options and 0
  -- * otherwise.
  --  

   function Set_Disasm_Options (DC : LLVM.Disassembler_Types.Disasm_Context_T; Options : stdint_h.uint64_t) return int;  -- llvm-11.0.1.src/include/llvm-c/Disassembler.h:72
   pragma Import (C, Set_Disasm_Options, "LLVMSetDisasmOptions");

  -- The option to produce marked up assembly.  
  -- The option to print immediates as hex.  
  -- The option use the other assembler printer variant  
  -- The option to set comment on instructions  
  -- The option to print latency information alongside instructions  
  --*
  -- * Dispose of a disassembler context.
  --  

   procedure Disasm_Dispose (DC : LLVM.Disassembler_Types.Disasm_Context_T);  -- llvm-11.0.1.src/include/llvm-c/Disassembler.h:88
   pragma Import (C, Disasm_Dispose, "LLVMDisasmDispose");

  --*
  -- * Disassemble a single instruction using the disassembler context specified in
  -- * the parameter DC.  The bytes of the instruction are specified in the
  -- * parameter Bytes, and contains at least BytesSize number of bytes.  The
  -- * instruction is at the address specified by the PC parameter.  If a valid
  -- * instruction can be disassembled, its string is returned indirectly in
  -- * OutString whose size is specified in the parameter OutStringSize.  This
  -- * function returns the number of bytes in the instruction or zero if there was
  -- * no valid instruction.
  --  

function Disasm_Instruction
     (DC              : LLVM.Disassembler_Types.Disasm_Context_T;
      Bytes           : access stdint_h.uint8_t;
      Bytes_Size      : stdint_h.uint64_t;
      PC              : stdint_h.uint64_t;
      Out_String      : String;
      Out_String_Size : stddef_h.size_t)
      return stddef_h.size_t;
   function Disasm_Instruction_C
     (DC              : LLVM.Disassembler_Types.Disasm_Context_T;
      Bytes           : access stdint_h.uint8_t;
      Bytes_Size      : stdint_h.uint64_t;
      PC              : stdint_h.uint64_t;
      Out_String      : Interfaces.C.Strings.chars_ptr;
      Out_String_Size : stddef_h.size_t)
      return stddef_h.size_t;
   pragma Import (C, Disasm_Instruction_C, "LLVMDisasmInstruction");

  --*
  -- * @}
  --  

end LLVM.Disassembler;

