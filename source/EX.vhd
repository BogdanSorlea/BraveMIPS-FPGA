----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    02:25:41 04/22/2013 
-- Design Name: 
-- Module Name:    Execute - Behavioral 
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

entity Execute is

	generic(
		DATAPATH : natural := 16;		-- size of data passing through processor (in bits)
		OPERATION_SEL : natural := 3	-- size of selection vector for operation (in bits)
	);
	
	port(
		clk : in std_logic;
		reset : in std_logic;
		operAregSEL, operBregSEL : in std_logic;
		operation : in std_logic_vector(OPERATION_SEL - 1 downto 0);
		inDataS, inDataT, immediate, PC : in std_logic_vector(DATAPATH - 1 downto 0);
		result : out std_logic_vector(DATAPATH - 1 downto 0)
	);

end Execute;

architecture Behavioral of Execute is

	signal operatorA, operatorB, result_buf : std_logic_vector(DATAPATH - 1 downto 0);

begin

	operatorA <= inDataS when operAregSEL = '1' else PC;
	operatorB <= inDataT when operBregSEL = '1' else immediate;

	OP: process(operation, inDataS, inDataT, immediate, PC)
	begin
		case operation is
			when "000" => result_buf <= operatorA + operatorB;
			when "001" => result_buf <= operatorA - operatorB;
			when "010" => result_buf <= operatorA and operatorB;
			when "011" => result_buf <= operatorA or operatorB;
			when "100" => result_buf <= operatorA sll conv_integer(operatorB(2 downto 0));
			when "101" => result_buf <= operatorA srl conv_integer(operatorB(2 downto 0));
			when "110" => result_buf <= operatorA;
			when "111" => result_buf <= (others => '0');
		end case;
	end process;

end Behavioral;

