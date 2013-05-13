package assembler;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;

/**
 * 
 */

/**
 * @author Bogdan
 *
 */
public class BraveAss {
	
	private static enum OutputType {
		BINARY,
		VHDL
	}
	
	private static List<Instruction> program = new LinkedList<Instruction>();
	
	private static int BASE_ADDRESS = 0;
	
	private static HashMap<String, Integer> labelMap = new HashMap<String, Integer>();
	
	private static String COMM_DELIMITER = "#";
	private static String LABEL_DELIMITER = ":";
	private static String INSTRUCTION_COMPONENTS_DELIMITER = " ";
	
	private static HashMap<String, String> mnemonicMap = new HashMap<String, String>();
	private static HashMap<String, String> functionMap = new HashMap<String, String>();
	
	private static void initMnemonics(){
		mnemonicMap.put("NOP", "000000");
		mnemonicMap.put("ADDI", "001000");
		mnemonicMap.put("LW", "100011");
		mnemonicMap.put("SW", "101011");
		mnemonicMap.put("ANDI", "001100");
		mnemonicMap.put("ORI", "001101");
		mnemonicMap.put("SLTI", "001010");
		mnemonicMap.put("BEQ", "000100");
		mnemonicMap.put("BNEQ", "000101");
	}
	
	private static void initFunctions(){
		functionMap.put("ADD", "100000");
		functionMap.put("SUB", "100010");
		functionMap.put("AND", "100100");
		functionMap.put("OR", "100101");
		functionMap.put("XOR", "100110");
		functionMap.put("NOR", "100111");
		functionMap.put("SLT", "101010");
		functionMap.put("SLL", "000000");
		functionMap.put("SRL", "000010");
	}
	
	private static String parseLine(String line, int lineNumber){
		
		if (line == null || (line != null && (line.trim().equals("") || line.equals("\n")))){
			return "";
		}
		
		int position;
		
		position = line.indexOf(COMM_DELIMITER);
		line = line.substring(0, position == -1 ? line.length() : position ).trim();
		
		//System.out.println(line);
		
		position = line.indexOf(LABEL_DELIMITER);
		String label = null;
		if (position != -1) {
			label = line.substring(0, position).trim();
			line = line.substring(position+1, line.length()).trim();
		}
		
		Instruction instruction = new Instruction();
		instruction.lineNumber = lineNumber;
		instruction.label = label;
		labelMap.put(label, lineNumber);
		//System.out.println("Label.." + label + "..///.." + line);
		
		position = line.indexOf(INSTRUCTION_COMPONENTS_DELIMITER);
		String mnemonic = null;
		if ( position == -1 )
			mnemonic = "NOP";
		else {
			mnemonic = line.substring(0, position).trim();
			line = line.substring(position+1, line.length()).trim();
		}
		
		position = line.indexOf(INSTRUCTION_COMPONENTS_DELIMITER);
		String operator1 = null;
		if ( position != -1 ) {
			operator1 = line.substring(0, position).trim();
			line = line.substring(position+1, line.length()).trim();
		}
		
		position = line.indexOf(INSTRUCTION_COMPONENTS_DELIMITER);
		String operator2 = null;
		if ( position != -1 ) {
			operator2 = line.substring(0, position).trim();
			line = line.substring(position+1, line.length()).trim();
		}
		
		position = line.indexOf(INSTRUCTION_COMPONENTS_DELIMITER);
		String operator3 = null;
		if ( !line.trim().equals("") ) {
			operator3 = line.trim();
		}
		
		instruction.mnemonic = mnemonic;
		instruction.operator1 = operator1;
		instruction.operator2 = operator2;
		instruction.operator3 = operator3;
		
		program.add(instruction);
		
		return line;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		String filename;
		OutputType outputType;
		
		if (args.length == 0 || args[0].equals("")){
			filename = "test.asm";			
		} else {
			filename = args[0];
		}
		
		if (args.length == 0 || args[1].equals("")){
			outputType = OutputType.valueOf("vhdl".toUpperCase());			
		} else {
			outputType = OutputType.valueOf(args[1].toUpperCase());
		}
		
		initMnemonics();
		initFunctions();
		
		BufferedReader br;
		try {
			br = new BufferedReader(new FileReader(filename));
			String line;
			int lineNumber = 0;
			while ((line = br.readLine()) != null) {
			   parseLine(line, lineNumber);
			   lineNumber++;
			}
			br.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e){
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		try {
			File file = new File(filename + (outputType.equals(OutputType.VHDL) ? ".vhd" : ".hex"));
			if (!file.exists()) {
				file.createNewFile();
			}
	
			FileWriter fw = new FileWriter(file.getAbsoluteFile());
			BufferedWriter bw = new BufferedWriter(fw);
			
			bw.write("");
			
			for (Instruction instruction : program) {
				bw.write("'");
				if ( instruction.mnemonic == null || instruction.mnemonic.toLowerCase().equals("nop")){
					bw.write("00000000000000000000000000000000");
					continue;
				} else if ( mnemonicMap.get(instruction.mnemonic) != null ){
					bw.write( mnemonicMap.get(instruction.mnemonic) );
				} else {
					bw.write( mnemonicMap.get("NOP") );
				}
				bw.write(" ");
				if ( instruction.operator1 != null ) {
					bw.write( Integer.toBinaryString( Integer.parseInt(
								instruction.operator1.toLowerCase().replace("r", "") ) ) );
				}
				
				bw.write(" ");
				
				if ( instruction.operator2 != null ) {
					bw.write( Integer.toBinaryString( Integer.parseInt(
								instruction.operator2.toLowerCase().replace("r", "") ) ) );
				}
				
				bw.write("',\n");
			}
			
			bw.write("(others => '1'),\n");
			bw.write("others => (others => '0')");
			bw.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		System.out.println();
		for (Instruction instruction : program){
			
			System.out.print(instruction.lineNumber);
			System.out.print("\t\t\t");
			System.out.print(instruction.label == null ? "LAB_NIL" : instruction.label);
			System.out.print("\t\t\t");
			System.out.print(instruction.mnemonic == null ? "MNE_NIL" : instruction.mnemonic);
			System.out.print("\t\t\t");
			System.out.print(instruction.operator1 == null ? "OP1_NIL" : instruction.operator1);
			System.out.print("\t\t\t");
			System.out.print(instruction.operator2 == null ? "OP2_NIL" : instruction.operator2);
			System.out.print("\t\t\t");
			System.out.print(instruction.operator3 == null ? "OP3_NIL" : instruction.operator2);
			System.out.println();
		}
		
		
	}

}
