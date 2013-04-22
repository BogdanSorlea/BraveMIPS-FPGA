----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:25:42 04/22/2013 
-- Design Name: 
-- Module Name:    RegisterFile - Behavioral 
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

entity RegisterFile is

	generic(
		REGISTER_SIZE : natural := 16;	-- size of the register in bits
		FILE_SIZE : natural := 16;			-- size of file (number of lines/registers in the file)
		FILE_SEL : natural := 4				-- size of the selection vector for the file (equal to log FILE_SIZE)
	);
	
	port(
		clk : in std_logic;
		--reset : in std_logic;
		we : in std_logic;
		rdAddrS, rdAddrT, wrAddrD : in std_logic_vector(FILE_SEL - 1 downto 0);
		wrData : in std_logic_vector(REGISTER_SIZE - 1 downto 0);
		rdDataS, rdDataT : out std_logic_vector(REGISTER_SIZE - 1 downto 0)
	);

end RegisterFile;

architecture Behavioral of RegisterFile is

	type register_ram is array(0 to FILE_SIZE - 1) of std_logic_vector(REGISTER_SIZE - 1 downto 0);
	signal RRAM : register_ram := (others => (others => '1'));

begin

	rdDataS <= RRAM(conv_integer(rdAddrS));
	rdDataT <= RRAM(conv_integer(rdAddrT));
	
	SEQ: process(clk, we, rdAddrS, rdAddrT, wrAddrD, wrData)
	begin
		
		if ( rising_edge(clk) ) then
			if ( we = '1' ) then
				RRAM(conv_integer(wrAddrD)) <= wrData;
			end if;
			
			RRAM(0) <= (others => '0');
		end if;
		
	end process;

end Behavioral;

