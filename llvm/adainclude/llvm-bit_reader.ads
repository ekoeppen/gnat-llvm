pragma Style_Checks (Off);

pragma Warnings (Off); with Interfaces.C; use Interfaces.C; pragma Warnings (On);
with LLVM.Types;
with System;

package LLVM.Bit_Reader is

  --===-- llvm-c/BitReader.h - BitReader Library C Interface ------*- C++ -*-===*|*                                                                            *|
  --|
  --|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
  --|* Exceptions.                                                                *|
  --|* See https://llvm.org/LICENSE.txt for license information.                  *|
  --|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
  --|*                                                                            *|
  --|*===----------------------------------------------------------------------===*|
  --|*                                                                            *|
  --|* This header declares the C interface to libLLVMBitReader.a, which          *|
  --|* implements input of the LLVM bitcode format.                               *|
  --|*                                                                            *|
  --|* Many exotic languages can interoperate with C code but have a harder time  *|
  --|* with C++ due to name mangling. So in addition to C, this interface enables *|
  --|* tools written in such languages.                                           *|
  --|*                                                                            *|
  --\*===----------------------------------------------------------------------=== 

  --*
  -- * @defgroup LLVMCBitReader Bit Reader
  -- * @ingroup LLVMC
  -- *
  -- * @{
  --  

  -- Builds a module from the bitcode in the specified memory buffer, returning a
  --   reference to the module via the OutModule parameter. Returns 0 on success.
  --   Optionally returns a human-readable error message via OutMessage.
  --   This is deprecated. Use LLVMParseBitcode2.  

function Parse_Bitcode
     (Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_Module  : System.Address;
      Out_Message : System.Address)
      return Boolean;
   function Parse_Bitcode_C
     (Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_Module  : System.Address;
      Out_Message : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Parse_Bitcode_C, "LLVMParseBitcode");

  -- Builds a module from the bitcode in the specified memory buffer, returning a
  --   reference to the module via the OutModule parameter. Returns 0 on success.  

   function Parse_Bitcode2
     (Mem_Buf    : LLVM.Types.Memory_Buffer_T;
      Out_Module : System.Address)
      return Boolean;
   function Parse_Bitcode2_C
     (Mem_Buf    : LLVM.Types.Memory_Buffer_T;
      Out_Module : System.Address)
      return LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/BitReader.h:44
   pragma Import (C, Parse_Bitcode2_C, "LLVMParseBitcode2");

  -- This is deprecated. Use LLVMParseBitcodeInContext2.  
function Parse_Bitcode_In_Context
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_Module  : System.Address;
      Out_Message : System.Address)
      return Boolean;
   function Parse_Bitcode_In_Context_C
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_Module  : System.Address;
      Out_Message : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Parse_Bitcode_In_Context_C, "LLVMParseBitcodeInContext");

function Parse_Bitcode_In_Context2
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_Module  : System.Address)
      return Boolean;
   function Parse_Bitcode_In_Context2_C
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_Module  : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Parse_Bitcode_In_Context2_C, "LLVMParseBitcodeInContext2");

  --* Reads a module from the specified path, returning via the OutMP parameter
  --    a module provider which performs lazy deserialization. Returns 0 on success.
  --    Optionally returns a human-readable error message via OutMessage.
  --    This is deprecated. Use LLVMGetBitcodeModuleInContext2.  

function Get_Bitcode_Module_In_Context
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_M       : System.Address;
      Out_Message : System.Address)
      return Boolean;
   function Get_Bitcode_Module_In_Context_C
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_M       : System.Address;
      Out_Message : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Get_Bitcode_Module_In_Context_C, "LLVMGetBitcodeModuleInContext");

  --* Reads a module from the specified path, returning via the OutMP parameter a
  -- * module provider which performs lazy deserialization. Returns 0 on success.  

function Get_Bitcode_Module_In_Context2
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_M       : System.Address)
      return Boolean;
   function Get_Bitcode_Module_In_Context2_C
     (Context_Ref : LLVM.Types.Context_T;
      Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_M       : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Get_Bitcode_Module_In_Context2_C, "LLVMGetBitcodeModuleInContext2");

  -- This is deprecated. Use LLVMGetBitcodeModule2.  
function Get_Bitcode_Module
     (Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_M       : System.Address;
      Out_Message : System.Address)
      return Boolean;
   function Get_Bitcode_Module_C
     (Mem_Buf     : LLVM.Types.Memory_Buffer_T;
      Out_M       : System.Address;
      Out_Message : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Get_Bitcode_Module_C, "LLVMGetBitcodeModule");

   function Get_Bitcode_Module2
     (Mem_Buf : LLVM.Types.Memory_Buffer_T;
      Out_M   : System.Address)
      return Boolean;
   function Get_Bitcode_Module2_C
     (Mem_Buf : LLVM.Types.Memory_Buffer_T;
      Out_M   : System.Address)
      return LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/BitReader.h:74
   pragma Import (C, Get_Bitcode_Module2_C, "LLVMGetBitcodeModule2");

  --*
  -- * @}
  --  

end LLVM.Bit_Reader;

