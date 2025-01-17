pragma Style_Checks (Off);

pragma Warnings (Off); with Interfaces.C; use Interfaces.C; pragma Warnings (On);
with LLVM.Types;

package LLVM.Transforms_Utils is

  --===-- Utils.h - Transformation Utils Library C Interface ------*- C++ -*-===*|*                                                                            *|
  --|
  --|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
  --|* Exceptions.                                                                *|
  --|* See https://llvm.org/LICENSE.txt for license information.                  *|
  --|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
  --|*                                                                            *|
  --|*===----------------------------------------------------------------------===*|
  --|*                                                                            *|
  --|* This header declares the C interface to libLLVMTransformUtils.a, which     *|
  --|* implements various transformation utilities of the LLVM IR.                *|
  --|*                                                                            *|
  --|* Many exotic languages can interoperate with C code but have a harder time  *|
  --|* with C++ due to name mangling. So in addition to C, this interface enables *|
  --|* tools written in such languages.                                           *|
  --|*                                                                            *|
  --\*===----------------------------------------------------------------------=== 

  --*
  -- * @defgroup LLVMCTransformsUtils Transformation Utilities
  -- * @ingroup LLVMCTransforms
  -- *
  -- * @{
  --  

  --* See llvm::createLowerSwitchPass function.  
   procedure Add_Lower_Switch_Pass (PM : LLVM.Types.Pass_Manager_T);  -- llvm-11.0.1.src/include/llvm-c/Transforms/Utils.h:35
   pragma Import (C, Add_Lower_Switch_Pass, "LLVMAddLowerSwitchPass");

  --* See llvm::createPromoteMemoryToRegisterPass function.  
   procedure Add_Promote_Memory_To_Register_Pass (PM : LLVM.Types.Pass_Manager_T);  -- llvm-11.0.1.src/include/llvm-c/Transforms/Utils.h:38
   pragma Import (C, Add_Promote_Memory_To_Register_Pass, "LLVMAddPromoteMemoryToRegisterPass");

  --* See llvm::createAddDiscriminatorsPass function.  
   procedure Add_Add_Discriminators_Pass (PM : LLVM.Types.Pass_Manager_T);  -- llvm-11.0.1.src/include/llvm-c/Transforms/Utils.h:41
   pragma Import (C, Add_Add_Discriminators_Pass, "LLVMAddAddDiscriminatorsPass");

  --*
  -- * @}
  --  

end LLVM.Transforms_Utils;

