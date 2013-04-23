----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    03:05:35 04/22/2013 
-- Design Name: 
-- Module Name:    MIPSController - Behavioral 
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

entity MIPSController is

	port(
		opcode : in std_logic_vector(3 downto 0);
		ALUop : out std_logic_vector(2 downto 0);
		ALUsrc, regDest, beq, bneq, memWE, regWE, WBSel, jump, signExtend : std_logic
	);

end MIPSController;

architecture Behavioral of MIPSController is

	signal ctrl_reg : std_logic_vector(11 downto 0);

begin

	jump <= ctrl_reg(11);
	ALUsrc <= ctrl_reg(10);
	regDest <= ctrl_reg(9);
	beq <= ctrl_reg(8);
	bneq <= ctrl_reg(7);
	memWE <= ctrl_reg(6);
	regWE <= ctrl_reg(5);
	WBSel <= ctrl_reg(4);
	signExtend <= ctrl_reg(3);
	ALUop(2 downto 0) <= ctrl_reg(2 downto 0);
	
	OPCODE: process(opcode)
	begin
		case opcode is
			when "0000" => ctrl <= "001000100000";  -- 
			when "0001" => ctrl <= "001000100001";
			when "0010" => ctrl <= "010000101000";
			when "0011" => ctrl <= "010000111000";
			when "0100" => ctrl <= "010001001000";
			when "0101" => ctrl <= "000100001001";
			when "0110" => ctrl <= "000010001001";
			when "0111" => ctrl <= "010000101100";
			when "1000" => ctrl <= "010000101101";
			when "1001" => ctrl <= "010000101001";
			when "1010" => ctrl <= "000000000111";
			when "1011" => ctrl <= "100000000111";
			when "1100" => ctrl <= "001000100010";
			when "1101" => ctrl <= "001000100011";
			when "1110" => ctrl <= "010000101010";
			when "1111" => ctrl <= "010000101011";
			when others => ctrl <= "000000000000";
		end case;
	end process;

end Behavioral;

