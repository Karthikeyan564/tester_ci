//////////////////////////////////////////////////////////////////////////////////
// Company: UofT - ISML
// Engineer: Motasem Ahmed Sakr
//
// Create Date: 06/13/2020 02:00:09 AM
// Design Name:
// Module Name: Mask Generation (MG)
// Project Name: T6D
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
// Cols is the important factor from Image Sensor Resolution as we generate the mask row by row. Rows number is not important.
// Supported Image Sensors
// Image Sensor Resolution: Cols x Rows
// T4/6: 320 x 320
// VGA : 640 x 480
// HD  : 1280 x 720
// FHD : 1920 x 1080


module mask_generation_VGA
(
	input clk,    						// Clock
	input clk_en, 						// Clock Enable
	input rst_n,  						// Asynchronous reset active low

	// Pattern Input passed through the micro-processor
	input [4:0] pattern_w, 				// size of the pattern W / "Repeated Pattern" width: 5 (XXX00) to 8 (XXX11)
	input pattern,						// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 1 in row n, ..., 31: pixel 31 in row n )
	input [7:0] repeatedPattern,		// pattern, to be repeated
	input load_pattern, 				// to load the pattern for repetition

	input [1:0] mask_type,				// Type of masks sliding right 00 - sliding left 01 - Random Mask 10 - repeated Pattern 11

	output logic [0:639] mg_mask,		// Mask Generated

	output logic rp_valid 				// Valid signal for the output
);

// Output register
logic valid_next;

// (LSB) 0 1 2 3 4 ..... 299(e.g.) (MSB)
logic [0:640-1] reg_curr;
logic [0:640-1] reg_next;

// Registers for Sliding Pattern
logic [0:31] pre_reg_curr;
logic [0:31] pre_reg_next;
logic [0:31] post_reg_curr;
logic [0:31] post_reg_next;
logic slide_bit;
logic feedback_bit;

// Registers for Pseudo Random Pattern
logic seedCounter;   					// counter for the random number across multiple columns based on the 640
logic seedLoaded;						// Signal will be asserted once all the seeds are loaded. 


// feedback bits used in random pattern generation
logic feedback_bit_random[0:19][0:31];
logic [0:639] reg_next_random;


// Repeated Pattern Registers
logic [639:0] c;						// Mask generated
logic [7:0] p;							// pattern, to be repeated

// Generate Feedback loop
genvar i;
generate

	for (i = 0; i < 20; i++)
	begin

		// My Random distribution
		assign feedback_bit_random[i][0]   = reg_curr[i+31] ^ reg_curr[i+21]  ^  reg_curr[i+1]   ^ reg_curr[i+0];
		assign feedback_bit_random[i][1]   = reg_curr[i+30] ^ reg_curr[i+20]  ^  reg_curr[i+0]   ^ reg_curr[i+16];
		assign feedback_bit_random[i][2]   = reg_curr[i+29] ^ reg_curr[i+19]  ^  reg_curr[i+2]   ^ reg_curr[i+15];
		assign feedback_bit_random[i][3]   = reg_curr[i+28] ^ reg_curr[i+18]  ^  reg_curr[i+3]   ^ reg_curr[i+14];
		assign feedback_bit_random[i][4]   = reg_curr[i+27] ^ reg_curr[i+17]  ^  reg_curr[i+4]   ^ reg_curr[i+13];
		assign feedback_bit_random[i][5]   = reg_curr[i+26] ^ reg_curr[i+16]  ^  reg_curr[i+5]   ^ reg_curr[i+12];
		assign feedback_bit_random[i][6]   = reg_curr[i+25] ^ reg_curr[i+15]  ^  reg_curr[i+6]   ^ reg_curr[i+11];
		assign feedback_bit_random[i][7]   = reg_curr[i+24] ^ reg_curr[i+14]  ^  reg_curr[i+7]   ^ reg_curr[i+10];
		assign feedback_bit_random[i][8]   = reg_curr[i+23] ^ reg_curr[i+13]  ^  reg_curr[i+8]   ^ reg_curr[i+1];
		assign feedback_bit_random[i][9]   = reg_curr[i+22] ^ reg_curr[i+12]  ^  reg_curr[i+9]   ^ reg_curr[i+2];
		assign feedback_bit_random[i][10]  = reg_curr[i+21] ^ reg_curr[i+11]  ^  reg_curr[i+20]  ^ reg_curr[i+3];
		assign feedback_bit_random[i][11]  = reg_curr[i+20] ^ reg_curr[i+10]  ^  reg_curr[i+21]  ^ reg_curr[i+4];
		assign feedback_bit_random[i][12]  = reg_curr[i+19] ^ reg_curr[i+9]   ^  reg_curr[i+22]  ^ reg_curr[i+5];
		assign feedback_bit_random[i][13]  = reg_curr[i+18] ^ reg_curr[i+8]   ^  reg_curr[i+23]  ^ reg_curr[i+6];
		assign feedback_bit_random[i][14]  = reg_curr[i+17] ^ reg_curr[i+7]   ^  reg_curr[i+24]  ^ reg_curr[i+30];
		assign feedback_bit_random[i][15]  = reg_curr[i+16] ^ reg_curr[i+6]   ^  reg_curr[i+25]  ^ reg_curr[i+29];
		assign feedback_bit_random[i][16]  = reg_curr[i+15] ^ reg_curr[i+5]   ^  reg_curr[i+26]  ^ reg_curr[i+28];
		assign feedback_bit_random[i][17]  = reg_curr[i+14] ^ reg_curr[i+4]   ^  reg_curr[i+27]  ^ reg_curr[i+27];
		assign feedback_bit_random[i][18]  = reg_curr[i+13] ^ reg_curr[i+3]   ^  reg_curr[i+31]  ^ reg_curr[i+26];
		assign feedback_bit_random[i][19]  = reg_curr[i+12] ^ reg_curr[i+2]   ^  reg_curr[i+29]  ^ reg_curr[i+25];
		assign feedback_bit_random[i][20]  = reg_curr[i+11] ^ reg_curr[i+1]   ^  reg_curr[i+30]  ^ reg_curr[i+24];
		assign feedback_bit_random[i][21]  = reg_curr[i+10] ^ reg_curr[i+0]   ^  reg_curr[i+10]  ^ reg_curr[i+23];
		assign feedback_bit_random[i][22]  = reg_curr[i+9]  ^ reg_curr[i+31]  ^  reg_curr[i+28]  ^ reg_curr[i+22];
		assign feedback_bit_random[i][23]  = reg_curr[i+8]  ^ reg_curr[i+30]  ^  reg_curr[i+11]  ^ reg_curr[i+21];
		assign feedback_bit_random[i][25]  = reg_curr[i+6]  ^ reg_curr[i+29]  ^  reg_curr[i+12]  ^ reg_curr[i+20];
		assign feedback_bit_random[i][26]  = reg_curr[i+5]  ^ reg_curr[i+28]  ^  reg_curr[i+13]  ^ reg_curr[i+19];
		assign feedback_bit_random[i][27]  = reg_curr[i+4]  ^ reg_curr[i+27]  ^  reg_curr[i+14]  ^ reg_curr[i+18];
		assign feedback_bit_random[i][24]  = reg_curr[i+7]  ^ reg_curr[i+26]  ^  reg_curr[i+15]  ^ reg_curr[i+17];
		assign feedback_bit_random[i][28]  = reg_curr[i+3]  ^ reg_curr[i+25]  ^  reg_curr[i+16]  ^ reg_curr[i+9];
		assign feedback_bit_random[i][29]  = reg_curr[i+2]  ^ reg_curr[i+24]  ^  reg_curr[i+17]  ^ reg_curr[i+8];
		assign feedback_bit_random[i][30]  = reg_curr[i+1]  ^ reg_curr[i+23]  ^  reg_curr[i+18]  ^ reg_curr[i+6];
		assign feedback_bit_random[i][31]  = reg_curr[i+0]  ^ reg_curr[i+22]  ^  reg_curr[i+19]  ^ reg_curr[i+7];


		assign reg_next_random[(i*32)+: 32] = {feedback_bit_random[i][0], feedback_bit_random[i][10], feedback_bit_random[i][4], feedback_bit_random[i][14], feedback_bit_random[i][6], feedback_bit_random[i][8], feedback_bit_random[i][16], feedback_bit_random[i][3], feedback_bit_random[i][29],
								feedback_bit_random[i][12], feedback_bit_random[i][22], feedback_bit_random[i][7], feedback_bit_random[i][11], feedback_bit_random[i][15], feedback_bit_random[i][5], feedback_bit_random[i][13], feedback_bit_random[i][1], feedback_bit_random[i][19],
								feedback_bit_random[i][17], feedback_bit_random[i][24], feedback_bit_random[i][20],feedback_bit_random[i][28], feedback_bit_random[i][29], feedback_bit_random[i][30], feedback_bit_random[i][23], feedback_bit_random[i][27], feedback_bit_random[i][26],
								feedback_bit_random[i][31], feedback_bit_random[i][18], feedback_bit_random[i][25], feedback_bit_random[i][22], feedback_bit_random[i][21]};				

		
	end
				
endgenerate


// Repeated Pattern Generation
assign w5 =	!pattern_w[1] && !pattern_w[0];			
assign w6 =	!pattern_w[1] &&  pattern_w[0];			
assign w7 =	 pattern_w[1] && !pattern_w[0];			
assign w8 =	 pattern_w[1] &&  pattern_w[0];			
				
assign c[0] = 	p[0]	;		
assign c[1] = 	p[1]	;		
assign c[2] = 	p[2]	;		
assign c[3] = 	p[3]	;		
assign c[4] = 	p[4]	;		
assign c[5] = 	(p[0]&&w5) || (p[5]&& !w5)	;		
assign c[6] = 	(p[0]&&w6) || (p[1]&&w5) || (p[6]&&(w7||w8))	;		
assign c[7] = 	(p[0]&&w7) || (p[1]&&w6) || (p[2]&&w5) || (p[7]&&w8)	;		
assign c[8] = 	(p[0]&&w8) || (p[1]&&w7) || (p[2]&&w6) || (p[3]&&w5)	;		
assign c[9] = 	(p[1]&&w8) || (p[2]&&w7) || (p[3]&&w6) || (p[4]&&w5)	;		
assign c[10] = 	(p[0]&&w5) || (p[2]&&w8) || (p[3]&&w7) || (p[4]&&w6)	;		
assign c[11] = 	(p[1]&&w5) || (p[3]&&w8) || (p[4]&&w7) || (p[5]&&w6)	;		
assign c[12] = 	(p[0]&&w6) || (p[2]&&w5) || (p[4]&&w8) || (p[5]&&w7)	;		
assign c[13] = 	(p[1]&&w6) || (p[3]&&w5) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[14] = 	(p[0]&&w7) || (p[2]&&w6) || (p[4]&&w5) || (p[6]&&w8)	;		
assign c[15] = 	(p[0]&&w5) || (p[1]&&w7) || (p[3]&&w6) || (p[7]&&w8)	;		
assign c[16] = 	(p[0]&&w8) || (p[1]&&w5) || (p[2]&&w7) || (p[4]&&w6)	;		
assign c[17] = 	(p[1]&&w8) || (p[2]&&w5) || (p[3]&&w7) || (p[5]&&w6)	;		
assign c[18] = 	(p[0]&&w6) || (p[2]&&w8) || (p[3]&&w5) || (p[4]&&w7)	;		
assign c[19] = 	(p[1]&&w6) || (p[3]&&w8) || (p[4]&&w5) || (p[5]&&w7)	;		
assign c[20] = 	(p[0]&&w5) || (p[2]&&w6) || (p[4]&&w8) || (p[6]&&w7)	;		
assign c[21] = 	(p[0]&&w7) || (p[1]&&w5) || (p[3]&&w6) || (p[5]&&w8)	;		
assign c[22] = 	(p[1]&&w7) || (p[2]&&w5) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[23] = 	(p[2]&&w7) || (p[3]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[24] = 	(p[0]&&(w6||w8)) || (p[3]&&w7) || (p[4]&&w5)	;		
assign c[25] = 	(p[0]&&w5) || (p[1]&&(w6||w8)) || (p[4]&&w7)	;		
assign c[26] = 	(p[1]&&w5) || (p[2]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[27] = 	(p[2]&&w5) || (p[3]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[28] = 	(p[0]&&w7) || (p[3]&&w5) || (p[4]&&(w6||w8))	;		
assign c[29] = 	(p[1]&&w7) || (p[4]&&w5) || (p[5]&&(w6||w8))	;		
assign c[30] = 	(p[0]&&(w5||w6)) || (p[2]&&w7) || (p[6]&&w8)	;		
assign c[31] = 	(p[1]&&(w5||w6)) || (p[3]&&w7) || (p[7]&&w8)	;		
assign c[32] = 	(p[0]&&w8) || (p[2]&&(w5||w6)) || (p[4]&&w7)	;		
assign c[33] = 	(p[1]&&w8) || (p[3]&&(w5||w6)) || (p[5]&&w7)	;		
assign c[34] = 	(p[2]&&w8) || (p[4]&&(w5||w6)) || (p[6]&&w7)	;		
assign c[35] = 	(p[0]&&(w5||w7)) || (p[3]&&w8) || (p[5]&&w6)	;		
assign c[36] = 	(p[0]&&w6) || (p[1]&&(w5||w7)) || (p[4]&&w8)	;		
assign c[37] = 	(p[1]&&w6) || (p[2]&&(w5||w7)) || (p[5]&&w8)	;		
assign c[38] = 	(p[2]&&w6) || (p[3]&&(w5||w7)) || (p[6]&&w8)	;		
assign c[39] = 	(p[3]&&w6) || (p[4]&&(w5||w7)) || (p[7]&&w8)	;		
assign c[40] = 	(p[0]&&(w5||w8)) || (p[4]&&w6) || (p[5]&&w7)	;		
assign c[41] = 	(p[1]&&(w5||w8)) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[42] = 	(p[0]&&(w6||w7)) || (p[2]&&(w5||w8))	;		
assign c[43] = 	(p[1]&&(w6||w7)) || (p[3]&&(w5||w8))	;		
assign c[44] = 	(p[2]&&(w6||w7)) || (p[4]&&(w5||w8))	;		
assign c[45] = 	(p[0]&&w5) || (p[3]&&(w6||w7)) || (p[5]&&w8)	;		
assign c[46] = 	(p[1]&&w5) || (p[4]&&(w6||w7)) || (p[6]&&w8)	;		
assign c[47] = 	(p[2]&&w5) || (p[5]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[48] = 	(p[0]&&(w6||w8)) || (p[3]&&w5) || (p[6]&&w7)	;		
assign c[49] = 	(p[0]&&w7) || (p[1]&&(w6||w8)) || (p[4]&&w5)	;		
assign c[50] = 	(p[0]&&w5) || (p[1]&&w7) || (p[2]&&(w6||w8))	;		
assign c[51] = 	(p[1]&&w5) || (p[2]&&w7) || (p[3]&&(w6||w8))	;		
assign c[52] = 	(p[2]&&w5) || (p[3]&&w7) || (p[4]&&(w6||w8))	;		
assign c[53] = 	(p[3]&&w5) || (p[4]&&w7) || (p[5]&&(w6||w8))	;		
assign c[54] = 	(p[0]&&w6) || (p[4]&&w5) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[55] = 	(p[0]&&w5) || (p[1]&&w6) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[56] = 	(p[0]&&(w7||w8)) || (p[1]&&w5) || (p[2]&&w6)	;		
assign c[57] = 	(p[1]&&(w7||w8)) || (p[2]&&w5) || (p[3]&&w6)	;		
assign c[58] = 	(p[2]&&(w7||w8)) || (p[3]&&w5) || (p[4]&&w6)	;		
assign c[59] = 	(p[3]&&(w7||w8)) || (p[4]&&w5) || (p[5]&&w6)	;		
assign c[60] = 	(p[0]&&(w5||w6)) || (p[4]&&(w7||w8))	;		
assign c[61] = 	(p[1]&&(w5||w6)) || (p[5]&&(w7||w8))	;		
assign c[62] = 	(p[2]&&(w5||w6)) || (p[6]&&(w7||w8))	;		
assign c[63] = 	(p[0]&&w7) || (p[3]&&(w5||w6)) || (p[7]&&w8)	;		
assign c[64] = 	(p[0]&&w8) || (p[1]&&w7) || (p[4]&&(w5||w6))	;		
assign c[65] = 	(p[0]&&w5) || (p[1]&&w8) || (p[2]&&w7) || (p[5]&&w6)	;		
assign c[66] = 	(p[0]&&w6) || (p[1]&&w5) || (p[2]&&w8) || (p[3]&&w7)	;		
assign c[67] = 	(p[1]&&w6) || (p[2]&&w5) || (p[3]&&w8) || (p[4]&&w7)	;		
assign c[68] = 	(p[2]&&w6) || (p[3]&&w5) || (p[4]&&w8) || (p[5]&&w7)	;		
assign c[69] = 	(p[3]&&w6) || (p[4]&&w5) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[70] = 	(p[0]&&(w5||w7)) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[71] = 	(p[1]&&(w5||w7)) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[72] = 	(p[0]&&(w6||w8)) || (p[2]&&(w5||w7))	;		
assign c[73] = 	(p[1]&&(w6||w8)) || (p[3]&&(w5||w7))	;		
assign c[74] = 	(p[2]&&(w6||w8)) || (p[4]&&(w5||w7))	;		
assign c[75] = 	(p[0]&&w5) || (p[3]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[76] = 	(p[1]&&w5) || (p[4]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[77] = 	(p[0]&&w7) || (p[2]&&w5) || (p[5]&&(w6||w8))	;		
assign c[78] = 	(p[0]&&w6) || (p[1]&&w7) || (p[3]&&w5) || (p[6]&&w8)	;		
assign c[79] = 	(p[1]&&w6) || (p[2]&&w7) || (p[4]&&w5) || (p[7]&&w8)	;		
assign c[80] = 	(p[0]&&(w5||w8)) || (p[2]&&w6) || (p[3]&&w7)	;		
assign c[81] = 	(p[1]&&(w5||w8)) || (p[3]&&w6) || (p[4]&&w7)	;		
assign c[82] = 	(p[2]&&(w5||w8)) || (p[4]&&w6) || (p[5]&&w7)	;		
assign c[83] = 	(p[3]&&(w5||w8)) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[84] = 	(p[0]&&(w6||w7)) || (p[4]&&(w5||w8))	;		
assign c[85] = 	(p[0]&&w5) || (p[1]&&(w6||w7)) || (p[5]&&w8)	;		
assign c[86] = 	(p[1]&&w5) || (p[2]&&(w6||w7)) || (p[6]&&w8)	;		
assign c[87] = 	(p[2]&&w5) || (p[3]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[88] = 	(p[0]&&w8) || (p[3]&&w5) || (p[4]&&(w6||w7))	;		
assign c[89] = 	(p[1]&&w8) || (p[4]&&w5) || (p[5]&&(w6||w7))	;		
assign c[90] = 	(p[0]&&(w5||w6)) || (p[2]&&w8) || (p[6]&&w7)	;		
assign c[91] = 	(p[0]&&w7) || (p[1]&&(w5||w6)) || (p[3]&&w8)	;		
assign c[92] = 	(p[1]&&w7) || (p[2]&&(w5||w6)) || (p[4]&&w8)	;		
assign c[93] = 	(p[2]&&w7) || (p[3]&&(w5||w6)) || (p[5]&&w8)	;		
assign c[94] = 	(p[3]&&w7) || (p[4]&&(w5||w6)) || (p[6]&&w8)	;		
assign c[95] = 	(p[0]&&w5) || (p[4]&&w7) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[96] = 	(p[0]&&(w6||w8)) || (p[1]&&w5) || (p[5]&&w7)	;		
assign c[97] = 	(p[1]&&(w6||w8)) || (p[2]&&w5) || (p[6]&&w7)	;		
assign c[98] = 	(p[0]&&w7) || (p[2]&&(w6||w8)) || (p[3]&&w5)	;		
assign c[99] = 	(p[1]&&w7) || (p[3]&&(w6||w8)) || (p[4]&&w5)	;		
assign c[100] = 	(p[0]&&w5) || (p[2]&&w7) || (p[4]&&(w6||w8))	;		
assign c[101] = 	(p[1]&&w5) || (p[3]&&w7) || (p[5]&&(w6||w8))	;		
assign c[102] = 	(p[0]&&w6) || (p[2]&&w5) || (p[4]&&w7) || (p[6]&&w8)	;		
assign c[103] = 	(p[1]&&w6) || (p[3]&&w5) || (p[5]&&w7) || (p[7]&&w8)	;		
assign c[104] = 	(p[0]&&w8) || (p[2]&&w6) || (p[4]&&w5) || (p[6]&&w7)	;		
assign c[105] = 	(p[0]&&(w5||w7)) || (p[1]&&w8) || (p[3]&&w6)	;		
assign c[106] = 	(p[1]&&(w5||w7)) || (p[2]&&w8) || (p[4]&&w6)	;		
assign c[107] = 	(p[2]&&(w5||w7)) || (p[3]&&w8) || (p[5]&&w6)	;		
assign c[108] = 	(p[0]&&w6) || (p[3]&&(w5||w7)) || (p[4]&&w8)	;		
assign c[109] = 	(p[1]&&w6) || (p[4]&&(w5||w7)) || (p[5]&&w8)	;		
assign c[110] = 	(p[0]&&w5) || (p[2]&&w6) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[111] = 	(p[1]&&w5) || (p[3]&&w6) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[112] = 	(p[0]&&(w7||w8)) || (p[2]&&w5) || (p[4]&&w6)	;		
assign c[113] = 	(p[1]&&(w7||w8)) || (p[3]&&w5) || (p[5]&&w6)	;		
assign c[114] = 	(p[0]&&w6) || (p[2]&&(w7||w8)) || (p[4]&&w5)	;		
assign c[115] = 	(p[0]&&w5) || (p[1]&&w6) || (p[3]&&(w7||w8))	;		
assign c[116] = 	(p[1]&&w5) || (p[2]&&w6) || (p[4]&&(w7||w8))	;		
assign c[117] = 	(p[2]&&w5) || (p[3]&&w6) || (p[5]&&(w7||w8))	;		
assign c[118] = 	(p[3]&&w5) || (p[4]&&w6) || (p[6]&&(w7||w8))	;		
assign c[119] = 	(p[0]&&w7) || (p[4]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[120] = 	(p[0]&& !w7) || (p[1]&&w7)	;		
assign c[121] = 	(p[1]&& !w7) || (p[2]&&w7)	;		
assign c[122] = 	(p[2]&& !w7) || (p[3]&&w7)	;		
assign c[123] = 	(p[3]&& !w7) || (p[4]&&w7)	;		
assign c[124] = 	(p[4]&& !w7) || (p[5]&&w7)	;		
assign c[125] = 	(p[0]&&w5) || (p[5]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[126] = 	(p[0]&&(w6||w7)) || (p[1]&&w5) || (p[6]&&w8)	;		
assign c[127] = 	(p[1]&&(w6||w7)) || (p[2]&&w5) || (p[7]&&w8)	;		
assign c[128] = 	(p[0]&&w8) || (p[2]&&(w6||w7)) || (p[3]&&w5)	;		
assign c[129] = 	(p[1]&&w8) || (p[3]&&(w6||w7)) || (p[4]&&w5)	;		
assign c[130] = 	(p[0]&&w5) || (p[2]&&w8) || (p[4]&&(w6||w7))	;		
assign c[131] = 	(p[1]&&w5) || (p[3]&&w8) || (p[5]&&(w6||w7))	;		
assign c[132] = 	(p[0]&&w6) || (p[2]&&w5) || (p[4]&&w8) || (p[6]&&w7)	;		
assign c[133] = 	(p[0]&&w7) || (p[1]&&w6) || (p[3]&&w5) || (p[5]&&w8)	;		
assign c[134] = 	(p[1]&&w7) || (p[2]&&w6) || (p[4]&&w5) || (p[6]&&w8)	;		
assign c[135] = 	(p[0]&&w5) || (p[2]&&w7) || (p[3]&&w6) || (p[7]&&w8)	;		
assign c[136] = 	(p[0]&&w8) || (p[1]&&w5) || (p[3]&&w7) || (p[4]&&w6)	;		
assign c[137] = 	(p[1]&&w8) || (p[2]&&w5) || (p[4]&&w7) || (p[5]&&w6)	;		
assign c[138] = 	(p[0]&&w6) || (p[2]&&w8) || (p[3]&&w5) || (p[5]&&w7)	;		
assign c[139] = 	(p[1]&&w6) || (p[3]&&w8) || (p[4]&&w5) || (p[6]&&w7)	;		
assign c[140] = 	(p[0]&&(w5||w7)) || (p[2]&&w6) || (p[4]&&w8)	;		
assign c[141] = 	(p[1]&&(w5||w7)) || (p[3]&&w6) || (p[5]&&w8)	;		
assign c[142] = 	(p[2]&&(w5||w7)) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[143] = 	(p[3]&&(w5||w7)) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[144] = 	(p[0]&&(w6||w8)) || (p[4]&&(w5||w7))	;		
assign c[145] = 	(p[0]&&w5) || (p[1]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[146] = 	(p[1]&&w5) || (p[2]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[147] = 	(p[0]&&w7) || (p[2]&&w5) || (p[3]&&(w6||w8))	;		
assign c[148] = 	(p[1]&&w7) || (p[3]&&w5) || (p[4]&&(w6||w8))	;		
assign c[149] = 	(p[2]&&w7) || (p[4]&&w5) || (p[5]&&(w6||w8))	;		
assign c[150] = 	(p[0]&&(w5||w6)) || (p[3]&&w7) || (p[6]&&w8)	;		
assign c[151] = 	(p[1]&&(w5||w6)) || (p[4]&&w7) || (p[7]&&w8)	;		
assign c[152] = 	(p[0]&&w8) || (p[2]&&(w5||w6)) || (p[5]&&w7)	;		
assign c[153] = 	(p[1]&&w8) || (p[3]&&(w5||w6)) || (p[6]&&w7)	;		
assign c[154] = 	(p[0]&&w7) || (p[2]&&w8) || (p[4]&&(w5||w6))	;		
assign c[155] = 	(p[0]&&w5) || (p[1]&&w7) || (p[3]&&w8) || (p[5]&&w6)	;		
assign c[156] = 	(p[0]&&w6) || (p[1]&&w5) || (p[2]&&w7) || (p[4]&&w8)	;		
assign c[157] = 	(p[1]&&w6) || (p[2]&&w5) || (p[3]&&w7) || (p[5]&&w8)	;		
assign c[158] = 	(p[2]&&w6) || (p[3]&&w5) || (p[4]&&w7) || (p[6]&&w8)	;		
assign c[159] = 	(p[3]&&w6) || (p[4]&&w5) || (p[5]&&w7) || (p[7]&&w8)	;		
assign c[160] = 	(p[0]&&(w5||w8)) || (p[4]&&w6) || (p[6]&&w7)	;		
assign c[161] = 	(p[0]&&w7) || (p[1]&&(w5||w8)) || (p[5]&&w6)	;		
assign c[162] = 	(p[0]&&w6) || (p[1]&&w7) || (p[2]&&(w5||w8))	;		
assign c[163] = 	(p[1]&&w6) || (p[2]&&w7) || (p[3]&&(w5||w8))	;		
assign c[164] = 	(p[2]&&w6) || (p[3]&&w7) || (p[4]&&(w5||w8))	;		
assign c[165] = 	(p[0]&&w5) || (p[3]&&w6) || (p[4]&&w7) || (p[5]&&w8)	;		
assign c[166] = 	(p[1]&&w5) || (p[4]&&w6) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[167] = 	(p[2]&&w5) || (p[5]&&w6) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[168] = 	(p[0]&& !w5) || (p[3]&&w5)	;		
assign c[169] = 	(p[1]&& !w5) || (p[4]&&w5)	;		
assign c[170] = 	(p[0]&&w5) || (p[2]&& !w5)	;		
assign c[171] = 	(p[1]&&w5) || (p[3]&& !w5)	;		
assign c[172] = 	(p[2]&&w5) || (p[4]&& !w5)	;		
assign c[173] = 	(p[3]&&w5) || (p[5]&& !w5)	;		
assign c[174] = 	(p[0]&&w6) || (p[4]&&w5) || (p[6]&&(w7||w8))	;		
assign c[175] = 	(p[0]&&(w5||w7)) || (p[1]&&w6) || (p[7]&&w8)	;		
assign c[176] = 	(p[0]&&w8) || (p[1]&&(w5||w7)) || (p[2]&&w6)	;		
assign c[177] = 	(p[1]&&w8) || (p[2]&&(w5||w7)) || (p[3]&&w6)	;		
assign c[178] = 	(p[2]&&w8) || (p[3]&&(w5||w7)) || (p[4]&&w6)	;		
assign c[179] = 	(p[3]&&w8) || (p[4]&&(w5||w7)) || (p[5]&&w6)	;		
assign c[180] = 	(p[0]&&(w5||w6)) || (p[4]&&w8) || (p[5]&&w7)	;		
assign c[181] = 	(p[1]&&(w5||w6)) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[182] = 	(p[0]&&w7) || (p[2]&&(w5||w6)) || (p[6]&&w8)	;		
assign c[183] = 	(p[1]&&w7) || (p[3]&&(w5||w6)) || (p[7]&&w8)	;		
assign c[184] = 	(p[0]&&w8) || (p[2]&&w7) || (p[4]&&(w5||w6))	;		
assign c[185] = 	(p[0]&&w5) || (p[1]&&w8) || (p[3]&&w7) || (p[5]&&w6)	;		
assign c[186] = 	(p[0]&&w6) || (p[1]&&w5) || (p[2]&&w8) || (p[4]&&w7)	;		
assign c[187] = 	(p[1]&&w6) || (p[2]&&w5) || (p[3]&&w8) || (p[5]&&w7)	;		
assign c[188] = 	(p[2]&&w6) || (p[3]&&w5) || (p[4]&&w8) || (p[6]&&w7)	;		
assign c[189] = 	(p[0]&&w7) || (p[3]&&w6) || (p[4]&&w5) || (p[5]&&w8)	;		
assign c[190] = 	(p[0]&&w5) || (p[1]&&w7) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[191] = 	(p[1]&&w5) || (p[2]&&w7) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[192] = 	(p[0]&&(w6||w8)) || (p[2]&&w5) || (p[3]&&w7)	;		
assign c[193] = 	(p[1]&&(w6||w8)) || (p[3]&&w5) || (p[4]&&w7)	;		
assign c[194] = 	(p[2]&&(w6||w8)) || (p[4]&&w5) || (p[5]&&w7)	;		
assign c[195] = 	(p[0]&&w5) || (p[3]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[196] = 	(p[0]&&w7) || (p[1]&&w5) || (p[4]&&(w6||w8))	;		
assign c[197] = 	(p[1]&&w7) || (p[2]&&w5) || (p[5]&&(w6||w8))	;		
assign c[198] = 	(p[0]&&w6) || (p[2]&&w7) || (p[3]&&w5) || (p[6]&&w8)	;		
assign c[199] = 	(p[1]&&w6) || (p[3]&&w7) || (p[4]&&w5) || (p[7]&&w8)	;		
assign c[200] = 	(p[0]&&(w5||w8)) || (p[2]&&w6) || (p[4]&&w7)	;		
assign c[201] = 	(p[1]&&(w5||w8)) || (p[3]&&w6) || (p[5]&&w7)	;		
assign c[202] = 	(p[2]&&(w5||w8)) || (p[4]&&w6) || (p[6]&&w7)	;		
assign c[203] = 	(p[0]&&w7) || (p[3]&&(w5||w8)) || (p[5]&&w6)	;		
assign c[204] = 	(p[0]&&w6) || (p[1]&&w7) || (p[4]&&(w5||w8))	;		
assign c[205] = 	(p[0]&&w5) || (p[1]&&w6) || (p[2]&&w7) || (p[5]&&w8)	;		
assign c[206] = 	(p[1]&&w5) || (p[2]&&w6) || (p[3]&&w7) || (p[6]&&w8)	;		
assign c[207] = 	(p[2]&&w5) || (p[3]&&w6) || (p[4]&&w7) || (p[7]&&w8)	;		
assign c[208] = 	(p[0]&&w8) || (p[3]&&w5) || (p[4]&&w6) || (p[5]&&w7)	;		
assign c[209] = 	(p[1]&&w8) || (p[4]&&w5) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[210] = 	(p[0]&& !w8) || (p[2]&&w8)	;		
assign c[211] = 	(p[1]&& !w8) || (p[3]&&w8)	;		
assign c[212] = 	(p[2]&& !w8) || (p[4]&&w8)	;		
assign c[213] = 	(p[3]&& !w8) || (p[5]&&w8)	;		
assign c[214] = 	(p[4]&& !w8) || (p[6]&&w8)	;		
assign c[215] = 	(p[0]&&w5) || (p[5]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[216] = 	(p[0]&&(w6||w8)) || (p[1]&&w5) || (p[6]&&w7)	;		
assign c[217] = 	(p[0]&&w7) || (p[1]&&(w6||w8)) || (p[2]&&w5)	;		
assign c[218] = 	(p[1]&&w7) || (p[2]&&(w6||w8)) || (p[3]&&w5)	;		
assign c[219] = 	(p[2]&&w7) || (p[3]&&(w6||w8)) || (p[4]&&w5)	;		
assign c[220] = 	(p[0]&&w5) || (p[3]&&w7) || (p[4]&&(w6||w8))	;		
assign c[221] = 	(p[1]&&w5) || (p[4]&&w7) || (p[5]&&(w6||w8))	;		
assign c[222] = 	(p[0]&&w6) || (p[2]&&w5) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[223] = 	(p[1]&&w6) || (p[3]&&w5) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[224] = 	(p[0]&&(w7||w8)) || (p[2]&&w6) || (p[4]&&w5)	;		
assign c[225] = 	(p[0]&&w5) || (p[1]&&(w7||w8)) || (p[3]&&w6)	;		
assign c[226] = 	(p[1]&&w5) || (p[2]&&(w7||w8)) || (p[4]&&w6)	;		
assign c[227] = 	(p[2]&&w5) || (p[3]&&(w7||w8)) || (p[5]&&w6)	;		
assign c[228] = 	(p[0]&&w6) || (p[3]&&w5) || (p[4]&&(w7||w8))	;		
assign c[229] = 	(p[1]&&w6) || (p[4]&&w5) || (p[5]&&(w7||w8))	;		
assign c[230] = 	(p[0]&&w5) || (p[2]&&w6) || (p[6]&&(w7||w8))	;		
assign c[231] = 	(p[0]&&w7) || (p[1]&&w5) || (p[3]&&w6) || (p[7]&&w8)	;		
assign c[232] = 	(p[0]&&w8) || (p[1]&&w7) || (p[2]&&w5) || (p[4]&&w6)	;		
assign c[233] = 	(p[1]&&w8) || (p[2]&&w7) || (p[3]&&w5) || (p[5]&&w6)	;		
assign c[234] = 	(p[0]&&w6) || (p[2]&&w8) || (p[3]&&w7) || (p[4]&&w5)	;		
assign c[235] = 	(p[0]&&w5) || (p[1]&&w6) || (p[3]&&w8) || (p[4]&&w7)	;		
assign c[236] = 	(p[1]&&w5) || (p[2]&&w6) || (p[4]&&w8) || (p[5]&&w7)	;		
assign c[237] = 	(p[2]&&w5) || (p[3]&&w6) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[238] = 	(p[0]&&w7) || (p[3]&&w5) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[239] = 	(p[1]&&w7) || (p[4]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[240] = 	(p[0]&& !w7) || (p[2]&&w7)	;		
assign c[241] = 	(p[1]&& !w7) || (p[3]&&w7)	;		
assign c[242] = 	(p[2]&& !w7) || (p[4]&&w7)	;		
assign c[243] = 	(p[3]&& !w7) || (p[5]&&w7)	;		
assign c[244] = 	(p[4]&& !w7) || (p[6]&&w7)	;		
assign c[245] = 	(p[0]&&(w5||w7)) || (p[5]&&(w6||w8))	;		
assign c[246] = 	(p[0]&&w6) || (p[1]&&(w5||w7)) || (p[6]&&w8)	;		
assign c[247] = 	(p[1]&&w6) || (p[2]&&(w5||w7)) || (p[7]&&w8)	;		
assign c[248] = 	(p[0]&&w8) || (p[2]&&w6) || (p[3]&&(w5||w7))	;		
assign c[249] = 	(p[1]&&w8) || (p[3]&&w6) || (p[4]&&(w5||w7))	;		
assign c[250] = 	(p[0]&&w5) || (p[2]&&w8) || (p[4]&&w6) || (p[5]&&w7)	;		
assign c[251] = 	(p[1]&&w5) || (p[3]&&w8) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[252] = 	(p[0]&&(w6||w7)) || (p[2]&&w5) || (p[4]&&w8)	;		
assign c[253] = 	(p[1]&&(w6||w7)) || (p[3]&&w5) || (p[5]&&w8)	;		
assign c[254] = 	(p[2]&&(w6||w7)) || (p[4]&&w5) || (p[6]&&w8)	;		
assign c[255] = 	(p[0]&&w5) || (p[3]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[256] = 	(p[0]&&w8) || (p[1]&&w5) || (p[4]&&(w6||w7))	;		
assign c[257] = 	(p[1]&&w8) || (p[2]&&w5) || (p[5]&&(w6||w7))	;		
assign c[258] = 	(p[0]&&w6) || (p[2]&&w8) || (p[3]&&w5) || (p[6]&&w7)	;		
assign c[259] = 	(p[0]&&w7) || (p[1]&&w6) || (p[3]&&w8) || (p[4]&&w5)	;		
assign c[260] = 	(p[0]&&w5) || (p[1]&&w7) || (p[2]&&w6) || (p[4]&&w8)	;		
assign c[261] = 	(p[1]&&w5) || (p[2]&&w7) || (p[3]&&w6) || (p[5]&&w8)	;		
assign c[262] = 	(p[2]&&w5) || (p[3]&&w7) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[263] = 	(p[3]&&w5) || (p[4]&&w7) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[264] = 	(p[0]&&(w6||w8)) || (p[4]&&w5) || (p[5]&&w7)	;		
assign c[265] = 	(p[0]&&w5) || (p[1]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[266] = 	(p[0]&&w7) || (p[1]&&w5) || (p[2]&&(w6||w8))	;		
assign c[267] = 	(p[1]&&w7) || (p[2]&&w5) || (p[3]&&(w6||w8))	;		
assign c[268] = 	(p[2]&&w7) || (p[3]&&w5) || (p[4]&&(w6||w8))	;		
assign c[269] = 	(p[3]&&w7) || (p[4]&&w5) || (p[5]&&(w6||w8))	;		
assign c[270] = 	(p[0]&&(w5||w6)) || (p[4]&&w7) || (p[6]&&w8)	;		
assign c[271] = 	(p[1]&&(w5||w6)) || (p[5]&&w7) || (p[7]&&w8)	;		
assign c[272] = 	(p[0]&&w8) || (p[2]&&(w5||w6)) || (p[6]&&w7)	;		
assign c[273] = 	(p[0]&&w7) || (p[1]&&w8) || (p[3]&&(w5||w6))	;		
assign c[274] = 	(p[1]&&w7) || (p[2]&&w8) || (p[4]&&(w5||w6))	;		
assign c[275] = 	(p[0]&&w5) || (p[2]&&w7) || (p[3]&&w8) || (p[5]&&w6)	;		
assign c[276] = 	(p[0]&&w6) || (p[1]&&w5) || (p[3]&&w7) || (p[4]&&w8)	;		
assign c[277] = 	(p[1]&&w6) || (p[2]&&w5) || (p[4]&&w7) || (p[5]&&w8)	;		
assign c[278] = 	(p[2]&&w6) || (p[3]&&w5) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[279] = 	(p[3]&&w6) || (p[4]&&w5) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[280] = 	(p[0]&& !w6) || (p[4]&&w6)	;		
assign c[281] = 	(p[1]&& !w6) || (p[5]&&w6)	;		
assign c[282] = 	(p[0]&&w6) || (p[2]&& !w6)	;		
assign c[283] = 	(p[1]&&w6) || (p[3]&& !w6)	;		
assign c[284] = 	(p[2]&&w6) || (p[4]&& !w6)	;		
assign c[285] = 	(p[0]&&w5) || (p[3]&&w6) || (p[5]&&(w7||w8))	;		
assign c[286] = 	(p[1]&&w5) || (p[4]&&w6) || (p[6]&&(w7||w8))	;		
assign c[287] = 	(p[0]&&w7) || (p[2]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[288] = 	(p[0]&&(w6||w8)) || (p[1]&&w7) || (p[3]&&w5)	;		
assign c[289] = 	(p[1]&&(w6||w8)) || (p[2]&&w7) || (p[4]&&w5)	;		
assign c[290] = 	(p[0]&&w5) || (p[2]&&(w6||w8)) || (p[3]&&w7)	;		
assign c[291] = 	(p[1]&&w5) || (p[3]&&(w6||w8)) || (p[4]&&w7)	;		
assign c[292] = 	(p[2]&&w5) || (p[4]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[293] = 	(p[3]&&w5) || (p[5]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[294] = 	(p[0]&&(w6||w7)) || (p[4]&&w5) || (p[6]&&w8)	;		
assign c[295] = 	(p[0]&&w5) || (p[1]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[296] = 	(p[0]&&w8) || (p[1]&&w5) || (p[2]&&(w6||w7))	;		
assign c[297] = 	(p[1]&&w8) || (p[2]&&w5) || (p[3]&&(w6||w7))	;		
assign c[298] = 	(p[2]&&w8) || (p[3]&&w5) || (p[4]&&(w6||w7))	;		
assign c[299] = 	(p[3]&&w8) || (p[4]&&w5) || (p[5]&&(w6||w7))	;		
assign c[300] = 	(p[0]&&(w5||w6)) || (p[4]&&w8) || (p[6]&&w7)	;		
assign c[301] = 	(p[0]&&w7) || (p[1]&&(w5||w6)) || (p[5]&&w8)	;		
assign c[302] = 	(p[1]&&w7) || (p[2]&&(w5||w6)) || (p[6]&&w8)	;		
assign c[303] = 	(p[2]&&w7) || (p[3]&&(w5||w6)) || (p[7]&&w8)	;		
assign c[304] = 	(p[0]&&w8) || (p[3]&&w7) || (p[4]&&(w5||w6))	;		
assign c[305] = 	(p[0]&&w5) || (p[1]&&w8) || (p[4]&&w7) || (p[5]&&w6)	;		
assign c[306] = 	(p[0]&&w6) || (p[1]&&w5) || (p[2]&&w8) || (p[5]&&w7)	;		
assign c[307] = 	(p[1]&&w6) || (p[2]&&w5) || (p[3]&&w8) || (p[6]&&w7)	;		
assign c[308] = 	(p[0]&&w7) || (p[2]&&w6) || (p[3]&&w5) || (p[4]&&w8)	;		
assign c[309] = 	(p[1]&&w7) || (p[3]&&w6) || (p[4]&&w5) || (p[5]&&w8)	;		
assign c[310] = 	(p[0]&&w5) || (p[2]&&w7) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[311] = 	(p[1]&&w5) || (p[3]&&w7) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[312] = 	(p[0]&&(w6||w8)) || (p[2]&&w5) || (p[4]&&w7)	;		
assign c[313] = 	(p[1]&&(w6||w8)) || (p[3]&&w5) || (p[5]&&w7)	;		
assign c[314] = 	(p[2]&&(w6||w8)) || (p[4]&&w5) || (p[6]&&w7)	;		
assign c[315] = 	(p[0]&&(w5||w7)) || (p[3]&&(w6||w8))	;		
assign c[316] = 	(p[1]&&(w5||w7)) || (p[4]&&(w6||w8))	;		
assign c[317] = 	(p[2]&&(w5||w7)) || (p[5]&&(w6||w8))	;		
assign c[318] = 	(p[0]&&w6) || (p[3]&&(w5||w7)) || (p[6]&&w8)	;		
assign c[319] = 	(p[1]&&w6) || (p[4]&&(w5||w7)) || (p[7]&&w8)	;		
assign c[320] = 	(p[0]&&(w5||w8)) || (p[2]&&w6) || (p[5]&&w7)	;		
assign c[321] = 	(p[1]&&(w5||w8)) || (p[3]&&w6) || (p[6]&&w7)	;		
assign c[322] = 	(p[0]&&w7) || (p[2]&&(w5||w8)) || (p[4]&&w6)	;		
assign c[323] = 	(p[1]&&w7) || (p[3]&&(w5||w8)) || (p[5]&&w6)	;		
assign c[324] = 	(p[0]&&w6) || (p[2]&&w7) || (p[4]&&(w5||w8))	;		
assign c[325] = 	(p[0]&&w5) || (p[1]&&w6) || (p[3]&&w7) || (p[5]&&w8)	;		
assign c[326] = 	(p[1]&&w5) || (p[2]&&w6) || (p[4]&&w7) || (p[6]&&w8)	;		
assign c[327] = 	(p[2]&&w5) || (p[3]&&w6) || (p[5]&&w7) || (p[7]&&w8)	;		
assign c[328] = 	(p[0]&&w8) || (p[3]&&w5) || (p[4]&&w6) || (p[6]&&w7)	;		
assign c[329] = 	(p[0]&&w7) || (p[1]&&w8) || (p[4]&&w5) || (p[5]&&w6)	;		
assign c[330] = 	(p[0]&&(w5||w6)) || (p[1]&&w7) || (p[2]&&w8)	;		
assign c[331] = 	(p[1]&&(w5||w6)) || (p[2]&&w7) || (p[3]&&w8)	;		
assign c[332] = 	(p[2]&&(w5||w6)) || (p[3]&&w7) || (p[4]&&w8)	;		
assign c[333] = 	(p[3]&&(w5||w6)) || (p[4]&&w7) || (p[5]&&w8)	;		
assign c[334] = 	(p[4]&&(w5||w6)) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[335] = 	(p[0]&&w5) || (p[5]&&w6) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[336] = 	(p[0]&& !w5) || (p[1]&&w5)	;		
assign c[337] = 	(p[1]&& !w5) || (p[2]&&w5)	;		
assign c[338] = 	(p[2]&& !w5) || (p[3]&&w5)	;		
assign c[339] = 	(p[3]&& !w5) || (p[4]&&w5)	;		
assign c[340] = 	(p[0]&&w5) || (p[4]&& !w5)	;		
assign c[341] = 	(p[1]&&w5) || (p[5]&& !w5)	;		
assign c[342] = 	(p[0]&&w6) || (p[2]&&w5) || (p[6]&&(w7||w8))	;		
assign c[343] = 	(p[0]&&w7) || (p[1]&&w6) || (p[3]&&w5) || (p[7]&&w8)	;		
assign c[344] = 	(p[0]&&w8) || (p[1]&&w7) || (p[2]&&w6) || (p[4]&&w5)	;		
assign c[345] = 	(p[0]&&w5) || (p[1]&&w8) || (p[2]&&w7) || (p[3]&&w6)	;		
assign c[346] = 	(p[1]&&w5) || (p[2]&&w8) || (p[3]&&w7) || (p[4]&&w6)	;		
assign c[347] = 	(p[2]&&w5) || (p[3]&&w8) || (p[4]&&w7) || (p[5]&&w6)	;		
assign c[348] = 	(p[0]&&w6) || (p[3]&&w5) || (p[4]&&w8) || (p[5]&&w7)	;		
assign c[349] = 	(p[1]&&w6) || (p[4]&&w5) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[350] = 	(p[0]&&(w5||w7)) || (p[2]&&w6) || (p[6]&&w8)	;		
assign c[351] = 	(p[1]&&(w5||w7)) || (p[3]&&w6) || (p[7]&&w8)	;		
assign c[352] = 	(p[0]&&w8) || (p[2]&&(w5||w7)) || (p[4]&&w6)	;		
assign c[353] = 	(p[1]&&w8) || (p[3]&&(w5||w7)) || (p[5]&&w6)	;		
assign c[354] = 	(p[0]&&w6) || (p[2]&&w8) || (p[4]&&(w5||w7))	;		
assign c[355] = 	(p[0]&&w5) || (p[1]&&w6) || (p[3]&&w8) || (p[5]&&w7)	;		
assign c[356] = 	(p[1]&&w5) || (p[2]&&w6) || (p[4]&&w8) || (p[6]&&w7)	;		
assign c[357] = 	(p[0]&&w7) || (p[2]&&w5) || (p[3]&&w6) || (p[5]&&w8)	;		
assign c[358] = 	(p[1]&&w7) || (p[3]&&w5) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[359] = 	(p[2]&&w7) || (p[4]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[360] = 	(p[0]&& !w7) || (p[3]&&w7)	;		
assign c[361] = 	(p[1]&& !w7) || (p[4]&&w7)	;		
assign c[362] = 	(p[2]&& !w7) || (p[5]&&w7)	;		
assign c[363] = 	(p[3]&& !w7) || (p[6]&&w7)	;		
assign c[364] = 	(p[0]&&w7) || (p[4]&& !w7)	;		
assign c[365] = 	(p[0]&&w5) || (p[1]&&w7) || (p[5]&&(w6||w8))	;		
assign c[366] = 	(p[0]&&w6) || (p[1]&&w5) || (p[2]&&w7) || (p[6]&&w8)	;		
assign c[367] = 	(p[1]&&w6) || (p[2]&&w5) || (p[3]&&w7) || (p[7]&&w8)	;		
assign c[368] = 	(p[0]&&w8) || (p[2]&&w6) || (p[3]&&w5) || (p[4]&&w7)	;		
assign c[369] = 	(p[1]&&w8) || (p[3]&&w6) || (p[4]&&w5) || (p[5]&&w7)	;		
assign c[370] = 	(p[0]&&w5) || (p[2]&&w8) || (p[4]&&w6) || (p[6]&&w7)	;		
assign c[371] = 	(p[0]&&w7) || (p[1]&&w5) || (p[3]&&w8) || (p[5]&&w6)	;		
assign c[372] = 	(p[0]&&w6) || (p[1]&&w7) || (p[2]&&w5) || (p[4]&&w8)	;		
assign c[373] = 	(p[1]&&w6) || (p[2]&&w7) || (p[3]&&w5) || (p[5]&&w8)	;		
assign c[374] = 	(p[2]&&w6) || (p[3]&&w7) || (p[4]&&w5) || (p[6]&&w8)	;		
assign c[375] = 	(p[0]&&w5) || (p[3]&&w6) || (p[4]&&w7) || (p[7]&&w8)	;		
assign c[376] = 	(p[0]&&w8) || (p[1]&&w5) || (p[4]&&w6) || (p[5]&&w7)	;		
assign c[377] = 	(p[1]&&w8) || (p[2]&&w5) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[378] = 	(p[0]&&(w6||w7)) || (p[2]&&w8) || (p[3]&&w5)	;		
assign c[379] = 	(p[1]&&(w6||w7)) || (p[3]&&w8) || (p[4]&&w5)	;		
assign c[380] = 	(p[0]&&w5) || (p[2]&&(w6||w7)) || (p[4]&&w8)	;		
assign c[381] = 	(p[1]&&w5) || (p[3]&&(w6||w7)) || (p[5]&&w8)	;		
assign c[382] = 	(p[2]&&w5) || (p[4]&&(w6||w7)) || (p[6]&&w8)	;		
assign c[383] = 	(p[3]&&w5) || (p[5]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[384] = 	(p[0]&&(w6||w8)) || (p[4]&&w5) || (p[6]&&w7)	;		
assign c[385] = 	(p[0]&&(w5||w7)) || (p[1]&&(w6||w8))	;		
assign c[386] = 	(p[1]&&(w5||w7)) || (p[2]&&(w6||w8))	;		
assign c[387] = 	(p[2]&&(w5||w7)) || (p[3]&&(w6||w8))	;		
assign c[388] = 	(p[3]&&(w5||w7)) || (p[4]&&(w6||w8))	;		
assign c[389] = 	(p[4]&&(w5||w7)) || (p[5]&&(w6||w8))	;		
assign c[390] = 	(p[0]&&(w5||w6)) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[391] = 	(p[1]&&(w5||w6)) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[392] = 	(p[0]&&(w7||w8)) || (p[2]&&(w5||w6))	;		
assign c[393] = 	(p[1]&&(w7||w8)) || (p[3]&&(w5||w6))	;		
assign c[394] = 	(p[2]&&(w7||w8)) || (p[4]&&(w5||w6))	;		
assign c[395] = 	(p[0]&&w5) || (p[3]&&(w7||w8)) || (p[5]&&w6)	;		
assign c[396] = 	(p[0]&&w6) || (p[1]&&w5) || (p[4]&&(w7||w8))	;		
assign c[397] = 	(p[1]&&w6) || (p[2]&&w5) || (p[5]&&(w7||w8))	;		
assign c[398] = 	(p[2]&&w6) || (p[3]&&w5) || (p[6]&&(w7||w8))	;		
assign c[399] = 	(p[0]&&w7) || (p[3]&&w6) || (p[4]&&w5) || (p[7]&&w8)	;		
assign c[400] = 	(p[0]&&(w5||w8)) || (p[1]&&w7) || (p[4]&&w6)	;		
assign c[401] = 	(p[1]&&(w5||w8)) || (p[2]&&w7) || (p[5]&&w6)	;		
assign c[402] = 	(p[0]&&w6) || (p[2]&&(w5||w8)) || (p[3]&&w7)	;		
assign c[403] = 	(p[1]&&w6) || (p[3]&&(w5||w8)) || (p[4]&&w7)	;		
assign c[404] = 	(p[2]&&w6) || (p[4]&&(w5||w8)) || (p[5]&&w7)	;		
assign c[405] = 	(p[0]&&w5) || (p[3]&&w6) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[406] = 	(p[0]&&w7) || (p[1]&&w5) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[407] = 	(p[1]&&w7) || (p[2]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[408] = 	(p[0]&&(w6||w8)) || (p[2]&&w7) || (p[3]&&w5)	;		
assign c[409] = 	(p[1]&&(w6||w8)) || (p[3]&&w7) || (p[4]&&w5)	;		
assign c[410] = 	(p[0]&&w5) || (p[2]&&(w6||w8)) || (p[4]&&w7)	;		
assign c[411] = 	(p[1]&&w5) || (p[3]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[412] = 	(p[2]&&w5) || (p[4]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[413] = 	(p[0]&&w7) || (p[3]&&w5) || (p[5]&&(w6||w8))	;		
assign c[414] = 	(p[0]&&w6) || (p[1]&&w7) || (p[4]&&w5) || (p[6]&&w8)	;		
assign c[415] = 	(p[0]&&w5) || (p[1]&&w6) || (p[2]&&w7) || (p[7]&&w8)	;		
assign c[416] = 	(p[0]&&w8) || (p[1]&&w5) || (p[2]&&w6) || (p[3]&&w7)	;		
assign c[417] = 	(p[1]&&w8) || (p[2]&&w5) || (p[3]&&w6) || (p[4]&&w7)	;		
assign c[418] = 	(p[2]&&w8) || (p[3]&&w5) || (p[4]&&w6) || (p[5]&&w7)	;		
assign c[419] = 	(p[3]&&w8) || (p[4]&&w5) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[420] = 	(p[0]&& !w8) || (p[4]&&w8)	;		
assign c[421] = 	(p[1]&& !w8) || (p[5]&&w8)	;		
assign c[422] = 	(p[2]&& !w8) || (p[6]&&w8)	;		
assign c[423] = 	(p[3]&& !w8) || (p[7]&&w8)	;		
assign c[424] = 	(p[0]&&w8) || (p[4]&& !w8)	;		
assign c[425] = 	(p[0]&&w5) || (p[1]&&w8) || (p[5]&&(w6||w7))	;		
assign c[426] = 	(p[0]&&w6) || (p[1]&&w5) || (p[2]&&w8) || (p[6]&&w7)	;		
assign c[427] = 	(p[0]&&w7) || (p[1]&&w6) || (p[2]&&w5) || (p[3]&&w8)	;		
assign c[428] = 	(p[1]&&w7) || (p[2]&&w6) || (p[3]&&w5) || (p[4]&&w8)	;		
assign c[429] = 	(p[2]&&w7) || (p[3]&&w6) || (p[4]&&w5) || (p[5]&&w8)	;		
assign c[430] = 	(p[0]&&w5) || (p[3]&&w7) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[431] = 	(p[1]&&w5) || (p[4]&&w7) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[432] = 	(p[0]&&(w6||w8)) || (p[2]&&w5) || (p[5]&&w7)	;		
assign c[433] = 	(p[1]&&(w6||w8)) || (p[3]&&w5) || (p[6]&&w7)	;		
assign c[434] = 	(p[0]&&w7) || (p[2]&&(w6||w8)) || (p[4]&&w5)	;		
assign c[435] = 	(p[0]&&w5) || (p[1]&&w7) || (p[3]&&(w6||w8))	;		
assign c[436] = 	(p[1]&&w5) || (p[2]&&w7) || (p[4]&&(w6||w8))	;		
assign c[437] = 	(p[2]&&w5) || (p[3]&&w7) || (p[5]&&(w6||w8))	;		
assign c[438] = 	(p[0]&&w6) || (p[3]&&w5) || (p[4]&&w7) || (p[6]&&w8)	;		
assign c[439] = 	(p[1]&&w6) || (p[4]&&w5) || (p[5]&&w7) || (p[7]&&w8)	;		
assign c[440] = 	(p[0]&&(w5||w8)) || (p[2]&&w6) || (p[6]&&w7)	;		
assign c[441] = 	(p[0]&&w7) || (p[1]&&(w5||w8)) || (p[3]&&w6)	;		
assign c[442] = 	(p[1]&&w7) || (p[2]&&(w5||w8)) || (p[4]&&w6)	;		
assign c[443] = 	(p[2]&&w7) || (p[3]&&(w5||w8)) || (p[5]&&w6)	;		
assign c[444] = 	(p[0]&&w6) || (p[3]&&w7) || (p[4]&&(w5||w8))	;		
assign c[445] = 	(p[0]&&w5) || (p[1]&&w6) || (p[4]&&w7) || (p[5]&&w8)	;		
assign c[446] = 	(p[1]&&w5) || (p[2]&&w6) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[447] = 	(p[2]&&w5) || (p[3]&&w6) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[448] = 	(p[0]&&(w7||w8)) || (p[3]&&w5) || (p[4]&&w6)	;		
assign c[449] = 	(p[1]&&(w7||w8)) || (p[4]&&w5) || (p[5]&&w6)	;		
assign c[450] = 	(p[0]&&(w5||w6)) || (p[2]&&(w7||w8))	;		
assign c[451] = 	(p[1]&&(w5||w6)) || (p[3]&&(w7||w8))	;		
assign c[452] = 	(p[2]&&(w5||w6)) || (p[4]&&(w7||w8))	;		
assign c[453] = 	(p[3]&&(w5||w6)) || (p[5]&&(w7||w8))	;		
assign c[454] = 	(p[4]&&(w5||w6)) || (p[6]&&(w7||w8))	;		
assign c[455] = 	(p[0]&&(w5||w7)) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[456] = 	(p[0]&&(w6||w8)) || (p[1]&&(w5||w7))	;		
assign c[457] = 	(p[1]&&(w6||w8)) || (p[2]&&(w5||w7))	;		
assign c[458] = 	(p[2]&&(w6||w8)) || (p[3]&&(w5||w7))	;		
assign c[459] = 	(p[3]&&(w6||w8)) || (p[4]&&(w5||w7))	;		
assign c[460] = 	(p[0]&&w5) || (p[4]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[461] = 	(p[1]&&w5) || (p[5]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[462] = 	(p[0]&&(w6||w7)) || (p[2]&&w5) || (p[6]&&w8)	;		
assign c[463] = 	(p[1]&&(w6||w7)) || (p[3]&&w5) || (p[7]&&w8)	;		
assign c[464] = 	(p[0]&&w8) || (p[2]&&(w6||w7)) || (p[4]&&w5)	;		
assign c[465] = 	(p[0]&&w5) || (p[1]&&w8) || (p[3]&&(w6||w7))	;		
assign c[466] = 	(p[1]&&w5) || (p[2]&&w8) || (p[4]&&(w6||w7))	;		
assign c[467] = 	(p[2]&&w5) || (p[3]&&w8) || (p[5]&&(w6||w7))	;		
assign c[468] = 	(p[0]&&w6) || (p[3]&&w5) || (p[4]&&w8) || (p[6]&&w7)	;		
assign c[469] = 	(p[0]&&w7) || (p[1]&&w6) || (p[4]&&w5) || (p[5]&&w8)	;		
assign c[470] = 	(p[0]&&w5) || (p[1]&&w7) || (p[2]&&w6) || (p[6]&&w8)	;		
assign c[471] = 	(p[1]&&w5) || (p[2]&&w7) || (p[3]&&w6) || (p[7]&&w8)	;		
assign c[472] = 	(p[0]&&w8) || (p[2]&&w5) || (p[3]&&w7) || (p[4]&&w6)	;		
assign c[473] = 	(p[1]&&w8) || (p[3]&&w5) || (p[4]&&w7) || (p[5]&&w6)	;		
assign c[474] = 	(p[0]&&w6) || (p[2]&&w8) || (p[4]&&w5) || (p[5]&&w7)	;		
assign c[475] = 	(p[0]&&w5) || (p[1]&&w6) || (p[3]&&w8) || (p[6]&&w7)	;		
assign c[476] = 	(p[0]&&w7) || (p[1]&&w5) || (p[2]&&w6) || (p[4]&&w8)	;		
assign c[477] = 	(p[1]&&w7) || (p[2]&&w5) || (p[3]&&w6) || (p[5]&&w8)	;		
assign c[478] = 	(p[2]&&w7) || (p[3]&&w5) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[479] = 	(p[3]&&w7) || (p[4]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[480] = 	(p[0]&& !w7) || (p[4]&&w7)	;		
assign c[481] = 	(p[1]&& !w7) || (p[5]&&w7)	;		
assign c[482] = 	(p[2]&& !w7) || (p[6]&&w7)	;		
assign c[483] = 	(p[0]&&w7) || (p[3]&& !w7)	;		
assign c[484] = 	(p[1]&&w7) || (p[4]&& !w7)	;		
assign c[485] = 	(p[0]&&w5) || (p[2]&&w7) || (p[5]&&(w6||w8))	;		
assign c[486] = 	(p[0]&&w6) || (p[1]&&w5) || (p[3]&&w7) || (p[6]&&w8)	;		
assign c[487] = 	(p[1]&&w6) || (p[2]&&w5) || (p[4]&&w7) || (p[7]&&w8)	;		
assign c[488] = 	(p[0]&&w8) || (p[2]&&w6) || (p[3]&&w5) || (p[5]&&w7)	;		
assign c[489] = 	(p[1]&&w8) || (p[3]&&w6) || (p[4]&&w5) || (p[6]&&w7)	;		
assign c[490] = 	(p[0]&&(w5||w7)) || (p[2]&&w8) || (p[4]&&w6)	;		
assign c[491] = 	(p[1]&&(w5||w7)) || (p[3]&&w8) || (p[5]&&w6)	;		
assign c[492] = 	(p[0]&&w6) || (p[2]&&(w5||w7)) || (p[4]&&w8)	;		
assign c[493] = 	(p[1]&&w6) || (p[3]&&(w5||w7)) || (p[5]&&w8)	;		
assign c[494] = 	(p[2]&&w6) || (p[4]&&(w5||w7)) || (p[6]&&w8)	;		
assign c[495] = 	(p[0]&&w5) || (p[3]&&w6) || (p[5]&&w7) || (p[7]&&w8)	;		
assign c[496] = 	(p[0]&&w8) || (p[1]&&w5) || (p[4]&&w6) || (p[6]&&w7)	;		
assign c[497] = 	(p[0]&&w7) || (p[1]&&w8) || (p[2]&&w5) || (p[5]&&w6)	;		
assign c[498] = 	(p[0]&&w6) || (p[1]&&w7) || (p[2]&&w8) || (p[3]&&w5)	;		
assign c[499] = 	(p[1]&&w6) || (p[2]&&w7) || (p[3]&&w8) || (p[4]&&w5)	;		
assign c[500] = 	(p[0]&&w5) || (p[2]&&w6) || (p[3]&&w7) || (p[4]&&w8)	;		
assign c[501] = 	(p[1]&&w5) || (p[3]&&w6) || (p[4]&&w7) || (p[5]&&w8)	;		
assign c[502] = 	(p[2]&&w5) || (p[4]&&w6) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[503] = 	(p[3]&&w5) || (p[5]&&w6) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[504] = 	(p[0]&& !w5) || (p[4]&&w5)	;		
assign c[505] = 	(p[0]&&w5) || (p[1]&& !w5)	;		
assign c[506] = 	(p[1]&&w5) || (p[2]&& !w5)	;		
assign c[507] = 	(p[2]&&w5) || (p[3]&& !w5)	;		
assign c[508] = 	(p[3]&&w5) || (p[4]&& !w5)	;		
assign c[509] = 	(p[4]&&w5) || (p[5]&& !w5)	;		
assign c[510] = 	(p[0]&&(w5||w6)) || (p[6]&&(w7||w8))	;		
assign c[511] = 	(p[0]&&w7) || (p[1]&&(w5||w6)) || (p[7]&&w8)	;		
assign c[512] = 	(p[0]&&w8) || (p[1]&&w7) || (p[2]&&(w5||w6))	;		
assign c[513] = 	(p[1]&&w8) || (p[2]&&w7) || (p[3]&&(w5||w6))	;		
assign c[514] = 	(p[2]&&w8) || (p[3]&&w7) || (p[4]&&(w5||w6))	;		
assign c[515] = 	(p[0]&&w5) || (p[3]&&w8) || (p[4]&&w7) || (p[5]&&w6)	;		
assign c[516] = 	(p[0]&&w6) || (p[1]&&w5) || (p[4]&&w8) || (p[5]&&w7)	;		
assign c[517] = 	(p[1]&&w6) || (p[2]&&w5) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[518] = 	(p[0]&&w7) || (p[2]&&w6) || (p[3]&&w5) || (p[6]&&w8)	;		
assign c[519] = 	(p[1]&&w7) || (p[3]&&w6) || (p[4]&&w5) || (p[7]&&w8)	;		
assign c[520] = 	(p[0]&&(w5||w8)) || (p[2]&&w7) || (p[4]&&w6)	;		
assign c[521] = 	(p[1]&&(w5||w8)) || (p[3]&&w7) || (p[5]&&w6)	;		
assign c[522] = 	(p[0]&&w6) || (p[2]&&(w5||w8)) || (p[4]&&w7)	;		
assign c[523] = 	(p[1]&&w6) || (p[3]&&(w5||w8)) || (p[5]&&w7)	;		
assign c[524] = 	(p[2]&&w6) || (p[4]&&(w5||w8)) || (p[6]&&w7)	;		
assign c[525] = 	(p[0]&&(w5||w7)) || (p[3]&&w6) || (p[5]&&w8)	;		
assign c[526] = 	(p[1]&&(w5||w7)) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[527] = 	(p[2]&&(w5||w7)) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[528] = 	(p[0]&&(w6||w8)) || (p[3]&&(w5||w7))	;		
assign c[529] = 	(p[1]&&(w6||w8)) || (p[4]&&(w5||w7))	;		
assign c[530] = 	(p[0]&&w5) || (p[2]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[531] = 	(p[1]&&w5) || (p[3]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[532] = 	(p[0]&&w7) || (p[2]&&w5) || (p[4]&&(w6||w8))	;		
assign c[533] = 	(p[1]&&w7) || (p[3]&&w5) || (p[5]&&(w6||w8))	;		
assign c[534] = 	(p[0]&&w6) || (p[2]&&w7) || (p[4]&&w5) || (p[6]&&w8)	;		
assign c[535] = 	(p[0]&&w5) || (p[1]&&w6) || (p[3]&&w7) || (p[7]&&w8)	;		
assign c[536] = 	(p[0]&&w8) || (p[1]&&w5) || (p[2]&&w6) || (p[4]&&w7)	;		
assign c[537] = 	(p[1]&&w8) || (p[2]&&w5) || (p[3]&&w6) || (p[5]&&w7)	;		
assign c[538] = 	(p[2]&&w8) || (p[3]&&w5) || (p[4]&&w6) || (p[6]&&w7)	;		
assign c[539] = 	(p[0]&&w7) || (p[3]&&w8) || (p[4]&&w5) || (p[5]&&w6)	;		
assign c[540] = 	(p[0]&&(w5||w6)) || (p[1]&&w7) || (p[4]&&w8)	;		
assign c[541] = 	(p[1]&&(w5||w6)) || (p[2]&&w7) || (p[5]&&w8)	;		
assign c[542] = 	(p[2]&&(w5||w6)) || (p[3]&&w7) || (p[6]&&w8)	;		
assign c[543] = 	(p[3]&&(w5||w6)) || (p[4]&&w7) || (p[7]&&w8)	;		
assign c[544] = 	(p[0]&&w8) || (p[4]&&(w5||w6)) || (p[5]&&w7)	;		
assign c[545] = 	(p[0]&&w5) || (p[1]&&w8) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[546] = 	(p[0]&&(w6||w7)) || (p[1]&&w5) || (p[2]&&w8)	;		
assign c[547] = 	(p[1]&&(w6||w7)) || (p[2]&&w5) || (p[3]&&w8)	;		
assign c[548] = 	(p[2]&&(w6||w7)) || (p[3]&&w5) || (p[4]&&w8)	;		
assign c[549] = 	(p[3]&&(w6||w7)) || (p[4]&&w5) || (p[5]&&w8)	;		
assign c[550] = 	(p[0]&&w5) || (p[4]&&(w6||w7)) || (p[6]&&w8)	;		
assign c[551] = 	(p[1]&&w5) || (p[5]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[552] = 	(p[0]&&(w6||w8)) || (p[2]&&w5) || (p[6]&&w7)	;		
assign c[553] = 	(p[0]&&w7) || (p[1]&&(w6||w8)) || (p[3]&&w5)	;		
assign c[554] = 	(p[1]&&w7) || (p[2]&&(w6||w8)) || (p[4]&&w5)	;		
assign c[555] = 	(p[0]&&w5) || (p[2]&&w7) || (p[3]&&(w6||w8))	;		
assign c[556] = 	(p[1]&&w5) || (p[3]&&w7) || (p[4]&&(w6||w8))	;		
assign c[557] = 	(p[2]&&w5) || (p[4]&&w7) || (p[5]&&(w6||w8))	;		
assign c[558] = 	(p[0]&&w6) || (p[3]&&w5) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[559] = 	(p[1]&&w6) || (p[4]&&w5) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[560] = 	(p[0]&& !w6) || (p[2]&&w6)	;		
assign c[561] = 	(p[1]&& !w6) || (p[3]&&w6)	;		
assign c[562] = 	(p[2]&& !w6) || (p[4]&&w6)	;		
assign c[563] = 	(p[3]&& !w6) || (p[5]&&w6)	;		
assign c[564] = 	(p[0]&&w6) || (p[4]&& !w6)	;		
assign c[565] = 	(p[0]&&w5) || (p[1]&&w6) || (p[5]&&(w7||w8))	;		
assign c[566] = 	(p[1]&&w5) || (p[2]&&w6) || (p[6]&&(w7||w8))	;		
assign c[567] = 	(p[0]&&w7) || (p[2]&&w5) || (p[3]&&w6) || (p[7]&&w8)	;		
assign c[568] = 	(p[0]&&w8) || (p[1]&&w7) || (p[3]&&w5) || (p[4]&&w6)	;		
assign c[569] = 	(p[1]&&w8) || (p[2]&&w7) || (p[4]&&w5) || (p[5]&&w6)	;		
assign c[570] = 	(p[0]&&(w5||w6)) || (p[2]&&w8) || (p[3]&&w7)	;		
assign c[571] = 	(p[1]&&(w5||w6)) || (p[3]&&w8) || (p[4]&&w7)	;		
assign c[572] = 	(p[2]&&(w5||w6)) || (p[4]&&w8) || (p[5]&&w7)	;		
assign c[573] = 	(p[3]&&(w5||w6)) || (p[5]&&w8) || (p[6]&&w7)	;		
assign c[574] = 	(p[0]&&w7) || (p[4]&&(w5||w6)) || (p[6]&&w8)	;		
assign c[575] = 	(p[0]&&w5) || (p[1]&&w7) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[576] = 	(p[0]&&(w6||w8)) || (p[1]&&w5) || (p[2]&&w7)	;		
assign c[577] = 	(p[1]&&(w6||w8)) || (p[2]&&w5) || (p[3]&&w7)	;		
assign c[578] = 	(p[2]&&(w6||w8)) || (p[3]&&w5) || (p[4]&&w7)	;		
assign c[579] = 	(p[3]&&(w6||w8)) || (p[4]&&w5) || (p[5]&&w7)	;		
assign c[580] = 	(p[0]&&w5) || (p[4]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[581] = 	(p[0]&&w7) || (p[1]&&w5) || (p[5]&&(w6||w8))	;		
assign c[582] = 	(p[0]&&w6) || (p[1]&&w7) || (p[2]&&w5) || (p[6]&&w8)	;		
assign c[583] = 	(p[1]&&w6) || (p[2]&&w7) || (p[3]&&w5) || (p[7]&&w8)	;		
assign c[584] = 	(p[0]&&w8) || (p[2]&&w6) || (p[3]&&w7) || (p[4]&&w5)	;		
assign c[585] = 	(p[0]&&w5) || (p[1]&&w8) || (p[3]&&w6) || (p[4]&&w7)	;		
assign c[586] = 	(p[1]&&w5) || (p[2]&&w8) || (p[4]&&w6) || (p[5]&&w7)	;		
assign c[587] = 	(p[2]&&w5) || (p[3]&&w8) || (p[5]&&w6) || (p[6]&&w7)	;		
assign c[588] = 	(p[0]&&(w6||w7)) || (p[3]&&w5) || (p[4]&&w8)	;		
assign c[589] = 	(p[1]&&(w6||w7)) || (p[4]&&w5) || (p[5]&&w8)	;		
assign c[590] = 	(p[0]&&w5) || (p[2]&&(w6||w7)) || (p[6]&&w8)	;		
assign c[591] = 	(p[1]&&w5) || (p[3]&&(w6||w7)) || (p[7]&&w8)	;		
assign c[592] = 	(p[0]&&w8) || (p[2]&&w5) || (p[4]&&(w6||w7))	;		
assign c[593] = 	(p[1]&&w8) || (p[3]&&w5) || (p[5]&&(w6||w7))	;		
assign c[594] = 	(p[0]&&w6) || (p[2]&&w8) || (p[4]&&w5) || (p[6]&&w7)	;		
assign c[595] = 	(p[0]&&(w5||w7)) || (p[1]&&w6) || (p[3]&&w8)	;		
assign c[596] = 	(p[1]&&(w5||w7)) || (p[2]&&w6) || (p[4]&&w8)	;		
assign c[597] = 	(p[2]&&(w5||w7)) || (p[3]&&w6) || (p[5]&&w8)	;		
assign c[598] = 	(p[3]&&(w5||w7)) || (p[4]&&w6) || (p[6]&&w8)	;		
assign c[599] = 	(p[4]&&(w5||w7)) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[600] = 	(p[0]&& !w7) || (p[5]&&w7)	;		
assign c[601] = 	(p[1]&& !w7) || (p[6]&&w7)	;		
assign c[602] = 	(p[0]&&w7) || (p[2]&& !w7)	;		
assign c[603] = 	(p[1]&&w7) || (p[3]&& !w7)	;		
assign c[604] = 	(p[2]&&w7) || (p[4]&& !w7)	;		
assign c[605] = 	(p[0]&&w5) || (p[3]&&w7) || (p[5]&&(w6||w8))	;		
assign c[606] = 	(p[0]&&w6) || (p[1]&&w5) || (p[4]&&w7) || (p[6]&&w8)	;		
assign c[607] = 	(p[1]&&w6) || (p[2]&&w5) || (p[5]&&w7) || (p[7]&&w8)	;		
assign c[608] = 	(p[0]&&w8) || (p[2]&&w6) || (p[3]&&w5) || (p[6]&&w7)	;		
assign c[609] = 	(p[0]&&w7) || (p[1]&&w8) || (p[3]&&w6) || (p[4]&&w5)	;		
assign c[610] = 	(p[0]&&w5) || (p[1]&&w7) || (p[2]&&w8) || (p[4]&&w6)	;		
assign c[611] = 	(p[1]&&w5) || (p[2]&&w7) || (p[3]&&w8) || (p[5]&&w6)	;		
assign c[612] = 	(p[0]&&w6) || (p[2]&&w5) || (p[3]&&w7) || (p[4]&&w8)	;		
assign c[613] = 	(p[1]&&w6) || (p[3]&&w5) || (p[4]&&w7) || (p[5]&&w8)	;		
assign c[614] = 	(p[2]&&w6) || (p[4]&&w5) || (p[5]&&w7) || (p[6]&&w8)	;		
assign c[615] = 	(p[0]&&w5) || (p[3]&&w6) || (p[6]&&w7) || (p[7]&&w8)	;		
assign c[616] = 	(p[0]&&(w7||w8)) || (p[1]&&w5) || (p[4]&&w6)	;		
assign c[617] = 	(p[1]&&(w7||w8)) || (p[2]&&w5) || (p[5]&&w6)	;		
assign c[618] = 	(p[0]&&w6) || (p[2]&&(w7||w8)) || (p[3]&&w5)	;		
assign c[619] = 	(p[1]&&w6) || (p[3]&&(w7||w8)) || (p[4]&&w5)	;		
assign c[620] = 	(p[0]&&w5) || (p[2]&&w6) || (p[4]&&(w7||w8))	;		
assign c[621] = 	(p[1]&&w5) || (p[3]&&w6) || (p[5]&&(w7||w8))	;		
assign c[622] = 	(p[2]&&w5) || (p[4]&&w6) || (p[6]&&(w7||w8))	;		
assign c[623] = 	(p[0]&&w7) || (p[3]&&w5) || (p[5]&&w6) || (p[7]&&w8)	;		
assign c[624] = 	(p[0]&&(w6||w8)) || (p[1]&&w7) || (p[4]&&w5)	;		
assign c[625] = 	(p[0]&&w5) || (p[1]&&(w6||w8)) || (p[2]&&w7)	;		
assign c[626] = 	(p[1]&&w5) || (p[2]&&(w6||w8)) || (p[3]&&w7)	;		
assign c[627] = 	(p[2]&&w5) || (p[3]&&(w6||w8)) || (p[4]&&w7)	;		
assign c[628] = 	(p[3]&&w5) || (p[4]&&(w6||w8)) || (p[5]&&w7)	;		
assign c[629] = 	(p[4]&&w5) || (p[5]&&(w6||w8)) || (p[6]&&w7)	;		
assign c[630] = 	(p[0]&& !w8) || (p[6]&&w8)	;		
assign c[631] = 	(p[1]&& !w8) || (p[7]&&w8)	;		
assign c[632] = 	(p[0]&&w8) || (p[2]&& !w8)	;		
assign c[633] = 	(p[1]&&w8) || (p[3]&& !w8)	;		
assign c[634] = 	(p[2]&&w8) || (p[4]&& !w8)	;		
assign c[635] = 	(p[0]&&w5) || (p[3]&&w8) || (p[5]&&(w6||w7))	;		
assign c[636] = 	(p[0]&&w6) || (p[1]&&w5) || (p[4]&&w8) || (p[6]&&w7)	;		
assign c[637] = 	(p[0]&&w7) || (p[1]&&w6) || (p[2]&&w5) || (p[5]&&w8)	;		
assign c[638] = 	(p[1]&&w7) || (p[2]&&w6) || (p[3]&&w5) || (p[6]&&w8)	;		
assign c[639] = 	(p[2]&&w7) || (p[3]&&w6) || (p[4]&&w5) || (p[7]&&w8)	;




always @(*)
begin
	if(~rst_n) 
	begin
		slide_bit = 'd0;
		pre_reg_next = 'd0;
		post_reg_next = 'd0;
		feedback_bit = 'd0;
		valid_next 		= 'b0;
		reg_next 		= 'd0;
		// p 				= 'd0;
	end
	
	else
	begin 
		

		if (load_pattern)
		begin 
			reg_next 	= reg_curr;
			valid_next 	= 1'b0;
		end 
		else
		begin 

			case (mask_type)

				2'b00: // Sliding right
				begin 

					valid_next = 1'b1;

					for (int i = 0; i < 32; i++)
					begin 
				
						pre_reg_next = 'd0;

						// Define the Sliding bit to the extra post reg
						slide_bit = reg_curr[639];
						post_reg_next = {slide_bit,post_reg_curr[0:30]};

						// Define the feedback bit to slide the pattern right
						if(pattern_w == (i+1))
						begin 

							feedback_bit = post_reg_curr[i];
							reg_next = {feedback_bit,reg_curr[0:638]};

						end

					end

				end

				2'b01: // Sliding left
				begin 

					valid_next = 1'b1;

					for (int i = 0; i < 32; i++)
					begin 
				
						post_reg_next = 'd0;

						// Define the Sliding bit to the extra pre reg
						slide_bit = reg_curr[0];
						pre_reg_next  = {pre_reg_curr[1:31],slide_bit};

						// Define the feedback bit to slide the pattern left
						if (pattern_w == (32-i))
						begin 

							feedback_bit = pre_reg_curr[i];
							reg_next = {reg_curr[1:639],feedback_bit};	
						
						end

					end

				end

				2'b10: // Random Pattern: Fibonacci random number generator
				begin 

					if (seedLoaded)
					begin

						valid_next =1'b1;

					end
					else // Loading seeds is not yet done.
					begin
						
						valid_next =1'b0;
					end
				
				end

				2'b11:	// Repeated Pattern generation
				begin 
					valid_next = 1'b1;
				end
				
				default: // Random Pattern
				begin 

					if (seedLoaded)
					begin

						valid_next =1'b1;

					end
					else // Loading seeds is not yet done.
					begin
						
						valid_next =1'b0;
					end

				end

			endcase


		end
	
	end


end

always_ff @(posedge clk or negedge rst_n) 
begin

	if(~rst_n) 
	begin
		 rp_valid = 1'b0;
		 reg_curr = 'd0;
		 seedCounter ='d0;
		 mg_mask ='d0;
		 pre_reg_curr ='d0;
		 post_reg_curr ='d0;
		 seedLoaded = 'd0;
		 p 			= 'd0;
	end 
	else if(clk_en)
	begin

		// if (load_pattern && mask_type == 2'b11) // load pattern for the repeated Pattern
		// begin

		// 	p = {pattern,p[7:1]};
		// 	rp_valid = 1'b0;
	       
		// end
		// else
		if (load_pattern)
		begin

			reg_curr = {pattern,reg_curr[0:638]};
			rp_valid=1'd0;
			seedCounter = 'd0;
        	pre_reg_curr ='d0;
        	post_reg_curr ='d0;
			p 	= repeatedPattern;	
	       
		end
		else
		begin

			pre_reg_curr =pre_reg_next;
			post_reg_curr =post_reg_next;

			
			rp_valid = valid_next;

			// Controlling the time for outputing the mg_mask
			case (mask_type)

				2'b00: // Sliding right
				begin
					reg_curr = reg_next;
					mg_mask = reg_curr;
				end

				2'b01: // Sliding left
				begin
					reg_curr = reg_next;
					mg_mask = reg_curr;
				end

				2'b10: // Random Pattern: Fibonacci random number generator
				begin 
					reg_curr = reg_next_random;
					
					if (seedCounter == 'b0) 
					begin 
						seedCounter = 'b1;
						seedLoaded  = 1'b0;
					end
					else
					begin 
						mg_mask =reg_curr;
						seedLoaded  = 1'b1; 
					end

				end

				2'b11:  // Repeated Pattern
				begin 
					mg_mask = c;
					rp_valid = 1'b1;
				end
		
				default : // Random Pattern
				begin

					reg_curr = reg_next_random;
					
					if (seedCounter == 'b0) 
					begin 
						seedCounter = 'b1;
						seedLoaded  = 1'b0;
					end
					else
					begin 
						mg_mask =reg_curr;
						seedLoaded  = 1'b1; 
					end

				end
			endcase

		end

	end
end



endmodule