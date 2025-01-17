pragma Style_Checks (Off);

pragma Warnings (Off); with Interfaces.C; use Interfaces.C; pragma Warnings (On);
with System;
with LLVM.Target_Machine;
with LLVM.Types;
with Interfaces.C.Extensions;
with stddef_h;
with Interfaces.C.Strings;
with LLVM.Target;
with stdint_h;

package LLVM.Execution_Engine is

  --===-- llvm-c/ExecutionEngine.h - ExecutionEngine Lib C Iface --*- C++ -*-===*|*                                                                            *|
  --|
  --|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
  --|* Exceptions.                                                                *|
  --|* See https://llvm.org/LICENSE.txt for license information.                  *|
  --|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
  --|*                                                                            *|
  --|*===----------------------------------------------------------------------===*|
  --|*                                                                            *|
  --|* This header declares the C interface to libLLVMExecutionEngine.o, which    *|
  --|* implements various analyses of the LLVM IR.                                *|
  --|*                                                                            *|
  --|* Many exotic languages can interoperate with C code but have a harder time  *|
  --|* with C++ due to name mangling. So in addition to C, this interface enables *|
  --|* tools written in such languages.                                           *|
  --|*                                                                            *|
  --\*===----------------------------------------------------------------------=== 

  --*
  -- * @defgroup LLVMCExecutionEngine Execution Engine
  -- * @ingroup LLVMC
  -- *
  -- * @{
  --  

   procedure Link_In_MCJIT;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:36
   pragma Import (C, Link_In_MCJIT, "LLVMLinkInMCJIT");

   procedure Link_In_Interpreter;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:37
   pragma Import (C, Link_In_Interpreter, "LLVMLinkInInterpreter");

   --  skipped empty struct LLVMOpaqueGenericValue

   type Generic_Value_T is new System.Address;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:39

   --  skipped empty struct LLVMOpaqueExecutionEngine

   type Execution_Engine_T is new System.Address;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:40

   --  skipped empty struct LLVMOpaqueMCJITMemoryManager

   type MCJIT_Memory_Manager_T is new System.Address;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:41

   type MCJIT_Compiler_Options_T is record
      OptLevel : aliased unsigned;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:44
      CodeModel : aliased LLVM.Target_Machine.Code_Model_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:45
      NoFramePointerElim : aliased LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:46
      EnableFastISel : aliased LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:47
      MCJMM : MCJIT_Memory_Manager_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:48
   end record;
   pragma Convention (C_Pass_By_Copy, MCJIT_Compiler_Options_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:43

  --===-- Operations on generic values --------------------------------------=== 
function Create_Generic_Value_Of_Int
     (Ty        : LLVM.Types.Type_T;
      N         : Extensions.unsigned_long_long;
      Is_Signed : Boolean)
      return Generic_Value_T;
   function Create_Generic_Value_Of_Int_C
     (Ty        : LLVM.Types.Type_T;
      N         : Extensions.unsigned_long_long;
      Is_Signed : LLVM.Types.Bool_T)
      return Generic_Value_T;
   pragma Import (C, Create_Generic_Value_Of_Int_C, "LLVMCreateGenericValueOfInt");

   function Create_Generic_Value_Of_Pointer (P : System.Address) return Generic_Value_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:57
   pragma Import (C, Create_Generic_Value_Of_Pointer, "LLVMCreateGenericValueOfPointer");

   function Create_Generic_Value_Of_Float (Ty : LLVM.Types.Type_T; N : double) return Generic_Value_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:59
   pragma Import (C, Create_Generic_Value_Of_Float, "LLVMCreateGenericValueOfFloat");

   function Generic_Value_Int_Width (Gen_Val_Ref : Generic_Value_T) return unsigned;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:61
   pragma Import (C, Generic_Value_Int_Width, "LLVMGenericValueIntWidth");

   function Generic_Value_To_Int
     (Gen_Val   : Generic_Value_T;
      Is_Signed : Boolean)
      return Extensions.unsigned_long_long;
   function Generic_Value_To_Int_C
     (Gen_Val   : Generic_Value_T;
      Is_Signed : LLVM.Types.Bool_T)
      return Extensions.unsigned_long_long;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:63
   pragma Import (C, Generic_Value_To_Int_C, "LLVMGenericValueToInt");

   function Generic_Value_To_Pointer (Gen_Val : Generic_Value_T) return System.Address;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:66
   pragma Import (C, Generic_Value_To_Pointer, "LLVMGenericValueToPointer");

   function Generic_Value_To_Float (Ty_Ref : LLVM.Types.Type_T; Gen_Val : Generic_Value_T) return double;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:68
   pragma Import (C, Generic_Value_To_Float, "LLVMGenericValueToFloat");

   procedure Dispose_Generic_Value (Gen_Val : Generic_Value_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:70
   pragma Import (C, Dispose_Generic_Value, "LLVMDisposeGenericValue");

  --===-- Operations on execution engines -----------------------------------=== 
function Create_Execution_Engine_For_Module
     (Out_EE    : System.Address;
      M         : LLVM.Types.Module_T;
      Out_Error : System.Address)
      return Boolean;
   function Create_Execution_Engine_For_Module_C
     (Out_EE    : System.Address;
      M         : LLVM.Types.Module_T;
      Out_Error : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Create_Execution_Engine_For_Module_C, "LLVMCreateExecutionEngineForModule");

function Create_Interpreter_For_Module
     (Out_Interp : System.Address;
      M          : LLVM.Types.Module_T;
      Out_Error  : System.Address)
      return Boolean;
   function Create_Interpreter_For_Module_C
     (Out_Interp : System.Address;
      M          : LLVM.Types.Module_T;
      Out_Error  : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Create_Interpreter_For_Module_C, "LLVMCreateInterpreterForModule");

function Create_JIT_Compiler_For_Module
     (Out_JIT   : System.Address;
      M         : LLVM.Types.Module_T;
      Opt_Level : unsigned;
      Out_Error : System.Address)
      return Boolean;
   function Create_JIT_Compiler_For_Module_C
     (Out_JIT   : System.Address;
      M         : LLVM.Types.Module_T;
      Opt_Level : unsigned;
      Out_Error : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Create_JIT_Compiler_For_Module_C, "LLVMCreateJITCompilerForModule");

   procedure Initialize_MCJIT_Compiler_Options (Options : access MCJIT_Compiler_Options_T; Size_Of_Options : stddef_h.size_t);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:87
   pragma Import (C, Initialize_MCJIT_Compiler_Options, "LLVMInitializeMCJITCompilerOptions");

  --*
  -- * Create an MCJIT execution engine for a module, with the given options. It is
  -- * the responsibility of the caller to ensure that all fields in Options up to
  -- * the given SizeOfOptions are initialized. It is correct to pass a smaller
  -- * value of SizeOfOptions that omits some fields. The canonical way of using
  -- * this is:
  -- *
  -- * LLVMMCJITCompilerOptions options;
  -- * LLVMInitializeMCJITCompilerOptions(&options, sizeof(options));
  -- * ... fill in those options you care about
  -- * LLVMCreateMCJITCompilerForModule(&jit, mod, &options, sizeof(options),
  -- *                                  &error);
  -- *
  -- * Note that this is also correct, though possibly suboptimal:
  -- *
  -- * LLVMCreateMCJITCompilerForModule(&jit, mod, 0, 0, &error);
  --  

function Create_MCJIT_Compiler_For_Module
     (Out_JIT         : System.Address;
      M               : LLVM.Types.Module_T;
      Options         : access MCJIT_Compiler_Options_T;
      Size_Of_Options : stddef_h.size_t;
      Out_Error       : System.Address)
      return Boolean;
   function Create_MCJIT_Compiler_For_Module_C
     (Out_JIT         : System.Address;
      M               : LLVM.Types.Module_T;
      Options         : access MCJIT_Compiler_Options_T;
      Size_Of_Options : stddef_h.size_t;
      Out_Error       : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Create_MCJIT_Compiler_For_Module_C, "LLVMCreateMCJITCompilerForModule");

   procedure Dispose_Execution_Engine (EE : Execution_Engine_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:112
   pragma Import (C, Dispose_Execution_Engine, "LLVMDisposeExecutionEngine");

   procedure Run_Static_Constructors (EE : Execution_Engine_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:114
   pragma Import (C, Run_Static_Constructors, "LLVMRunStaticConstructors");

   procedure Run_Static_Destructors (EE : Execution_Engine_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:116
   pragma Import (C, Run_Static_Destructors, "LLVMRunStaticDestructors");

   function Run_Function_As_Main
     (EE : Execution_Engine_T;
      F : LLVM.Types.Value_T;
      Arg_C : unsigned;
      Arg_V : System.Address;
      Env_P : System.Address) return int;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:118
   pragma Import (C, Run_Function_As_Main, "LLVMRunFunctionAsMain");

   function Run_Function
     (EE : Execution_Engine_T;
      F : LLVM.Types.Value_T;
      Num_Args : unsigned;
      Args : System.Address) return Generic_Value_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:122
   pragma Import (C, Run_Function, "LLVMRunFunction");

   procedure Free_Machine_Code_For_Function (EE : Execution_Engine_T; F : LLVM.Types.Value_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:126
   pragma Import (C, Free_Machine_Code_For_Function, "LLVMFreeMachineCodeForFunction");

   procedure Add_Module (EE : Execution_Engine_T; M : LLVM.Types.Module_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:128
   pragma Import (C, Add_Module, "LLVMAddModule");

function Remove_Module
     (EE        : Execution_Engine_T;
      M         : LLVM.Types.Module_T;
      Out_Mod   : System.Address;
      Out_Error : System.Address)
      return Boolean;
   function Remove_Module_C
     (EE        : Execution_Engine_T;
      M         : LLVM.Types.Module_T;
      Out_Mod   : System.Address;
      Out_Error : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Remove_Module_C, "LLVMRemoveModule");

function Find_Function
     (EE     : Execution_Engine_T;
      Name   : String;
      Out_Fn : System.Address)
      return Boolean;
   function Find_Function_C
     (EE     : Execution_Engine_T;
      Name   : Interfaces.C.Strings.chars_ptr;
      Out_Fn : System.Address)
      return LLVM.Types.Bool_T;
   pragma Import (C, Find_Function_C, "LLVMFindFunction");

   function Recompile_And_Relink_Function (EE : Execution_Engine_T; Fn : LLVM.Types.Value_T) return System.Address;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:136
   pragma Import (C, Recompile_And_Relink_Function, "LLVMRecompileAndRelinkFunction");

   function Get_Execution_Engine_Target_Data (EE : Execution_Engine_T) return LLVM.Target.Target_Data_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:139
   pragma Import (C, Get_Execution_Engine_Target_Data, "LLVMGetExecutionEngineTargetData");

   function Get_Execution_Engine_Target_Machine (EE : Execution_Engine_T) return LLVM.Target_Machine.Target_Machine_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:141
   pragma Import (C, Get_Execution_Engine_Target_Machine, "LLVMGetExecutionEngineTargetMachine");

   procedure Add_Global_Mapping
     (EE : Execution_Engine_T;
      Global : LLVM.Types.Value_T;
      Addr : System.Address);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:143
   pragma Import (C, Add_Global_Mapping, "LLVMAddGlobalMapping");

   function Get_Pointer_To_Global (EE : Execution_Engine_T; Global : LLVM.Types.Value_T) return System.Address;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:146
   pragma Import (C, Get_Pointer_To_Global, "LLVMGetPointerToGlobal");

   function Get_Global_Value_Address
     (EE   : Execution_Engine_T;
      Name : String)
      return stdint_h.uint64_t;
   function Get_Global_Value_Address_C
     (EE   : Execution_Engine_T;
      Name : Interfaces.C.Strings.chars_ptr)
      return stdint_h.uint64_t;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:148
   pragma Import (C, Get_Global_Value_Address_C, "LLVMGetGlobalValueAddress");

   function Get_Function_Address
     (EE   : Execution_Engine_T;
      Name : String)
      return stdint_h.uint64_t;
   function Get_Function_Address_C
     (EE   : Execution_Engine_T;
      Name : Interfaces.C.Strings.chars_ptr)
      return stdint_h.uint64_t;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:150
   pragma Import (C, Get_Function_Address_C, "LLVMGetFunctionAddress");

  --/ Returns true on error, false on success. If true is returned then the error
  --/ message is copied to OutStr and cleared in the ExecutionEngine instance.
   function Execution_Engine_Get_Err_Msg
     (EE        : Execution_Engine_T;
      Out_Error : System.Address)
      return Boolean;
   function Execution_Engine_Get_Err_Msg_C
     (EE        : Execution_Engine_T;
      Out_Error : System.Address)
      return LLVM.Types.Bool_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:154
   pragma Import (C, Execution_Engine_Get_Err_Msg_C, "LLVMExecutionEngineGetErrMsg");

  --===-- Operations on memory managers -------------------------------------=== 
   type Memory_Manager_Allocate_Code_Section_Callback_T is access function 
        (arg1 : System.Address;
         arg2 : stdint_h.uintptr_t;
         arg3 : unsigned;
         arg4 : unsigned;
         arg5 : Interfaces.C.Strings.chars_ptr) return access stdint_h.uint8_t;
   pragma Convention (C, Memory_Manager_Allocate_Code_Section_Callback_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:159

   type Memory_Manager_Allocate_Data_Section_Callback_T is access function 
        (arg1 : System.Address;
         arg2 : stdint_h.uintptr_t;
         arg3 : unsigned;
         arg4 : unsigned;
         arg5 : Interfaces.C.Strings.chars_ptr;
         arg6 : LLVM.Types.Bool_T) return access stdint_h.uint8_t;
   pragma Convention (C, Memory_Manager_Allocate_Data_Section_Callback_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:162

   type Memory_Manager_Finalize_Memory_Callback_T is access function  (arg1 : System.Address; arg2 : System.Address) return LLVM.Types.Bool_T;
   pragma Convention (C, Memory_Manager_Finalize_Memory_Callback_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:165

   type Memory_Manager_Destroy_Callback_T is access procedure  (arg1 : System.Address);
   pragma Convention (C, Memory_Manager_Destroy_Callback_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:167

  --*
  -- * Create a simple custom MCJIT memory manager. This memory manager can
  -- * intercept allocations in a module-oblivious way. This will return NULL
  -- * if any of the passed functions are NULL.
  -- *
  -- * @param Opaque An opaque client object to pass back to the callbacks.
  -- * @param AllocateCodeSection Allocate a block of memory for executable code.
  -- * @param AllocateDataSection Allocate a block of memory for data.
  -- * @param FinalizeMemory Set page permissions and flush cache. Return 0 on
  -- *   success, 1 on error.
  --  

   function Create_Simple_MCJIT_Memory_Manager
     (Opaque : System.Address;
      Allocate_Code_Section : Memory_Manager_Allocate_Code_Section_Callback_T;
      Allocate_Data_Section : Memory_Manager_Allocate_Data_Section_Callback_T;
      Finalize_Memory : Memory_Manager_Finalize_Memory_Callback_T;
      Destroy : Memory_Manager_Destroy_Callback_T) return MCJIT_Memory_Manager_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:180
   pragma Import (C, Create_Simple_MCJIT_Memory_Manager, "LLVMCreateSimpleMCJITMemoryManager");

   procedure Dispose_MCJIT_Memory_Manager (MM : MCJIT_Memory_Manager_T);  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:187
   pragma Import (C, Dispose_MCJIT_Memory_Manager, "LLVMDisposeMCJITMemoryManager");

  --===-- JIT Event Listener functions -------------------------------------=== 
   function Create_GDB_Registration_Listener return LLVM.Types.JIT_Event_Listener_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:191
   pragma Import (C, Create_GDB_Registration_Listener, "LLVMCreateGDBRegistrationListener");

   function Create_Intel_JIT_Event_Listener return LLVM.Types.JIT_Event_Listener_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:192
   pragma Import (C, Create_Intel_JIT_Event_Listener, "LLVMCreateIntelJITEventListener");

   function Create_O_Profile_JIT_Event_Listener return LLVM.Types.JIT_Event_Listener_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:193
   pragma Import (C, Create_O_Profile_JIT_Event_Listener, "LLVMCreateOProfileJITEventListener");

   function Create_Perf_JIT_Event_Listener return LLVM.Types.JIT_Event_Listener_T;  -- llvm-11.0.1.src/include/llvm-c/ExecutionEngine.h:194
   pragma Import (C, Create_Perf_JIT_Event_Listener, "LLVMCreatePerfJITEventListener");

  --*
  -- * @}
  --  

end LLVM.Execution_Engine;

