----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    06:23:14 04/29/2013 
-- Design Name: 
-- Module Name:    mpg - Behavioral 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mpg_PC_test is

	port (
		clk : in std_logic;
		btn : in std_logic;
		reset : in std_logic;
		--step : out std_logic;
		sw : in std_logic_vector(1 downto 0);
		led : out std_logic_vector(7 downto 0)
	);

end mpg_PC_test;

architecture Behavioral of mpg_PC_test is

	signal q0, q1, q2, step : std_logic;
	signal cnt, btn_cnt : std_logic_vector(15 downto 0);
	
	signal tmpPC : std_logic_vector(15 downto 0);

begin

	COUNT : process(clk)
	begin
		if (rising_edge(clk)) then
			cnt <= cnt + '1';
		end if;
	end process;

	FF1 : process(cnt)
	begin
		if (rising_edge(cnt(cnt'high))) then
			q0 <= btn;
		end if;
	end process;

	FF : process(clk)
	begin
		if (rising_edge(clk)) then
			q1 <= q0;
			q2 <= q1;
		end if;
	end process;
	
	step <= q1 and not q2;
	
	process(step)
	begin
		if (rising_edge(step)) then
			btn_cnt <= btn_cnt + '1';
		end if;
	end process;
	
	tmpPC <= btn_cnt when sw(1) = '0' else "1001001001001001";
	led <= tmpPC(7 downto 0) when sw(0) = '0' else tmpPC(15 downto 8);

end Behavioral;