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

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings; use Interfaces.C.Strings;

with stddef_h; use stddef_h;

package body CCG.Helper is

   ---------------------------
   -- Const_Real_Get_Double --
   ---------------------------

   function Const_Real_Get_Double
     (V : Value_T; Loses_Info : out Boolean) return Double
   is
      C_Loses_Info : aliased Bool_T;
      Result       : constant Double :=
        Const_Real_Get_Double (V, C_Loses_Info'Access);

   begin
      Loses_Info := C_Loses_Info /= 0;
      return Result;
   end Const_Real_Get_Double;

   ---------------------
   -- Struct_Has_Name --
   ---------------------

   function Struct_Has_Name (T : Type_T) return Boolean is
      function Struct_Has_Name (T : Type_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Struct_Has_Name";
   begin
      return (if Struct_Has_Name (T) /= 0 then True else False);
   end Struct_Has_Name;

   --------------------
   -- Value_Has_Name --
   --------------------

   function Value_Has_Name (V : Value_T) return Boolean is
      function Value_Has_Name (V : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Value_Has_Name";
   begin
      return (if Value_Has_Name (V) /= 0 then True else False);
   end Value_Has_Name;

   ---------------------
   -- Get_Opcode_Name --
   ---------------------

   function Get_Opcode_Name (Opc : Opcode_T) return String is
      function Get_Opcode_Name_C (Opc : Opcode_T) return chars_ptr
        with Import, Convention => C, External_Name => "Get_Opcode_Name";
   begin
      return Value (Get_Opcode_Name_C (Opc));
   end Get_Opcode_Name;

   -------------------
   -- Get_As_String --
   -------------------

   function Get_As_String (V : Value_T) return String is
      Length : aliased stddef_h.size_t;
      S      : constant String := Get_As_String (V, Length'Access);
   begin
      return S;
   end Get_As_String;

end CCG.Helper;
