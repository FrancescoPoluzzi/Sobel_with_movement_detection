--------------------------------------------------------------------------------
-- $RCSfile: $
--
-- DESC    : OpenRisk 1420 
--
-- AUTHOR  : Dr. Theo Kluter
--
-- CVS     : $Revision: $
--           $Date: $
--           $Author: $
--           $Source: $
--
--------------------------------------------------------------------------------
--
--  HISTORY :
--
--  $Log: 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY bios_rom IS
   PORT ( address : IN  unsigned( 10 DOWNTO 0 );
          data    : OUT std_logic_vector(31 DOWNTO 0));
END bios_rom;
