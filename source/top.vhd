----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    03:34:39 04/25/2013 
-- Design Name: 
-- Module Name:    top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is

	port(
		clk, reset : in std_logic;
		led : out std_logic
	);

end top;

architecture Behavioral of top is

	component mips is
		generic(
		DATAPATH : natural := 32;			-- datapath size in bits
		INMEM_SIZE : natural := 256;		-- instruction memory size in lines
		INMEM_SEL : natural := 8;			-- instruction memory select vector size in bits (eq. to log INMEM_SIZE)
		REGFILE_SIZE : natural := 32;		-- register file size in lines
		REGFILE_SEL : natural := 5;		-- register file select vector size in bits (eq. to log REGFILE_SIZE)
		MEMORY_SIZE : natural := 64;		-- memory size in lines
		MEMORY_SEL : natural := 6;			-- memory select vector size in bits (eq. to log MEMORY_SIZE)
		
		-- Instr. Type - Format
		--	R           - | 31  opcode  26 | 25  rs 21  | 20  rt  16 | 15  rd  11 | 10  shamt  6 | 5  funct  0 |
		-- I				- | 31  opcode  26 | 25  rs 21  | 20  rt  16 | 15             immediate              0 |
		-- J				- | 31  opcode  26 | 25                       	   address	 								 0 |
		
		F_OPCODE_LEFT : natural := 31;
		F_OPCODE_RIGHT : natural := 26;
		F_RS_LEFT : natural := 25;
		F_RS_RIGHT : natural := 21;
		F_RT_LEFT : natural := 20;
		F_RT_RIGHT : natural := 16;
		F_RD_LEFT : natural := 15;
		F_RD_RIGHT : natural := 11;
		F_SHAMT_LEFT : natural := 10;
		F_SHAMT_RIGHT : natural := 6;
		F_FUNCT_LEFT : natural := 5;
		F_FUNCT_RIGHT : natural := 0;
		F_IMMEDIATE_LEFT : natural := 15;
		F_IMMEDIATE_RIGHT : natural := 0;
		F_ADDRESS_LEFT : natural := 25;
		F_ADDRESS_RIGHT : natural := 0
	);
	
	port(
		clk, reset : in std_logic;
		led : out std_logic
	);
	end component;

begin

	MIPS_1: mips port map(clk => clk, reset => reset, led => led);

end Behavioral;

