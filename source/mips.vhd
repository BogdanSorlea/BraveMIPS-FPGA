----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:35:51 04/22/2013 
-- Design Name: 
-- Module Name:    mips - Behavioral 
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

entity mips is

	generic(
		DATAPATH : natural := 32;			-- datapath size in bits
		INMEM_SIZE : natural := 256;		-- instruction memory size in lines
		INMEM_SEL : natural := 8;			-- instruction memory select vector size in bits (eq. to log INMEM_SIZE)
		REGFILE_SIZE : natural := 32;		-- register file size in lines
		REGFILE_SEL : natural := 5;		-- register file select vector size in bits (eq. to log REGFILE_SIZE)
		MEMORY_SIZE : natural := 64;		-- memory size in lines
		MEMORY_SEL : natural := 6;			-- memory select vector size in bits (eq. to log MEMORY_SIZE)
		
		-- Instr. Type - Format
		--	R           - | 31  opcode  26 | 25  rs 21  | 20  rt  16 | 15  rd  11 | 10  shamt  6 | 5  funct  0 |
		-- I				- | 31  opcode  26 | 25  rs 21  | 20  rt  16 | 15             immediate              0 |
		-- J				- | 31  opcode  26 | 25                       	   address	 								 0 |
		
		F_OPCODE_LEFT : natural := 31;
		F_OPCODE_RIGHT : natural := 26;
		F_RS_LEFT : natural := 25;
		F_RS_RIGHT : natural := 21;
		F_RT_LEFT : natural := 20;
		F_RT_RIGHT : natural := 16;
		F_RD_LEFT : natural := 15;
		F_RD_RIGHT : natural := 11;
		F_SHAMT_LEFT : natural := 10;
		F_SHAMT_RIGHT : natural := 6;
		F_FUNCT_LEFT : natural := 5;
		F_FUNCT_RIGHT : natural := 0;
		F_IMMEDIATE_LEFT : natural := 15;
		F_IMMEDIATE_RIGHT : natural := 0;
		F_ADDRESS_LEFT : natural := 25;
		F_ADDRESS_RIGHT : natural := 0
	);
	
	port(
		clk, reset : in std_logic;
		sw : in std_logic_vector(7 downto 0);
		led : out std_logic_vector(7 downto 0)
	);

end mips;

architecture Behavioral of mips is

	---------- MEMORY TYPES DECLARATIONS -----------
	
	type inmem_ram is array(0 to INMEM_SIZE - 1) of std_logic_vector(DATAPATH - 1 downto 0);
	type regfile_ram is array(0 to REGFILE_SIZE - 1) of std_logic_vector(DATAPATH - 1 downto 0);
	type memory_ram is array(0 to MEMORY_SIZE - 1) of std_logic_vector(DATAPATH - 1 downto 0);
	
	------------------------------------------------
	
	----------- BETWEEN-STAGE REGISTERS ------------
	
	type IF_ID_REG is
		record
			instruction : std_logic_vector(DATAPATH - 1 downto 0);
			next_seq_PC : std_logic_vector(DATAPATH - 1 downto 0);
		end record;
		
	type ID_EX_REG is
		record
			sourceValue, targetValue : std_logic_vector(DATAPATH - 1 downto 0);
			immediateValue : std_logic_vector(DATAPATH - 1 downto 0);
			destinationRegAddress : std_logic_vector(F_RD_LEFT - F_RD_RIGHT downto 0);
			next_seq_PC : std_logic_vector(DATAPATH - 1 downto 0);
			WBSelectALU : std_logic;
			REGFILE_WE, MEMORY_WE : std_logic;
			beq, bneq, jump : std_logic;
			isSourcePC, isTargetImmediate : std_logic;
			ALUoperation : std_logic_vector(F_FUNCT_LEFT - F_FUNCT_RIGHT downto 0);
		end record;
		
	type EX_MEM_REG is
		record
			ALUresult : std_logic_vector(DATAPATH - 1 downto 0);
			destinationRegAddress : std_logic_vector(F_RD_LEFT - F_RD_RIGHT downto 0);
			next_seq_PC : std_logic_vector(DATAPATH - 1 downto 0);
			targetValue : std_logic_vector(DATAPATH - 1 downto 0);
			MEMORY_WE : std_logic;
			differenceIsZero : std_logic;
			WBSelectALU : std_logic;
			REGFILE_WE : std_logic;
			beq, bneq, jump : std_logic;
		end record;
	
	type MEM_WB_REG is
		record
			ALUresult : std_logic_vector(DATAPATH - 1 downto 0);
			destinationRegAddress : std_logic_vector(F_RD_LEFT - F_RD_RIGHT downto 0);
			MEMresult : std_logic_vector(DATAPATH - 1 downto 0);
			WBSelectALU : std_logic;
			REGFILE_WE : std_logic;
		end record;
	
	------------------------------------------------
	
	constant SH_NIL : std_logic_vector(4 downto 0) := "-----";
	constant RG_NIL : std_logic_vector(4 downto 0) := "-----";
	
	---------- OPCODE (MNEMONIC) CONSTANTS ---------
	
	constant MN_ZERO : std_logic_vector(5 downto 0) := "000000";
	constant MN_ADDI : std_logic_vector(5 downto 0) := "001000";
	constant MN_LW : std_logic_vector(5 downto 0) := "100011";
	constant MN_SW : std_logic_vector(5 downto 0) := "101011";
	constant MN_ANDI : std_logic_vector(5 downto 0) := "001100";
	constant MN_ORI : std_logic_vector(5 downto 0) := "001101";
	constant MN_SLTI : std_logic_vector(5 downto 0) := "001010";
	constant MN_BEQ : std_logic_vector(5 downto 0) := "000100";
	constant MN_BNEQ : std_logic_vector(5 downto 0) := "000101";
	
	-------------- FUNCTION CONSTANTS --------------
	
	constant FN_ADD : std_logic_vector(5 downto 0) := "100000";
	constant FN_SUB : std_logic_vector(5 downto 0) := "100010";
	constant FN_AND : std_logic_vector(5 downto 0) := "100100";
	constant FN_OR : std_logic_vector(5 downto 0) := "100101";
	constant FN_XOR : std_logic_vector(5 downto 0) := "100110";
	constant FN_NOR : std_logic_vector(5 downto 0) := "100111";
	constant FN_SLT : std_logic_vector(5 downto 0) := "101010";
	constant FN_SLL : std_logic_vector(5 downto 0) := "000000";
	constant FN_SRL : std_logic_vector(5 downto 0) := "000010";
	
	-------------- REGISTER CONSTANTS --------------
	
	constant RG_0 : std_logic_vector(4 downto 0) := conv_std_logic_vector(0, 5);
	constant RG_1 : std_logic_vector(4 downto 0) := conv_std_logic_vector(1, 5);
	constant RG_2 : std_logic_vector(4 downto 0) := conv_std_logic_vector(2, 5);
	constant RG_3 : std_logic_vector(4 downto 0) := conv_std_logic_vector(3, 5);
	constant RG_4 : std_logic_vector(4 downto 0) := conv_std_logic_vector(4, 5);
	constant RG_5 : std_logic_vector(4 downto 0) := conv_std_logic_vector(5, 5);
	constant RG_6 : std_logic_vector(4 downto 0) := conv_std_logic_vector(6, 5);
	constant RG_7 : std_logic_vector(4 downto 0) := conv_std_logic_vector(7, 5);
	constant RG_8 : std_logic_vector(4 downto 0) := conv_std_logic_vector(8, 5);
	constant RG_9 : std_logic_vector(4 downto 0) := conv_std_logic_vector(9, 5);
	constant RG_10 : std_logic_vector(4 downto 0) := conv_std_logic_vector(10, 5);
	constant RG_11 : std_logic_vector(4 downto 0) := conv_std_logic_vector(11, 5);
	constant RG_12 : std_logic_vector(4 downto 0) := conv_std_logic_vector(12, 5);
	constant RG_13 : std_logic_vector(4 downto 0) := conv_std_logic_vector(13, 5);
	constant RG_14 : std_logic_vector(4 downto 0) := conv_std_logic_vector(14, 5);
	constant RG_15 : std_logic_vector(4 downto 0) := conv_std_logic_vector(15, 5);
	constant RG_16 : std_logic_vector(4 downto 0) := conv_std_logic_vector(16, 5);
	constant RG_17 : std_logic_vector(4 downto 0) := conv_std_logic_vector(17, 5);
	constant RG_18 : std_logic_vector(4 downto 0) := conv_std_logic_vector(18, 5);
	constant RG_19 : std_logic_vector(4 downto 0) := conv_std_logic_vector(19, 5);
	constant RG_20 : std_logic_vector(4 downto 0) := conv_std_logic_vector(20, 5);
	constant RG_21 : std_logic_vector(4 downto 0) := conv_std_logic_vector(21, 5);
	constant RG_22 : std_logic_vector(4 downto 0) := conv_std_logic_vector(22, 5);
	constant RG_23 : std_logic_vector(4 downto 0) := conv_std_logic_vector(23, 5);
	constant RG_24 : std_logic_vector(4 downto 0) := conv_std_logic_vector(24, 5);
	constant RG_25 : std_logic_vector(4 downto 0) := conv_std_logic_vector(25, 5);
	constant RG_26 : std_logic_vector(4 downto 0) := conv_std_logic_vector(26, 5);
	constant RG_27 : std_logic_vector(4 downto 0) := conv_std_logic_vector(27, 5);
	constant RG_28 : std_logic_vector(4 downto 0) := conv_std_logic_vector(28, 5);
	constant RG_29 : std_logic_vector(4 downto 0) := conv_std_logic_vector(29, 5);
	constant RG_30 : std_logic_vector(4 downto 0) := conv_std_logic_vector(30, 5);
	constant RG_31 : std_logic_vector(4 downto 0) := conv_std_logic_vector(31, 5);
	
	------------------------------------------------
	
	--"" & "" & "" & "", -- I instruction... opcode | rs | rt | imm
	constant INMEM : inmem_ram := (
		(others => '0'),														-- nop
		MN_ADDI & RG_0 & RG_5 & conv_std_logic_vector(13, 16), 	-- I instr... opcode | rs | rt | imm
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_5 & RG_5 & RG_6 & SH_NIL & FN_ADD,				-- R instr... opcode = 0 | rs | rt | rd | sh | funct
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ADDI & RG_0 & RG_5 & conv_std_logic_vector(3, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_6 & RG_5 & RG_6 & SH_NIL & FN_SUB,				-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_SW & RG_0 & RG_5 & conv_std_logic_vector(2, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_LW & RG_0 & RG_7 & conv_std_logic_vector(2, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ADDI & RG_0 & RG_4 & conv_std_logic_vector(6, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_4 & RG_5 & RG_5 & SH_NIL & FN_AND,				-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ANDI & RG_4 & RG_3 & conv_std_logic_vector(15, 16),	-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_7 & RG_3 & RG_3 & SH_NIL & FN_OR,				-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ORI & RG_5 & RG_5 & conv_std_logic_vector(8, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_5 & RG_7 & RG_7 & SH_NIL & FN_XOR,				-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ADDI & RG_0 & RG_1 & "1111111111110000",					-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_7 & RG_1 & RG_1 & SH_NIL & FN_NOR,				-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_7 & RG_1 & RG_1 & SH_NIL & FN_SLT,				-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_SLTI & RG_7 & RG_3 & conv_std_logic_vector(0, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_NIL & RG_1 & RG_1 & "00010" & FN_SLL,			-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ZERO & RG_NIL & RG_7 & RG_7 & "00010" & FN_SRL,			-- R
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_BEQ & RG_0 & RG_3 & conv_std_logic_vector(5, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_ADDI & RG_0 & RG_2 & conv_std_logic_vector(3, 16),		-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		MN_BNEQ & RG_7 & RG_2 & conv_std_logic_vector(1, 16),		-- I
		MN_ADDI & RG_7 & RG_7 & conv_std_logic_vector(2, 16),		-- I
		MN_ADDI & RG_7 & RG_7 & conv_std_logic_vector(14, 16),	-- I
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '0'),														-- nop
		(others => '1'),														-- nop
		others => (others => '0')
	);
	signal REGFILE : regfile_ram := (others => (others => '0'));
	signal MEMORY : memory_ram := (others => (others => '0'));
	
	signal IFID : IF_ID_REG;
	signal IDEX : ID_EX_REG;
	signal EXMEM : EX_MEM_REG;
	signal MEMWB : MEM_WB_REG;
	
	----------- "TEMPORARY" SIGNALS (FF) -----------
	
	signal instruction, operatorSource, operatorTarget, regfileWBValue : std_logic_vector(DATAPATH - 1 downto 0);
	signal shiftResult, shiftResultL, shiftResultR, lessThanResult : std_logic_vector(DATAPATH - 1 downto 0);
	signal jumpOrBranchPC, PC_in : std_logic_vector(DATAPATH - 1 downto 0);
	signal PC : std_logic_vector(DATAPATH-1 downto 0) := (others => '0');
	
	------------------------------------------------
	
	----------- CONTROL SIGNALS -----------
	
	signal signExtend, isDestinationTarget: std_logic;
	signal controlReg : std_logic_vector(15 downto 0);
	
	---------------------------------------
	
	--------------- HELPERS ---------------

	constant zeroArray : std_logic_vector(DATAPATH - 1 downto 0) := (others => '0');
	
	---------------------------------------
	
	signal led_instruction, led_regdata, led_pc : std_logic_vector(7 downto 0);
	signal led_regfile : std_logic_vector(31 downto 0);

begin

	-- TODO: remove this at some point (kept here just to have some output)
	
	led_pc <= PC(7 downto 0);
	led_instruction <= IFID.instruction(7 downto 0) when sw(1 downto 0) = "00" else
				IFID.instruction(15 downto 8) when sw(1 downto 0) = "01" else
				IFID.instruction(23 downto 16) when sw(1 downto 0) = "10" else
				IFID.instruction(31 downto 24);
	led_regfile <= REGFILE(conv_integer("0" & sw(5 downto 2)));
	led_regdata <= led_regfile(7 downto 0) when sw(1 downto 0) = "00" else
				led_regfile(15 downto 8) when sw(1 downto 0) = "01" else
				led_regfile(23 downto 16) when sw(1 downto 0) = "10" else
				led_regfile(31 downto 24);

	led <= led_pc when sw(7 downto 6) = "00" else
				led_regdata when sw(7 downto 6) = "11" else
				led_instruction; 
	
	
--	led <= IFID.instruction(7 downto 0) when sw = "00" else
--				IFID.instruction(15 downto 8) when sw = "01" else
--				IFID.instruction(23 downto 16) when sw = "10" else
--				IFID.instruction(31 downto 24); 

	---------- INSTRUCTION FETCH ----------
	PC_in <= EXMEM.ALUresult when 
						(EXMEM.jump = '1' 
						or (EXMEM.beq = '1' and EXMEM.differenceIsZero = '1') 
						or (EXMEM.bneq = '1' and EXMEM.differenceIsZero = '0')) 
				else (PC + 1);
	
	SEQ_IF: process(clk, reset)
	begin
	
		if (reset = '0') then
			PC <= (others => '0');
			
			IFID.instruction <= (others => '0');
		elsif ( rising_edge(clk) ) then
		
			PC <= PC_in;
			
			IFID.next_seq_PC <= PC + 1;
			IFID.instruction <= INMEM(conv_integer( PC(INMEM_SEL - 1 downto 0) ));
			
		end if;
	
	end process;
	
	---------------------------------------
	
	--------- INSTRUCTION DECODE ----------
	
	regfileWBValue <= MEMWB.ALUresult when MEMWB.WBSelectALU = '1' else MEMWB.MEMresult;
	
	SEQ_ID: process(clk, reset, signExtend)
	begin
	
		--REGFILE <= (others => (others => '0'));
	
		if (reset = '0') then
			IDEX.next_seq_PC <= (others => '0');
		elsif ( rising_edge(clk) ) then
		
			if ( MEMWB.REGFILE_WE = '1' ) then		
				REGFILE(conv_integer(MEMWB.destinationRegAddress)) <= regfileWBValue;
			end if;
		
			if ( conv_integer( IFID.instruction(F_RS_LEFT downto F_RS_RIGHT)) = 0 ) then
				IDEX.sourceValue <= (others => '0');
			elsif (conv_integer(MEMWB.destinationRegAddress)
						= conv_integer( IFID.instruction(F_RS_LEFT downto F_RS_RIGHT))) then
				IDEX.sourceValue <= regfileWBValue;
			else
				IDEX.sourceValue <= REGFILE(conv_integer( IFID.instruction(F_RS_LEFT downto F_RS_RIGHT)));
			end if;
			
			if ( conv_integer( IFID.instruction(F_RT_LEFT downto F_RT_RIGHT)) = 0 ) then
				IDEX.targetValue <= (others => '0');
			elsif (conv_integer(MEMWB.destinationRegAddress)
						= conv_integer( IFID.instruction(F_RT_LEFT downto F_RT_RIGHT))) then
				IDEX.targetValue <= regfileWBValue;
			else
				IDEX.targetValue <= REGFILE(conv_integer( IFID.instruction(F_RT_LEFT downto F_RT_RIGHT)));
			end if;
			
			IDEX.immediateValue(15 downto 0) <= IFID.instruction(F_IMMEDIATE_LEFT downto F_IMMEDIATE_RIGHT);
			IDEX.immediateValue(31 downto 16) <= (others => IFID.instruction(F_IMMEDIATE_LEFT) and signExtend);
			
			if ( isDestinationTarget = '1' ) then
				IDEX.destinationRegAddress <= IFID.instruction(F_RT_LEFT downto F_RT_RIGHT);
			else 
				IDEX.destinationRegAddress <= IFID.instruction(F_RD_LEFT downto F_RD_RIGHT);
			end if;
		
			IDEX.next_seq_PC <= IFID.next_seq_PC;
			
		end if;
	
	end process;
	
	---------------------------------------
	
	------------- CONTROLLER --------------
	
	-- TODO: implement unsigned operations, remove implicit zero extension control flag assignment
	controlReg(6) <= '0';
	
	CTRL_CL: process(IFID.instruction)
	begin
		-- these ifs might have been omitted if I would do the case statement based on the value of OPCODE || FUNCT
		-- however, doing it like this is safer, since by some fault illegal instructions might be loaded
		-- e.g. instructions having both OPCODE and FUNCT as non-zero values
		
		-- set-up for ALUoperation
		if ( conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) = 0 ) then		-- R type instruction
			case conv_integer(IFID.instruction(F_FUNCT_LEFT downto F_FUNCT_RIGHT)) is
				-- TODO: ch. code for unsigned operations?
				when 32 => controlReg(5 downto 0) <= "000000";			--	+
				when 34 => controlReg(5 downto 0) <= "000001";			-- -
				when 24 => controlReg(5 downto 0) <= "000010";			-- *
				when 26 => controlReg(5 downto 0) <= "000011";			-- /
				when 36 => controlReg(5 downto 0) <= "000100";			-- and
				when 37 => controlReg(5 downto 0) <= "000101";			-- or
				when 38 => controlReg(5 downto 0) <= "000110";			-- xor
				when 39 => controlReg(5 downto 0) <= "000111";			-- nor
				when 42 => controlReg(5 downto 0) <= "001000";			-- lt
				when 0 => controlReg(5 downto 0) <= "001001";			-- sll
				when 2 => controlReg(5 downto 0) <= "001010";			-- srl
				when others => controlReg(5 downto 0) <= "001011";	-- pass $s
			end case;
		else	-- I or J type instruction
			case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is
				when 8 | 23 | 43 | 4 | 5 | 2 | 35 => controlReg(5 downto 0) <= "000000";	-- +
				when 12 => controlReg(5 downto 0) <= "000100";										-- and
				when 13 => controlReg(5 downto 0) <= "000101";										-- or
				when 10 => controlReg(5 downto 0) <= "001000";										-- lt
				when others => controlReg(5 downto 0) <= "001011";									-- pass $s
			end case;
		end if;
		
		-- set-up for WBSelALU
		if ( conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) = 0 ) then		-- R type instruction
			case conv_integer(IFID.instruction(F_FUNCT_LEFT downto F_FUNCT_RIGHT)) is
				when 32 | 34 | 24 | 26 | 36 | 37 | 38 | 39 | 42 | 0 | 2 | 8 => controlReg(7) <= '1';	-- return ALU
				when others => controlReg(7) <= '0';																	-- return MEMORY
			end case;
		else	-- I or J type instruction
			case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is
				when 8 | 43 | 12 | 13 | 10 | 4 | 5 | 2 => controlReg(7) <= '1';				-- return ALU
				when others => controlReg(7) <= '0';													-- return MEMORY
			end case;
		end if;
		
		-- set-up for REGFILE_WE
		-- TODO: think about implementing multiplication/division result storage (special cases, excluded for now)
		if ( conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) = 0 ) then		-- R type instruction
			case conv_integer(IFID.instruction(F_FUNCT_LEFT downto F_FUNCT_RIGHT)) is
				when 32 | 34 | 36 | 37 | 38 | 39 | 42 | 0 | 2 => controlReg(8) <= '1';			-- allow write
				when others => controlReg(8) <= '0';														-- disallow write
			end case;
		else	-- I or J type instruction
			case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is
				when 8 | 23 | 0 | 12 | 13 | 10 | 35 => controlReg(8) <= '1';		-- allow write
				when others => controlReg(8) <= '0';										-- disallow write
			end case;
		end if;
		
		-- set-up for MEMORY_WE
		if ( conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) = 0 ) then		-- R type instruction
			controlReg(9) <= '0';																-- disallow write
		else	-- I or J type instruction
			case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is
				when 43 => controlReg(9) <= '1';												-- allow write
				when others => controlReg(9) <= '0';										-- disallow write
			end case;
		end if;
		
		-- set-up for beq
		if ( conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) = 4 ) then		-- beq I instruction
			controlReg(10) <= '1';
		else
			controlReg(10) <= '0';
		end if;
		
		-- set-up for bneq
		if ( conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) = 5 ) then		-- bneq I instruction
			controlReg(11) <= '1';
		else
			controlReg(11) <= '0';
		end if;
		
		-- set-up for jump
		if ( conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) = 0 ) then		-- R type instruction
			case conv_integer(IFID.instruction(F_FUNCT_LEFT downto F_FUNCT_RIGHT)) is
				when 8 => controlReg(12) <= '1';																-- jump
				when others => controlReg(12) <= '0';														-- don't! :))
			end case;
		else									-- I or J type instruction
			case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is
				when 2 => controlReg(12) <= '1';												-- jump
				when others => controlReg(12) <= '0';										-- don't :))
			end case;
		end if;
		
		-- set-up for isSourcePC
		case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is		-- I & J instructions
			when 4 | 5 | 2 => controlReg(13) <= '1';													-- is PC
			when others => controlReg(13) <= '0';														-- is Source register
		end case;
		
		-- set-up for isTargetImmediate
		case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is		-- I & J instructions
			when 8 | 12 | 13 | 10 | 4 | 5 | 2 | 35 | 43 => controlReg(14) <= '1';			-- is Immediate
			when others => controlReg(14) <= '0';														-- is Target register
		end case;
		
		-- set-up for isDestinationTarget (destination refers to REGFILE, during WB)
		case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is		-- I & J instructions
			when 8 | 23 | 12 | 13 | 10 | 35 => controlReg(15) <= '1';			-- address is Target register value
			when others => controlReg(15) <= '0';										-- address is Destination register value
		end case;
		
	end process;
	
	signExtend <= controlReg(6);
	isDestinationTarget <= controlReg(15);
	
	CTRL_SEQ: process(clk)
	begin
		if (rising_edge(clk)) then
			IDEX.ALUoperation <= controlReg(5 downto 0);
			IDEX.WBSelectALU <= controlReg(7);
			IDEX.REGFILE_WE <= controlReg(8);
			IDEX.MEMORY_WE <= controlReg(9);
			IDEX.beq <= controlReg(10);
			IDEX.bneq <= controlReg(11);
			IDEX.jump <= controlReg(12);
			IDEX.isSourcePC <= controlReg(13);
			IDEX.isTargetImmediate <= controlReg(14);
		end if;
	end process;
	
	
	---------------------------------------
	
	--------------- EXECUTE ---------------
	
	operatorSource <= IDEX.next_seq_PC when (IDEX.isSourcePC = '1') else IDEX.sourceValue;
	operatorTarget <= IDEX.immediateValue when (IDEX.isTargetImmediate = '1') else IDEX.targetValue;
	
	--shiftResult <= operatorSource * 2**conv_integer(operatorTarget(10 downto 6));
	--shiftResult <= operatorSource * 2**conv_integer(operatorTarget(10 downto 6));
	-- this doesn't seem to work - at least in simulation (nor the long listed version :|)
	shiftResult <= operatorSource(DATAPATH - 1 - conv_integer(operatorTarget(10 downto 6)) downto 0) 
							& zeroArray(conv_integer(operatorTarget(10 downto 6)) - 1 downto 0)
							when (IDEX.ALUoperation(3 downto 0) = "1001") else
						zeroArray(conv_integer(operatorTarget(10 downto 6)) - 1 downto 0)
							& operatorSource(DATAPATH - 1 downto conv_integer(operatorTarget(10 downto 6))) 
							when (IDEX.ALUoperation(3 downto 0) = "1010") else
						(others => '0');

--	shiftResultL <= 	operatorSource(DATAPATH - 1 downto 0) 
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 0 else
--							operatorSource(DATAPATH - 2 downto 0) & "0"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 1 else
--							operatorSource(DATAPATH - 3 downto 0) & "00"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 2 else
--							operatorSource(DATAPATH - 4 downto 0) & "000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 3 else
--							operatorSource(DATAPATH - 5 downto 0) & "0000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 4 else
--							operatorSource(DATAPATH - 6 downto 0) & "00000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 5 else
--							operatorSource(DATAPATH - 7 downto 0) & "000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 6 else
--							operatorSource(DATAPATH - 8 downto 0) & "0000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 7 else
--							operatorSource(DATAPATH - 9 downto 0) & "00000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 8 else
--							operatorSource(DATAPATH - 10 downto 0) & "000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 9 else
--							operatorSource(DATAPATH - 11 downto 0) & "0000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 10 else
--							operatorSource(DATAPATH - 12 downto 0) & "00000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 11 else
--							operatorSource(DATAPATH - 13 downto 0) & "000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 12 else
--							operatorSource(DATAPATH - 14 downto 0) & "0000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 13 else
--							operatorSource(DATAPATH - 15 downto 0) & "00000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 14 else
--							operatorSource(DATAPATH - 16 downto 0) & "000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 15 else
--							operatorSource(DATAPATH - 17 downto 0) & "0000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 16 else
--							operatorSource(DATAPATH - 18 downto 0) & "00000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 17 else
--							operatorSource(DATAPATH - 19 downto 0) & "000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 18 else
--							operatorSource(DATAPATH - 20 downto 0) & "0000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 19 else
--							operatorSource(DATAPATH - 21 downto 0) & "00000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 20 else
--							operatorSource(DATAPATH - 22 downto 0) & "000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 21 else
--							operatorSource(DATAPATH - 23 downto 0) & "0000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 22 else
--							operatorSource(DATAPATH - 24 downto 0) & "00000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 23 else
--							operatorSource(DATAPATH - 25 downto 0) & "000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 24 else
--							operatorSource(DATAPATH - 26 downto 0) & "0000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 25 else
--							operatorSource(DATAPATH - 27 downto 0) & "00000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 26 else
--							operatorSource(DATAPATH - 28 downto 0) & "000000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 27 else
--							operatorSource(DATAPATH - 29 downto 0) & "0000000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 28 else
--							operatorSource(DATAPATH - 30 downto 0) & "00000000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 29 else
--							operatorSource(DATAPATH - 31 downto 0) & "000000000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 30 else
--							operatorSource(DATAPATH - 32 downto 0) & "0000000000000000000000000000000"
--								when conv_integer(operatorTarget(F_SHAMT_LEFT - F_SHAMT_RIGHT)) = 31 else
--							(others => '0');
--							
--	shiftResultR <= (others => '0');				 
--
--	shiftResult <= shiftResultL when (IDEX.ALUoperation(3 downto 0) = "1001") else
--						shiftResultR when (IDEX.ALUoperation(3 downto 0) = "1010") else
--						(others => '0');
	
	lessThanResult <= zeroArray(DATAPATH - 2 downto 0) & "1" 
								when (operatorSource < operatorTarget) else 
							(others => '0');
	
	SEQ_EX: process(clk, reset)
	begin
	
		if (reset = '0') then
			EXMEM.next_seq_PC <= (others => '0');
		elsif ( rising_edge(clk) ) then
		
			case IDEX.ALUoperation(3 downto 0) is			
				when "0000" => EXMEM.ALUresult <= operatorSource + operatorTarget;
				when "0001" => EXMEM.ALUresult <= operatorSource - operatorTarget;
				when "0010" => EXMEM.ALUresult <= operatorSource + operatorTarget;	-- TODO: operator should be *
				when "0011" => EXMEM.ALUresult <= operatorSource + operatorTarget;	-- TODO: operator should be /
				when "0100" => EXMEM.ALUresult <= operatorSource and operatorTarget;
				when "0101" => EXMEM.ALUresult <= operatorSource or operatorTarget;
				when "0110" => EXMEM.ALUresult <= operatorSource xor operatorTarget;
				when "0111" => EXMEM.ALUresult <= operatorSource nor operatorTarget;
				when "1000" => EXMEM.ALUresult <= lessThanResult;
				when "1001" | "1010" => EXMEM.ALUresult <= shiftResult;
				when others => EXMEM.ALUresult <= operatorSource;
			end case;
		
			EXMEM.targetValue <= IDEX.targetValue;
			EXMEM.MEMORY_WE <= IDEX.MEMORY_WE;
			EXMEM.destinationRegAddress <= IDEX.destinationRegAddress;
			EXMEM.WBSelectALU <= IDEX.WBSelectALU;
			EXMEM.next_seq_PC <= IDEX.next_seq_PC;
			EXMEM.REGFILE_WE <= IDEX.REGFILE_WE;
			EXMEM.beq <= IDEX.beq;
			EXMEM.bneq <= IDEX.bneq;
			EXMEM.jump <= IDEX.jump;
			
			if ( conv_integer(IDEX.sourceValue - IDEX.targetValue) = 0 ) then
				EXMEM.differenceIsZero <= '1';
			else
				EXMEM.differenceIsZero <= '0';
			end if;
			
		end if;
	
	end process;
	
	---------------------------------------

	--------------- MEMORY ----------------
	
	SEQ_MEM: process(clk)
	begin
	
		if ( rising_edge(clk) ) then
										
			if ( EXMEM.MEMORY_WE = '1' ) then
				MEMORY(conv_integer(EXMEM.ALUresult(MEMORY_SEL - 1 downto 0))) <= EXMEM.targetValue;
				MEMWB.MEMresult <= EXMEM.targetValue;
			else
				MEMWB.MEMresult <= MEMORY(conv_integer(EXMEM.ALUresult(MEMORY_SEL - 1 downto 0)));
			end if;
			
			MEMWB.ALUresult <= EXMEM.ALUresult;
			MEMWB.destinationRegAddress <= EXMEM.destinationRegAddress;
			MEMWB.WBSelectALU <= EXMEM.WBSelectALU;
			MEMWB.REGFILE_WE <= EXMEM.REGFILE_WE;
			
		end if;
	
	end process;
	
	---------------------------------------
	
	------------- WRITE BACK --------------
	
	-- Multiplexing implemented in Instruction Decode section 
	
	---------------------------------------

end Behavioral;

