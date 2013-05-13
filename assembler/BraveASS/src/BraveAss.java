import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;

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
	
	private static void initFunction(){
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
		
		int position;
		
		position = line.indexOf(COMM_DELIMITER);
		line = line.substring(0, position == -1 ? line.length() : position ).trim();
		
		//System.out.println(line);
		
		position = line.indexOf(LABEL_DELIMITER);
		String label = line.substring(0, position == -1 ? 0 : position).trim();
		line = line.substring(position == -1 ? 0 : position+1, 
						position == -1 ? line.length() : line.length()).trim();
		labelMap.put(label, lineNumber);
		
		//System.out.println("Label.." + label + "..///.." + line);
		
		position = line.indexOf(INSTRUCTION_COMPONENTS_DELIMITER);
		String mnemonic = line.substring(0, position).trim();
		line = line.substring(position+1, line.length()).trim();
		
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
			outputType = OutputType.valueOf("binary".toUpperCase());			
		} else {
			outputType = OutputType.valueOf(args[1].toUpperCase());
		}
		
		
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
		
		
	}

}
