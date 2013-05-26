----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:28:16 05/26/2013 
-- Design Name: 
-- Module Name:    uart_receiver - Behavioral 
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

entity uart_receiver is

	port ( 
		clk : in  STD_LOGIC;
		din : in  STD_LOGIC;
		do : out  STD_LOGIC_VECTOR (7 downto 0);
		oe : out  STD_LOGIC
	);

end uart_receiver;

architecture Behavioral of uart_receiver is
	
	type state_type is (idle, start, data, stop, waits);
	signal state : state_type:=idle ;
	signal oversamp: std_logic;
	signal sum2: std_logic_vector(12 downto 0):="0000000000000";
	signal dout: std_logic_vector (7 downto 0):="00000000";
	signal cnt: std_logic_vector (2 downto 0):="000";
	signal cnt2: std_logic_vector (3 downto 0):="0000";
	signal shift_en: std_logic;
	signal clk50 : std_logic;

begin

	do <= dout;
		
	process(clk)
	begin 
		if rising_edge(clk) then
			clk50 <= not clk50;
		end if;
	end process;
	
	--output enable
	process(state)
	begin
		if state=waits then
			oe <= '1';
		else
			oe <= '0';
		end if;
	end process;
		
	--oversampling clock
	process(clk50)
	begin
		if rising_edge(clk50) then
			if sum2 = 325 then
				sum2<=(others => '0');
				oversamp <= '1';
			else 
				sum2<=sum2+1;
				oversamp <= '0';
			end if;
		end if;
	end process;
	
	--FSM
	process(clk50)
	begin
		if rising_edge(clk50) then
			case state is
				when idle => 
				if oversamp = '1' then
					if din = '0' then
						state <= start;
						cnt2<="0000";
					end if;
				end if;
				
				when start => 
					if oversamp = '1' then
						if din = '0' then
							if cnt2="0111" then
								cnt2 <= "0000";
								cnt <= "000";
								state <= data;
							else
								cnt2 <= cnt2 + 1;
								state <= start;
							end if;
						else
							cnt2 <= "0000";
							state <= idle;
						end if;						
					end if;
									
				when data => 
					if oversamp = '1' then
						if cnt2 = "1111" then
							if cnt = "111" then
								state <= waits;
								cnt <= "000";
								cnt2 <= "0000";
							else
								cnt <= cnt + 1;
								cnt2 <= "0000";
								state <= data;
							end if;
						else
							cnt2 <= cnt2+1;
							state <= data;
						end if;
					else
						state <= data;
					end if;
					
				when stop =>
					if oversamp = '1' then
						if cnt2 = "1111" then
							cnt2 <= "0000";
							state <= waits;
						else
							cnt2 <= cnt2+1;
							state <= stop;
						end if;
					end if;
					
				when waits =>
					if oversamp = '1' then
						if cnt2 = "0111" then
							state <= idle;
							cnt2 <= (others => '0');
						else
							state <= waits;
							cnt2 <= cnt2 + 1;
						end if;
					end if;
					
				when others => state <= idle;
			end case;
		end if;
	end process;
	
	--shift enable
	process(state,cnt2)
	begin
		case state is
			when idle => shift_en <= '0';
			when start => shift_en <= '0';
			when data => 
				if cnt2 = "1111" then 
					shift_en<= '1'; 
				else
					shift_en<= '0'; 
				end if;
						
			when stop => shift_en <= '0';
			when waits => shift_en <= '0';
			when others => shift_en <= '0';
		end case;
	end process;
	
	--get data in and shift output register
	process(clk50) 	
	begin
		if rising_edge(clk50) then
			if oversamp = '1' then
				if shift_en = '1' then
					dout(7) <= din;
					for i in 0 to 6 loop
						dout(i) <= dout(i + 1);
					end loop;
				end if;
			end if;
		end if;
	end process;

end Behavioral;