-------------------------------------------------------------------------------
-- Practica 2: Diseño de un procesador monociclo
-------------------------------------------------------------------------------
-- Autores    : 
-- Ariadna Sarai Lobato Brito
-- Luis Angel Palestina Cedeño
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Package1 is

type Byte is array ( natural range <>) of std_logic_vector(6 downto 0);
type Two_Byte is array ( natural range <>) of std_logic_vector(9 downto 0);
type status is(
		S_IDLE,
		S_LCD_ISSUE_INSTRUCTION,
		S_LCD_ISSUE_INSTRUCTION_delay
);

type PS2_status is(
		S_PS2_IDLE,
		S_PS2_ASSEMBLE_CODE,
		S_PS2_PARITY,
		S_PS2_STOP);
		
end Package1;

package body Package1 is
 
end Package1;
