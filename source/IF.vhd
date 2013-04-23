----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:07:02 04/22/2013 
-- Design Name: 
-- Module Name:    InstructionFetch - Behavioral 
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

entity InstructionFetch is

	generic(
		DATAPATH : natural := 32;			-- size of datapath
		MEMORY_SIZE : natural := 32; 		-- size of the memory, in "lines"
		MEMORY_SEL : natural := 5			-- size of the selection vector for lines in the memory 
													--			(equal to log MEMORY_SIZE)
	);

	port(
		clk : in std_logic;
		reset : in std_logic;
		beq, bneq, zero, jump : in std_logic;
		branchPC, jumpPC : in std_logic_vector(15 downto 0);
		PC_i : in std_logic_vector(15 downto 0);
		PC_o : out std_logic_vector(15 downto 0);
		instr : out std_logic_vector(15 downto 0)
	);
	
end InstructionFetch;

architecture Behavioral of InstructionFetch is

	type instruction_ram is array(0 to MEMORYSIZE - 1) of std_logic_vector(DATAPATH - 1 downto 0);
	constant IRAM : ram := (others => (others => '0'));
	
	signal nextPC : std_logic_vector(15 downto 0);

begin

	instr <= IRAM(conv_integer( PC_i(MEMORY_SEL downto INSTR_BYTE_SEL) ));

	CL: process(branchPC, jumpPC, beq, bneq, zero, jump)
	begin
	
		if ( (beq = '1' and zero = '1') or (bneq = '1' and zero = '0') ) then
			nextPC <= branchPC;
		elsif ( jump = '1' ) then
			nextPC <= jumpPC;
		else
			nextPC <= PC_i + INSTR_BYTE_SIZE;
		end if;
	
	end process;
	
	SEQ: process(clk, reset, nextpc)
	begin
		
		if ( reset = '1' ) then
			PC_o <= (others => '0');
		elsif ( rising_edge(clk) ) then
			PC_o <= nextPC;
		end if;
		
	end process;

end Behavioral;

