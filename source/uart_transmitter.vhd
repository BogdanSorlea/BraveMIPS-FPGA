----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:38:14 05/26/2013 
-- Design Name: 
-- Module Name:    uart_transmitter - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_transmitter is

	Generic ( N : integer := 8 );
	Port ( 
		clk : in  STD_LOGIC;
		di : in  STD_LOGIC_VECTOR (N-1 downto 0);
		en : in STD_LOGIC;
		do : out  STD_LOGIC
	);

end uart_transmitter;

architecture Behavioral of uart_transmitter is

	signal cnt : std_logic_vector(13 downto 0) := (others=>'0');
	signal e,load,q : std_logic := '0';
	signal reg : std_logic_vector(N downto 0) := (others=>'1');

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if load='1' then
				reg <= "0" & di;
			else
				if q='1' then
					reg <= reg(N-1 downto 0)&"1";
				end if;
			end if;
		end if;
	end process;
	
	do <= reg(N);

	process(clk)
	begin
		if rising_edge(clk) then
			e <= en;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			load <= en and not e;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if load = '1' then
				cnt <= "00000000000010";				
			else
				if cnt="10100010110000" then
					cnt <= "00000000000001";
				else
					cnt <= cnt + 1;
				end if;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if cnt = "00000000000001" then
				q <= '1';
			else
				q <= '0';
			end if;
		end if;
	end process;

end Behavioral;