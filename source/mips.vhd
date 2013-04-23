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
		clk, reset : in std_logic
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
			MEMORY_addr : std_logic_vector(DATAPATH - 1 downto 0);
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

	constant INMEM : inmem_ram := (others => (others => '0'));
	signal REGFILE : regfile_ram;
	signal MEMORY : memory_ram;
	
	signal IFID : IF_ID_REG;
	signal IDEX : ID_EX_REG;
	signal EXMEM : EX_MEM_REG;
	signal MEMWB : MEM_WB_REG;
	
	----------- "TEMPORARY" SIGNALS (FF) -----------
	
	signal instruction, operatorSource, operatorTarget : std_logic_vector(DATAPATH - 1 downto 0);
	signal shiftResult, lessThanResult : std_logic_vector(DATAPATH - 1 downto 0);
	signal jumpOrBranchPC, PC, PC_in : std_logic_vector(DATAPATH - 1 downto 0);
	
	------------------------------------------------
	
	----------- CONTROL SIGNALS -----------
	
	signal signExtend, isDestinationTarget: std_logic;
	signal controlReg : std_logic_vector(15 downto 0);
	
	---------------------------------------
	
	--------------- HELPERS ---------------

	constant zeroArray : std_logic_vector(DATAPATH - 1 downto 0) := (others => '0');
	
	---------------------------------------

begin

	---------- INSTRUCTION FETCH ----------
	PC_in <= EXMEM.ALUresult when 
						(EXMEM.jump = '1' 
						or (EXMEM.beq = '1' and EXMEM.differenceIsZero = '1') 
						or (EXMEM.bneq = '1' and EXMEM.differenceIsZero = '0')) 
				else (PC + 1);
	
	SEQ_IF: process(clk, reset)
	begin
	
		if (reset = '1') then
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
	
	SEQ_ID: process(clk, reset, signExtend)
	begin
	
		if (reset = '1') then
			IDEX.next_seq_PC <= (others => '0');
		elsif ( rising_edge(clk) ) then
		
			if ( MEMWB.REGFILE_WE = '1' ) then
				if ( MEMWB.WBSelectALU = '1' ) then
					REGFILE(conv_integer(MEMWB.destinationRegAddress)) <= MEMWB.ALUresult;
				else
					REGFILE(conv_integer(MEMWB.destinationRegAddress)) <= MEMWB.MEMresult;
				end if;
			end if;
		
			IDEX.sourceValue <= REGFILE(conv_integer( IFID.instruction(F_RS_LEFT downto F_RS_RIGHT) ));
			IDEX.targetValue <= REGFILE(conv_integer( IFID.instruction(F_RT_LEFT downto F_RT_RIGHT) ));
			
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
				when 8 | 23 | 43 | 4 | 5 | 2 => controlReg(5 downto 0) <= "000000";			-- +
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
				when 8 | 23 | 0 | 12 | 13 | 10 => controlReg(8) <= '1';				-- allow write
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
			when 8 | 12 | 13 | 10 | 4 | 5 | 2 => controlReg(14) <= '1';			-- is Immediate
			when others => controlReg(14) <= '0';										-- is Target register
		end case;
		
		-- set-up for isDestinationTarget (destination refers to REGFILE, during WB)
		case conv_integer(IFID.instruction(F_OPCODE_LEFT downto F_OPCODE_RIGHT)) is		-- I & J instructions
			when 8 | 23 | 12 | 13 | 10 => controlReg(15) <= '1';			-- address is Target register value
			when others => controlReg(15) <= '0';								-- address is Destination register value
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
	shiftResult <= operatorSource(DATAPATH - 1 - conv_integer(operatorTarget(10 downto 6)) downto 0) 
							& zeroArray(conv_integer(operatorTarget(10 downto 6)) - 1 downto 0)
							when (IDEX.ALUoperation(3 downto 0) = "1001") else
						zeroArray(conv_integer(operatorTarget(10 downto 6)) - 1 downto 0)
							& operatorSource(DATAPATH - 1 downto conv_integer(operatorTarget(10 downto 6))) 
							when (IDEX.ALUoperation(3 downto 0) = "1010") else
						(others => '0');
	
	lessThanResult <= zeroArray(DATAPATH - 2 downto 0) & "1" 
								when (operatorSource < operatorTarget) else 
							(others => '0');
	
	SEQ_EX: process(clk, reset)
	begin
	
		if (reset = '1') then
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
		
			EXMEM.MEMORY_addr <= IDEX.targetValue;
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
				MEMORY(conv_integer(EXMEM.MEMORY_addr)) <= EXMEM.ALUresult;
				MEMWB.MEMresult <= EXMEM.ALUresult;
			else
				MEMWB.MEMresult <= MEMORY(conv_integer(EXMEM.MEMORY_addr));
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

