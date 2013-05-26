----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:16:48 05/24/2013 
-- Design Name: 
-- Module Name:    uart_ex1 - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_ex1 is

	generic (addr_bits : integer := 1);
   port (
		clk     : in std_logic;
		reset   : in std_logic;
		led     : out std_logic;
		leds : out std_logic_vector(6 downto 0);
		txd : out std_logic;
		rxd : in std_logic
		--rd,wr   : out std_logic;
		--wr_data : out std_logic_vector(31 downto 0);
		--address : out std_logic_vector(addr_bits-1 downto 0);
		--ncts    : out std_logic
	);

end uart_ex1;

architecture Behavioral of uart_ex1 is

	constant CLOCK_FREQ : integer := 100000000;
	constant LED_FREQ : integer := 1;
	constant COUNT : integer := CLOCK_FREQ/LED_FREQ/2 - 1;
	
	signal counter : unsigned(25 downto 0);
	signal led_tmp, led_flag : std_logic;
	
	signal wr : std_logic;
	signal wr_data : std_logic_vector(31 downto 0);
	signal wrt_data : std_logic_vector(7 downto 0);
	
	signal rd_data : std_logic_vector(31 downto 0);
	
	signal rdy_cnt : unsigned(1 downto 0);
	signal nrts : std_logic;
	
	component sc_uart is
	
		generic (
			addr_bits : integer;
			clk_freq : integer;
			baud_rate : integer;
			txf_depth : integer; txf_thres : integer;
			rxf_depth : integer; rxf_thres : integer
		);
		port (
			clk		: in std_logic;
			reset	: in std_logic;

			-- SimpCon interface

			address		: in std_logic_vector(addr_bits-1 downto 0);
			wr_data		: in std_logic_vector(31 downto 0);
			rd, wr		: in std_logic;
			rd_data		: out std_logic_vector(31 downto 0);
			rdy_cnt		: out unsigned(1 downto 0);

			txd		: out std_logic;
			rxd		: in std_logic;
			ncts	: in std_logic;
			nrts	: out std_logic
		);
	end component;
	
	component uart_transmitter is
	
		generic ( N : integer := 8 );
		port ( 
			clk : in  STD_LOGIC;
			di : in  STD_LOGIC_VECTOR (N-1 downto 0);
			en : in STD_LOGIC;
			do : out  STD_LOGIC
		);
	
	end component;

begin

	TXX: uart_transmitter
		generic map(
			N => 8
		) port map (
			clk => clk,
			di => wrt_data,
			en => wr,
			do => txd
		);

	UART: sc_uart
		generic map (
			addr_bits => 2,--addr_bits,
			clk_freq => 100000000,
			baud_rate => 9600,
			txf_depth => 8, txf_thres => 8, rxf_depth => 8, rxf_thres => 8
		) port map (
			clk => clk, 
			reset => reset,
			address => "01",
			wr_data => wr_data,
			rd => '1',
			wr => wr,
			rd_data => rd_data,
			rdy_cnt => rdy_cnt, -- even if left open it has the same behavior (not working)
			txd => open,
			rxd => rxd,
			ncts => '0',
			nrts => nrts
		);
	
	process(led_flag, led_tmp)
	begin
		
		if led_flag = '1' then
			wr <= '1';
			if led_tmp = '1' then
				wr_data <= x"000000" & x"31";
				wrt_data <= x"31";
			else
				wr_data <= x"000000" & x"30";
				wrt_data <= x"30";
			end if;
		else	
			wr <= '0';
			wr_data <= (others => '0');
			wrt_data <= (others => '0');
		end if;
		
	end process;
	
	process(clk)
	begin
	
		if rising_edge(clk) then
		
			if reset = '0' then
			
				counter <= (others => '0');
				led_tmp <= '0';
				led_flag <= '0';
				
			else
			
				if counter = COUNT then
					counter <= (others => '0');
					led_tmp <= not led_tmp;
					led_flag <= '1';
				else
					counter <= counter + 1;
					led_flag <= '0';
				end if;
				
			end if;
		
		end if;
	
	end process;
	
	led <= led_tmp;
	leds <= rd_data(6 downto 0);
	
end Behavioral;