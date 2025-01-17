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

with Ada.Unchecked_Conversion;
with Ada.Containers; use Ada.Containers;
with Ada.Containers.Hashed_Maps;

with Table; use Table;

with CCG.Output; use CCG.Output;
with CCG.Utils;  use CCG.Utils;

package body CCG.Tables is

   type Value_Data is record
      C_Value             : Str;
      --  If Present, a string that represents the value of the Value_T

      Is_Variable         : Boolean;
      --  True if a variable declared at source level

      Is_Decl_Output      : Boolean;
      --  True if we wrote any needed decl for this value

      Is_Temp_Decl_Output : Boolean;
      --  Likewise, but applies to the temporary needed for a PHI instruction

      Is_LHS              : Boolean;
      --  True if this value represents an LHS. This is usually either a
      --  global variable or an alloca in the entry block. In that case,
      --  from a C perspective, a use of a value in LLVM IR represents the
      --  address of the value; only "load" or "store" instruction actually
      --  accesses the value. It can also be the result of a GEP
      --  instruction.

      Is_Constant         : Boolean;
      --  True if this value is a constant and was declared that way
      --  in C. We use this to indicate that we have to cast the type
      --  to the non-constant pointer to take the address of the value.

      Is_Unsigned         : Boolean;
      --  True if this value was marked as unsigned and will be declared
      --  that way.

      Is_Used             : Boolean;
      --  True if this value represents a variable that has been used in an
      --  expression.

      Output_Idx          : Nat;
      --  A positive number if we've assigned an ordinal to use as
      --  part of the name for this anonymous value.

   end record;

   type Type_Data is record
      Is_Typedef_Output        : Boolean;
      --  True if this is a type either for which we don't write a typedef
      --  or if it is and we've written that typedef previously.

      Is_Return_Typedef_Output : Boolean;
      --  True if this is an array type and we've written the struct type
      --  that we use for the return type of a function returning this type.

      Is_Incomplete_Output     : Boolean;
      --  True if this is a struct type and we've just written the struct
      --  definition without fields (an incomplete type).

      Are_Writing_Typedef      : Boolean;
      --  True if we're in the process of writing a typedef

      Output_Idx               : Nat;
      --  A positive number if we've assigned an ordinal to use as
      --  part of the name for this anonymous type.

   end record;

   type BB_Data is record
      Was_Output : Boolean;
      --  True if this basic block has already been output

      Output_Idx : Nat;
      --  A positive number if we've assigned an ordinal to use as
      --  part of the name for this block.

   end record;

   type Value_Idx is new Nat;
   type Type_Idx  is new Nat;
   type BB_Idx    is new Nat;

   No_Value_Idx : constant Value_Idx := 0;
   No_Type_Idx  : constant Type_Idx  := 0;
   No_BB_Idx    : constant BB_Idx    := 0;

   function Present (X : Value_Idx) return Boolean is (X /= No_Value_Idx);
   function Present (X : Type_Idx)  return Boolean is (X /= No_Type_Idx);
   function Present (X : BB_Idx)    return Boolean is (X /= No_BB_Idx);

   package Value_Data_Table is new Table.Table
     (Table_Component_Type => Value_Data,
      Table_Index_Type     => Value_Idx,
      Table_Low_Bound      => 1,
      Table_Initial        => 500,
      Table_Increment      => 100,
      Table_Name           => "Value_Data_Table");

   package Type_Data_Table is new Table.Table
     (Table_Component_Type => Type_Data,
      Table_Index_Type     => Type_Idx,
      Table_Low_Bound      => 1,
      Table_Initial        => 200,
      Table_Increment      => 50,
      Table_Name           => "Type_Data_Table");

   package BB_Data_Table is new Table.Table
     (Table_Component_Type => BB_Data,
      Table_Index_Type     => BB_Idx,
      Table_Low_Bound      => 1,
      Table_Initial        => 200,
      Table_Increment      => 50,
      Table_Name           => "BB_Data_Table");

   package Value_Data_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Value_T,
      Element_Type    => Value_Idx,
      Hash            => Hash,
      Equivalent_Keys => "=");
   Value_Data_Map : Value_Data_Maps.Map;

   package Type_Data_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Type_T,
      Element_Type    => Type_Idx,
      Hash            => Hash,
      Equivalent_Keys => "=");
   Type_Data_Map : Type_Data_Maps.Map;

   package BB_Data_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Basic_Block_T,
      Element_Type    => BB_Idx,
      Hash            => Hash,
      Equivalent_Keys => "=");
   BB_Data_Map : BB_Data_Maps.Map;

   Output_Idx : Nat := 1;
   --  The next output index to use for values, types, and basic blocks

   --  Functions to return the corresponding index for a value, type, or
   --  basic block and whether to create one if one isn't present.

   function Value_Data_Idx (V : Value_T; Create : Boolean) return Value_Idx
     with Pre => Present (V), Pure_Function;
   function Type_Data_Idx  (T : Type_T; Create : Boolean) return Type_Idx
     with Pre => Present (T), Pure_Function;
   function BB_Data_Idx    (B : Basic_Block_T; Create : Boolean) return BB_Idx
     with Pre => Present (B), Pure_Function;

   --------------------
   -- Value_Data_Idx --
   --------------------

   function Value_Data_Idx (V : Value_T; Create : Boolean) return Value_Idx
   is
      use Value_Data_Maps;
      Position : constant Cursor := Find (Value_Data_Map, V);

   begin
      if Has_Element (Position) then
         return Element (Position);
      elsif not Create then
         return No_Value_Idx;
      else
         Value_Data_Table.Append ((C_Value             => No_Str,
                                   Is_Variable         => False,
                                   Is_Decl_Output      => False,
                                   Is_Temp_Decl_Output => False,
                                   Is_LHS              => False,
                                   Is_Constant         => False,
                                   Is_Unsigned         => False,
                                   Is_Used             => False,
                                   Output_Idx          => 0));
         Insert (Value_Data_Map, V, Value_Data_Table.Last);
         return Value_Data_Table.Last;
      end if;
   end Value_Data_Idx;

   -----------------------
   -- Delete_Value_Info --
   -----------------------

   procedure Delete_Value_Info (V : Value_T) is
      use Value_Data_Maps;
   begin
      Exclude (Value_Data_Map, V);
   end Delete_Value_Info;

   -------------------
   -- Type_Data_Idx --
   -------------------

   function Type_Data_Idx (T : Type_T; Create : Boolean) return Type_Idx
   is
      use Type_Data_Maps;
      Position : constant Cursor := Find (Type_Data_Map, T);

   begin
      if Has_Element (Position) then
         return Element (Position);
      elsif not Create then
         return No_Type_Idx;
      else
         Type_Data_Table.Append ((Is_Typedef_Output        => False,
                                  Is_Return_Typedef_Output => False,
                                  Is_Incomplete_Output     => False,
                                  Are_Writing_Typedef      => False,
                                  Output_Idx               => 0));
         Insert (Type_Data_Map, T, Type_Data_Table.Last);
         return Type_Data_Table.Last;
      end if;
   end Type_Data_Idx;

   -----------------
   -- BB_Data_Idx --
   -----------------

   function BB_Data_Idx (B : Basic_Block_T; Create : Boolean) return BB_Idx
   is
      use BB_Data_Maps;
      Position : constant Cursor := Find (BB_Data_Map, B);

   begin
      if Has_Element (Position) then
         return Element (Position);
      elsif not Create then
         return No_BB_Idx;
      else
         BB_Data_Table.Append ((Was_Output => False,
                                Output_Idx => 0));
         Insert (BB_Data_Map, B, BB_Data_Table.Last);
         return BB_Data_Table.Last;
      end if;
   end BB_Data_Idx;

   -----------------
   -- Get_C_Value --
   -----------------

   function Get_C_Value (V : Value_T) return Str is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return (if   Present (Idx) then Value_Data_Table.Table (Idx).C_Value
              else No_Str);
   end Get_C_Value;

   ---------------------
   -- Get_Is_Variable --
   ---------------------

   function Get_Is_Variable (V : Value_T) return Boolean is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return Present (Idx) and then Value_Data_Table.Table (Idx).Is_Variable;
   end Get_Is_Variable;

   ------------------------
   -- Get_Is_Decl_Output --
   ------------------------

   function Get_Is_Decl_Output (V : Value_T) return Boolean is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return Present (Idx)
        and then Value_Data_Table.Table (Idx).Is_Decl_Output;

   end Get_Is_Decl_Output;

   -----------------------------
   -- Get_Is_Temp_Decl_Output --
   -----------------------------

   function Get_Is_Temp_Decl_Output (V : Value_T) return Boolean is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return Present (Idx)
        and then Value_Data_Table.Table (Idx).Is_Temp_Decl_Output;

   end Get_Is_Temp_Decl_Output;

   ----------------
   -- Get_Is_LHS --
   ----------------

   function Get_Is_LHS (V : Value_T) return Boolean is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return Present (Idx)
        and then Value_Data_Table.Table (Idx).Is_LHS;

   end Get_Is_LHS;

   ---------------------
   -- Get_Is_Constant --
   ---------------------

   function Get_Is_Constant (V : Value_T) return Boolean is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return Present (Idx)
        and then Value_Data_Table.Table (Idx).Is_Constant;

   end Get_Is_Constant;

   ---------------------
   -- Get_Is_Unsigned --
   ---------------------

   function Get_Is_Unsigned (V : Value_T) return Boolean is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return Present (Idx)
        and then Value_Data_Table.Table (Idx).Is_Unsigned;

   end Get_Is_Unsigned;

   ------------------
   -- Get_Is_Used --
   ------------------

   function Get_Is_Used (V : Value_T) return Boolean is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => False);

   begin
      return Present (Idx)
        and then Value_Data_Table.Table (Idx).Is_Used;

   end Get_Is_Used;

   -----------------
   -- Set_C_Value --
   -----------------

   procedure Set_C_Value (V : Value_T; S : Str) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).C_Value := S;
   end Set_C_Value;

   ---------------------
   -- Set_Is_Variable --
   ---------------------

   procedure Set_Is_Variable (V : Value_T; B : Boolean := True) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).Is_Variable := B;
   end Set_Is_Variable;

   ------------------------
   -- Set_Is_Decl_Output --
   ------------------------

   procedure Set_Is_Decl_Output (V : Value_T; B : Boolean := True) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).Is_Decl_Output := B;
   end Set_Is_Decl_Output;

   -----------------------------
   -- Set_Is_Temp_Decl_Output --
   -----------------------------

   procedure Set_Is_Temp_Decl_Output (V : Value_T; B : Boolean := True) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).Is_Temp_Decl_Output := B;
   end Set_Is_Temp_Decl_Output;

   ----------------
   -- Set_Is_LHS --
   ----------------

   procedure Set_Is_LHS (V : Value_T; B : Boolean := True) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).Is_LHS := B;
   end Set_Is_LHS;

   ---------------------
   -- Set_Is_Constant --
   ---------------------

   procedure Set_Is_Constant (V : Value_T; B : Boolean := True) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).Is_Constant := B;
   end Set_Is_Constant;

   ---------------------
   -- Set_Is_Unsigned --
   ---------------------

   procedure Set_Is_Unsigned (V : Value_T; B : Boolean := True) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).Is_Unsigned := B;
   end Set_Is_Unsigned;

   -----------------
   -- Set_Is_Used --
   -----------------

   procedure Set_Is_Used (V : Value_T; B : Boolean := True) is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);

   begin
      Value_Data_Table.Table (Idx).Is_Used := B;
   end Set_Is_Used;

   ---------------------------
   -- Get_Is_Typedef_Output --
   ---------------------------

   function Get_Is_Typedef_Output (T : Type_T) return Boolean is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => False);

   begin
      return Present (Idx)
        and then Type_Data_Table.Table (Idx).Is_Typedef_Output;
   end Get_Is_Typedef_Output;

   ----------------------------------
   -- Get_Is_Return_Typedef_Output --
   ----------------------------------

   function Get_Is_Return_Typedef_Output (T : Type_T) return Boolean is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => False);

   begin
      return Present (Idx)
        and then Type_Data_Table.Table (Idx).Is_Return_Typedef_Output;
   end Get_Is_Return_Typedef_Output;

   ------------------------------
   -- Get_Is_Incomplete_Output --
   ------------------------------

   function Get_Is_Incomplete_Output (T : Type_T) return Boolean is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => False);

   begin
      return Present (Idx)
        and then Type_Data_Table.Table (Idx).Is_Incomplete_Output;
   end Get_Is_Incomplete_Output;

   -----------------------------
   -- Get_Are_Writing_Typedef --
   -----------------------------

   function Get_Are_Writing_Typedef (T : Type_T) return Boolean is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => False);

   begin
      return Present (Idx)
        and then Type_Data_Table.Table (Idx).Are_Writing_Typedef;
   end Get_Are_Writing_Typedef;

   --------------------------
   -- Set_Is_Typedef_Output --
   --------------------------

   procedure Set_Is_Typedef_Output (T : Type_T; B : Boolean := True) is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => True);

   begin
      Type_Data_Table.Table (Idx).Is_Typedef_Output := B;
   end Set_Is_Typedef_Output;

   ----------------------------------
   -- Set_Is_Return_Typedef_Output --
   ----------------------------------

   procedure Set_Is_Return_Typedef_Output (T : Type_T; B : Boolean := True) is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => True);

   begin
      Type_Data_Table.Table (Idx).Is_Return_Typedef_Output := B;
   end Set_Is_Return_Typedef_Output;

   ------------------------------
   -- Set_Is_Incomplete_Output --
   ------------------------------

   procedure Set_Is_Incomplete_Output (T : Type_T; B : Boolean := True) is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => True);

   begin
      Type_Data_Table.Table (Idx).Is_Incomplete_Output := B;
   end Set_Is_Incomplete_Output;

   -----------------------------
   -- Set_Are_Writing_Typedef --
   -----------------------------

   procedure Set_Are_Writing_Typedef (T : Type_T; B : Boolean := True) is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => True);

   begin
      Type_Data_Table.Table (Idx).Are_Writing_Typedef := B;
   end Set_Are_Writing_Typedef;

   --------------------
   -- Get_Was_Output --
   --------------------

   function Get_Was_Output (BB : Basic_Block_T) return Boolean is
      Idx : constant BB_Idx := BB_Data_Idx (BB, Create => False);

   begin
      return Present (Idx) and then BB_Data_Table.Table (Idx).Was_Output;
   end Get_Was_Output;

   --------------------
   -- Set_Was_Output --
   --------------------

   procedure Set_Was_Output (BB : Basic_Block_T; B : Boolean := True) is
      Idx : constant BB_Idx := BB_Data_Idx (BB, Create => True);

   begin
      BB_Data_Table.Table (Idx).Was_Output := B;
   end Set_Was_Output;

   -------------------------
   -- Maybe_Write_Typedef --
   -------------------------

   procedure Maybe_Write_Typedef (T : Type_T; Incomplete : Boolean := False) is
   begin
      --  If we're writing this, have written it, or are just looking for
      --  an incomplete definition and have already written one, we don't
      --  need to do anything. Otherwise, write the typedef.
      if Get_Are_Writing_Typedef (T)
        or else Get_Is_Typedef_Output (T)
        or else (Incomplete and then Get_Is_Incomplete_Output (T))
      then
         null;
      else
         Write_Typedef (T, Incomplete => Incomplete);
      end if;
   end Maybe_Write_Typedef;

   --------------------
   -- Get_Output_Idx --
   --------------------

   function Get_Output_Idx (V : Value_T) return Nat is
      Idx : constant Value_Idx := Value_Data_Idx (V, Create => True);
      VD  : Value_Data renames Value_Data_Table.Table (Idx);

   begin
      if VD.Output_Idx = 0 then
         VD.Output_Idx := Output_Idx;
         Output_Idx    := Output_Idx + 1;
      end if;

      return VD.Output_Idx;
   end Get_Output_Idx;

   --------------------
   -- Get_Output_Idx --
   --------------------

   function Get_Output_Idx (T : Type_T) return Nat is
      Idx : constant Type_Idx := Type_Data_Idx (T, Create => True);
      TD  : Type_Data renames Type_Data_Table.Table (Idx);

   begin
      if TD.Output_Idx = 0 then
         TD.Output_Idx := Output_Idx;
         Output_Idx    := Output_Idx + 1;
      end if;

      return TD.Output_Idx;
   end Get_Output_Idx;

   --------------------
   -- Get_Output_Idx --
   --------------------

   function Get_Output_Idx (BB : Basic_Block_T) return Nat is
      Idx : constant BB_Idx := BB_Data_Idx (BB, Create => True);
      BBD : BB_Data renames BB_Data_Table.Table (Idx);

   begin
      if BBD.Output_Idx = 0 then
         BBD.Output_Idx := Output_Idx;
         Output_Idx     := Output_Idx + 1;
      end if;

      return BBD.Output_Idx;
   end Get_Output_Idx;

   --------------------
   -- Get_Output_Idx --
   --------------------

   function Get_Output_Idx return Nat is
      Result : constant Nat := Output_Idx;

   begin
      Output_Idx := Output_Idx + 1;
      return Result;
   end Get_Output_Idx;

end CCG.Tables;
