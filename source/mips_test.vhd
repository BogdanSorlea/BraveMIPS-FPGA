--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   02:59:11 04/25/2013
-- Design Name:   
-- Module Name:   D:/Study/DTU/1/02211/BraveMIPS/source/mips_test.vhd
-- Project Name:  BraveMIPS
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mips
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY mips_test IS
END mips_test;
 
ARCHITECTURE behavior OF mips_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mips
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
			sw : IN std_logic_vector(1 downto 0);
			led : OUT std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
	signal sw : std_logic_vector(1 downto 0) := "00";
	
	--Outputs
	signal led : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	signal count : natural := 0;
	signal clk_en : std_logic := '0';
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mips PORT MAP (
          clk => clk,
          reset => reset,
			 sw => sw,
			 led => led
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0' and clk_en;
		wait for clk_period/2;
		clk <= '1' and clk_en;
		wait for clk_period/2;
   end process;
 
	clk_en_process: process
	begin
		clk_en <= '1';
		wait for clk_period * 100;
		clk_en <= '0';
		wait for clk_period * 1000;
	end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
