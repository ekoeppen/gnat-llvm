pragma Style_Checks (Off);

pragma Warnings (Off); with Interfaces.C; use Interfaces.C; pragma Warnings (On);
with System;
with LLVM.Types;
with Interfaces.C.Strings;
with Interfaces.C.Extensions;

package LLVM.Target is

  --===-- llvm-c/Target.h - Target Lib C Iface --------------------*- C++ -*-=== 
  --                                                                             
  -- Part of the LLVM Project, under the Apache License v2.0 with LLVM           
  -- Exceptions.                                                                 
  -- See https://llvm.org/LICENSE.txt for license information.                   
  -- SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                     
  --                                                                             
  --===----------------------------------------------------------------------=== 
  --                                                                             
  -- This header declares the C interface to libLLVMTarget.a, which              
  -- implements target information.                                              
  --                                                                             
  -- Many exotic languages can interoperate with C code but have a harder time   
  -- with C++ due to name mangling. So in addition to C, this interface enables  
  -- tools written in such languages.                                            
  --                                                                             
  --===----------------------------------------------------------------------=== 
  --*
  -- * @defgroup LLVMCTarget Target information
  -- * @ingroup LLVMC
  -- *
  -- * @{
  --  

   type Byte_Ordering_T is 
     (Big_Endian,
      Little_Endian);
   pragma Convention (C, Byte_Ordering_T);  -- llvm-11.0.1.src/include/llvm-c/Target.h:35

   --  skipped empty struct LLVMOpaqueTargetData

   type Target_Data_T is new System.Address;  -- llvm-11.0.1.src/include/llvm-c/Target.h:37

   --  skipped empty struct LLVMOpaqueTargetLibraryInfotData

   type Target_Library_Info_T is new System.Address;  -- llvm-11.0.1.src/include/llvm-c/Target.h:38

  -- Declare all of the target-initialization functions that are available.  
  -- Declare all of the available assembly printer initialization functions.  
  -- Declare all of the available assembly parser initialization functions.  
  -- Declare all of the available disassembler initialization functions.  
  --* LLVMInitializeAllTargetInfos - The main program should call this function if
  --    it wants access to all available targets that LLVM is configured to
  --    support.  

   procedure Initialize_All_Target_Infos;  -- llvm-11.0.1.src/include/llvm-c/Target.h:76
   pragma Import (C, Initialize_All_Target_Infos, "LLVMInitializeAllTargetInfos");

  --* LLVMInitializeAllTargets - The main program should call this function if it
  --    wants to link in all available targets that LLVM is configured to
  --    support.  

   procedure Initialize_All_Targets;  -- llvm-11.0.1.src/include/llvm-c/Target.h:85
   pragma Import (C, Initialize_All_Targets, "LLVMInitializeAllTargets");

  --* LLVMInitializeAllTargetMCs - The main program should call this function if
  --    it wants access to all available target MC that LLVM is configured to
  --    support.  

   procedure Initialize_All_Target_M_Cs;  -- llvm-11.0.1.src/include/llvm-c/Target.h:94
   pragma Import (C, Initialize_All_Target_M_Cs, "LLVMInitializeAllTargetMCs");

  --* LLVMInitializeAllAsmPrinters - The main program should call this function if
  --    it wants all asm printers that LLVM is configured to support, to make them
  --    available via the TargetRegistry.  

   procedure Initialize_All_Asm_Printers;  -- llvm-11.0.1.src/include/llvm-c/Target.h:103
   pragma Import (C, Initialize_All_Asm_Printers, "LLVMInitializeAllAsmPrinters");

  --* LLVMInitializeAllAsmParsers - The main program should call this function if
  --    it wants all asm parsers that LLVM is configured to support, to make them
  --    available via the TargetRegistry.  

   procedure Initialize_All_Asm_Parsers;  -- llvm-11.0.1.src/include/llvm-c/Target.h:112
   pragma Import (C, Initialize_All_Asm_Parsers, "LLVMInitializeAllAsmParsers");

  --* LLVMInitializeAllDisassemblers - The main program should call this function
  --    if it wants all disassemblers that LLVM is configured to support, to make
  --    them available via the TargetRegistry.  

   procedure Initialize_All_Disassemblers;  -- llvm-11.0.1.src/include/llvm-c/Target.h:121
   pragma Import (C, Initialize_All_Disassemblers, "LLVMInitializeAllDisassemblers");

  --* LLVMInitializeNativeTarget - The main program should call this function to
  --    initialize the native target corresponding to the host.  This is useful
  --    for JIT applications to ensure that the target gets linked in correctly.  

   function Initialize_Native_Target return LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:131
   pragma Import (C, Initialize_Native_Target, "LLVMInitializeNativeTarget");

  -- If we have a native target, initialize it to ensure it is linked in.  
  --* LLVMInitializeNativeTargetAsmParser - The main program should call this
  --    function to initialize the parser for the native target corresponding to the
  --    host.  

   function Initialize_Native_Asm_Parser return LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:146
   pragma Import (C, Initialize_Native_Asm_Parser, "LLVMInitializeNativeAsmParser");

  --* LLVMInitializeNativeTargetAsmPrinter - The main program should call this
  --    function to initialize the printer for the native target corresponding to
  --    the host.  

   function Initialize_Native_Asm_Printer return LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:158
   pragma Import (C, Initialize_Native_Asm_Printer, "LLVMInitializeNativeAsmPrinter");

  --* LLVMInitializeNativeTargetDisassembler - The main program should call this
  --    function to initialize the disassembler for the native target corresponding
  --    to the host.  

   function Initialize_Native_Disassembler return LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:170
   pragma Import (C, Initialize_Native_Disassembler, "LLVMInitializeNativeDisassembler");

  --===-- Target Data -------------------------------------------------------=== 
  --*
  -- * Obtain the data layout for a module.
  -- *
  -- * @see Module::getDataLayout()
  --  

   function Get_Module_Data_Layout (M : LLVM.Types.Module_T) return Target_Data_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:186
   pragma Import (C, Get_Module_Data_Layout, "LLVMGetModuleDataLayout");

  --*
  -- * Set the data layout for a module.
  -- *
  -- * @see Module::setDataLayout()
  --  

   procedure Set_Module_Data_Layout (M : LLVM.Types.Module_T; DL : Target_Data_T);  -- llvm-11.0.1.src/include/llvm-c/Target.h:193
   pragma Import (C, Set_Module_Data_Layout, "LLVMSetModuleDataLayout");

  --* Creates target data from a target layout string.
  --    See the constructor llvm::DataLayout::DataLayout.  

   function Create_Target_Data
     (String_Rep : String)
      return Target_Data_T;
   function Create_Target_Data_C
     (String_Rep : Interfaces.C.Strings.chars_ptr)
      return Target_Data_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:197
   pragma Import (C, Create_Target_Data_C, "LLVMCreateTargetData");

  --* Deallocates a TargetData.
  --    See the destructor llvm::DataLayout::~DataLayout.  

   procedure Dispose_Target_Data (TD : Target_Data_T);  -- llvm-11.0.1.src/include/llvm-c/Target.h:201
   pragma Import (C, Dispose_Target_Data, "LLVMDisposeTargetData");

  --* Adds target library information to a pass manager. This does not take
  --    ownership of the target library info.
  --    See the method llvm::PassManagerBase::add.  

   procedure Add_Target_Library_Info (TLI : Target_Library_Info_T; PM : LLVM.Types.Pass_Manager_T);  -- llvm-11.0.1.src/include/llvm-c/Target.h:206
   pragma Import (C, Add_Target_Library_Info, "LLVMAddTargetLibraryInfo");

  --* Converts target data to a target layout string. The string must be disposed
  --    with LLVMDisposeMessage.
  --    See the constructor llvm::DataLayout::DataLayout.  

   function Copy_String_Rep_Of_Target_Data
     (TD : Target_Data_T)
      return String;
   function Copy_String_Rep_Of_Target_Data_C
     (TD : Target_Data_T)
      return Interfaces.C.Strings.chars_ptr;  -- llvm-11.0.1.src/include/llvm-c/Target.h:212
   pragma Import (C, Copy_String_Rep_Of_Target_Data_C, "LLVMCopyStringRepOfTargetData");

  --* Returns the byte order of a target, either LLVMBigEndian or
  --    LLVMLittleEndian.
  --    See the method llvm::DataLayout::isLittleEndian.  

   function Byte_Order (TD : Target_Data_T) return Byte_Ordering_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:217
   pragma Import (C, Byte_Order, "LLVMByteOrder");

  --* Returns the pointer size in bytes for a target.
  --    See the method llvm::DataLayout::getPointerSize.  

   function Pointer_Size (TD : Target_Data_T) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/Target.h:221
   pragma Import (C, Pointer_Size, "LLVMPointerSize");

  --* Returns the pointer size in bytes for a target for a specified
  --    address space.
  --    See the method llvm::DataLayout::getPointerSize.  

   function Pointer_Size_For_AS (TD : Target_Data_T; AS : unsigned) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/Target.h:226
   pragma Import (C, Pointer_Size_For_AS, "LLVMPointerSizeForAS");

  --* Returns the integer type that is the same size as a pointer on a target.
  --    See the method llvm::DataLayout::getIntPtrType.  

   function Int_Ptr_Type (TD : Target_Data_T) return LLVM.Types.Type_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:230
   pragma Import (C, Int_Ptr_Type, "LLVMIntPtrType");

  --* Returns the integer type that is the same size as a pointer on a target.
  --    This version allows the address space to be specified.
  --    See the method llvm::DataLayout::getIntPtrType.  

   function Int_Ptr_Type_For_AS (TD : Target_Data_T; AS : unsigned) return LLVM.Types.Type_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:235
   pragma Import (C, Int_Ptr_Type_For_AS, "LLVMIntPtrTypeForAS");

  --* Returns the integer type that is the same size as a pointer on a target.
  --    See the method llvm::DataLayout::getIntPtrType.  

   function Int_Ptr_Type_In_Context (C : LLVM.Types.Context_T; TD : Target_Data_T) return LLVM.Types.Type_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:239
   pragma Import (C, Int_Ptr_Type_In_Context, "LLVMIntPtrTypeInContext");

  --* Returns the integer type that is the same size as a pointer on a target.
  --    This version allows the address space to be specified.
  --    See the method llvm::DataLayout::getIntPtrType.  

   function Int_Ptr_Type_For_AS_In_Context
     (C : LLVM.Types.Context_T;
      TD : Target_Data_T;
      AS : unsigned) return LLVM.Types.Type_T;  -- llvm-11.0.1.src/include/llvm-c/Target.h:244
   pragma Import (C, Int_Ptr_Type_For_AS_In_Context, "LLVMIntPtrTypeForASInContext");

  --* Computes the size of a type in bytes for a target.
  --    See the method llvm::DataLayout::getTypeSizeInBits.  

   function Size_Of_Type_In_Bits (TD : Target_Data_T; Ty : LLVM.Types.Type_T) return Extensions.unsigned_long_long;  -- llvm-11.0.1.src/include/llvm-c/Target.h:249
   pragma Import (C, Size_Of_Type_In_Bits, "LLVMSizeOfTypeInBits");

  --* Computes the storage size of a type in bytes for a target.
  --    See the method llvm::DataLayout::getTypeStoreSize.  

   function Store_Size_Of_Type (TD : Target_Data_T; Ty : LLVM.Types.Type_T) return Extensions.unsigned_long_long;  -- llvm-11.0.1.src/include/llvm-c/Target.h:253
   pragma Import (C, Store_Size_Of_Type, "LLVMStoreSizeOfType");

  --* Computes the ABI size of a type in bytes for a target.
  --    See the method llvm::DataLayout::getTypeAllocSize.  

   function ABI_Size_Of_Type (TD : Target_Data_T; Ty : LLVM.Types.Type_T) return Extensions.unsigned_long_long;  -- llvm-11.0.1.src/include/llvm-c/Target.h:257
   pragma Import (C, ABI_Size_Of_Type, "LLVMABISizeOfType");

  --* Computes the ABI alignment of a type in bytes for a target.
  --    See the method llvm::DataLayout::getTypeABISize.  

   function ABI_Alignment_Of_Type (TD : Target_Data_T; Ty : LLVM.Types.Type_T) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/Target.h:261
   pragma Import (C, ABI_Alignment_Of_Type, "LLVMABIAlignmentOfType");

  --* Computes the call frame alignment of a type in bytes for a target.
  --    See the method llvm::DataLayout::getTypeABISize.  

   function Call_Frame_Alignment_Of_Type (TD : Target_Data_T; Ty : LLVM.Types.Type_T) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/Target.h:265
   pragma Import (C, Call_Frame_Alignment_Of_Type, "LLVMCallFrameAlignmentOfType");

  --* Computes the preferred alignment of a type in bytes for a target.
  --    See the method llvm::DataLayout::getTypeABISize.  

   function Preferred_Alignment_Of_Type (TD : Target_Data_T; Ty : LLVM.Types.Type_T) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/Target.h:269
   pragma Import (C, Preferred_Alignment_Of_Type, "LLVMPreferredAlignmentOfType");

  --* Computes the preferred alignment of a global variable in bytes for a target.
  --    See the method llvm::DataLayout::getPreferredAlignment.  

   function Preferred_Alignment_Of_Global (TD : Target_Data_T; Global_Var : LLVM.Types.Value_T) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/Target.h:273
   pragma Import (C, Preferred_Alignment_Of_Global, "LLVMPreferredAlignmentOfGlobal");

  --* Computes the structure element that contains the byte offset for a target.
  --    See the method llvm::StructLayout::getElementContainingOffset.  

   function Element_At_Offset
     (TD : Target_Data_T;
      Struct_Ty : LLVM.Types.Type_T;
      Offset : Extensions.unsigned_long_long) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/Target.h:278
   pragma Import (C, Element_At_Offset, "LLVMElementAtOffset");

  --* Computes the byte offset of the indexed struct element for a target.
  --    See the method llvm::StructLayout::getElementContainingOffset.  

   function Offset_Of_Element
     (TD : Target_Data_T;
      Struct_Ty : LLVM.Types.Type_T;
      Element : unsigned) return Extensions.unsigned_long_long;  -- llvm-11.0.1.src/include/llvm-c/Target.h:283
   pragma Import (C, Offset_Of_Element, "LLVMOffsetOfElement");

  --*
  -- * @}
  --  

end LLVM.Target;

