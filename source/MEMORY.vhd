----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:57:46 04/22/2013 
-- Design Name: 
-- Module Name:    Memory - Behavioral 
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

entity Memory is

	generic(
		MEMORY_SIZE : natural := 16;		-- number of lines in memory
		MEMORY_SEL : natural := 4;			-- number of bits of vector selection
		LINE_SIZE : natural := 16			-- number of bits on line
	);
	
	port(
		clk : in std_logic;
		we : in std_logic;
		addr : in std_logic_vector(MEMORY_SEL - 1 downto 0);
		wrData : in std_logic_vector(MEMORY_SIZE - 1 downto 0);
		rdData : out std_logic_vector(MEMORY_SIZE - 1 downto 0)
	);

end Memory;

architecture Behavioral of Memory is

	type memory_ram is array (15 downto 0) of std_logic_vector (15 downto 0);
	signal MRAM : memory_ram;

begin

	SEQ: process(clk)
	begin
		
		if ( rising_edge(clk) ) then
			if ( we = '1' ) then
				MRAM(conv_integer(addr)) <= wrData;
			end if;
			rdData <= MRAM(conv_integer(addr));			-- shouldn't worry about simultaneous RD/WR
		end if;
		
	end process;

end Behavioral;

