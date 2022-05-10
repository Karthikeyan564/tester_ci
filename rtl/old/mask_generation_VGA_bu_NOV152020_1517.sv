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
	input [4:0] pattern_w, 				// size of the pattern W 
	input pattern,						// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	input right_sliding,				// Direction of sliding 1-- right / 0 -- left
	input load_pattern, 				// to load the pattern for repetition

	input mask_type,					// Choose the type of mask between sliding pattern 0 - Random Mask 1 

	output logic [0:639] mg_mask,
	output logic [0:639] mg_mask_n,

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
logic seedCounter;   	// counter for the random number across multiple columns based on the 640
logic seedLoaded;			// Signal will be asserted once all the seeds are loaded. 


// feedback bits used in random pattern generation
logic feedback_bit_random[0:19][0:31];
logic [0:639] reg_next_random;


// Generate Feedback loop
genvar i;
generate

	for (i = 0; i < 20; i++)
	begin
		// Verified Passing the Random Tests
		// calculate feedback bits using a single feedback polynomial
		// assign feedback_bit_random[i][0]   = reg_curr[i+31] ^ reg_curr[i+21]  		   ^ reg_curr[i+1]   			^ reg_curr[i+0];
		// assign feedback_bit_random[i][1]   = reg_curr[i+30] ^ reg_curr[i+20]  		   ^ reg_curr[i+0]   			^ feedback_bit_random[i][0];
		// assign feedback_bit_random[i][2]   = reg_curr[i+29] ^ reg_curr[i+19]  		   ^ feedback_bit_random[i][0]  ^ feedback_bit_random[i][1];
		// assign feedback_bit_random[i][3]   = reg_curr[i+28] ^ reg_curr[i+18]  		   ^ feedback_bit_random[i][1]  ^ feedback_bit_random[i][2];
		// assign feedback_bit_random[i][4]   = reg_curr[i+27] ^ reg_curr[i+17]  		   ^ feedback_bit_random[i][2]  ^ feedback_bit_random[i][3];
		// assign feedback_bit_random[i][5]   = reg_curr[i+26] ^ reg_curr[i+16]  		   ^ feedback_bit_random[i][3]  ^ feedback_bit_random[i][4];
		// assign feedback_bit_random[i][6]   = reg_curr[i+25] ^ reg_curr[i+15]  		   ^ feedback_bit_random[i][4]  ^ feedback_bit_random[i][5];
		// assign feedback_bit_random[i][7]   = reg_curr[i+24] ^ reg_curr[i+14]  		   ^ feedback_bit_random[i][5]  ^ feedback_bit_random[i][6];
		// assign feedback_bit_random[i][8]   = reg_curr[i+23] ^ reg_curr[i+13]  		   ^ feedback_bit_random[i][6]  ^ feedback_bit_random[i][7];
		// assign feedback_bit_random[i][9]   = reg_curr[i+22] ^ reg_curr[i+12]  		   ^ feedback_bit_random[i][7]  ^ feedback_bit_random[i][8];
		// assign feedback_bit_random[i][10]  = reg_curr[i+21] ^ reg_curr[i+11]  		   ^ feedback_bit_random[i][8]  ^ feedback_bit_random[i][9];
		// assign feedback_bit_random[i][11]  = reg_curr[i+20] ^ reg_curr[i+10]  		   ^ feedback_bit_random[i][9]  ^ feedback_bit_random[i][10];
		// assign feedback_bit_random[i][12]  = reg_curr[i+19] ^ reg_curr[i+9]   		   ^ feedback_bit_random[i][10] ^ feedback_bit_random[i][11];
		// assign feedback_bit_random[i][13]  = reg_curr[i+18] ^ reg_curr[i+8]   		   ^ feedback_bit_random[i][11] ^ feedback_bit_random[i][12];
		// assign feedback_bit_random[i][14]  = reg_curr[i+17] ^ reg_curr[i+7]   		   ^ feedback_bit_random[i][12] ^ feedback_bit_random[i][13];
		// assign feedback_bit_random[i][15]  = reg_curr[i+16] ^ reg_curr[i+6]   		   ^ feedback_bit_random[i][13] ^ feedback_bit_random[i][14];
		// assign feedback_bit_random[i][16]  = reg_curr[i+15] ^ reg_curr[i+5]   		   ^ feedback_bit_random[i][14] ^ feedback_bit_random[i][15];
		// assign feedback_bit_random[i][17]  = reg_curr[i+14] ^ reg_curr[i+4]   		   ^ feedback_bit_random[i][15] ^ feedback_bit_random[i][16];
		// assign feedback_bit_random[i][18]  = reg_curr[i+13] ^ reg_curr[i+3]   		   ^ feedback_bit_random[i][16] ^ feedback_bit_random[i][17];
		// assign feedback_bit_random[i][19]  = reg_curr[i+12] ^ reg_curr[i+2]   		   ^ feedback_bit_random[i][17] ^ feedback_bit_random[i][18];
		// assign feedback_bit_random[i][20]  = reg_curr[i+11] ^ reg_curr[i+1]   		   ^ feedback_bit_random[i][18] ^ feedback_bit_random[i][19];
		// assign feedback_bit_random[i][21]  = reg_curr[i+10] ^ reg_curr[i+0]   		   ^ feedback_bit_random[i][19] ^ feedback_bit_random[i][20];
		// assign feedback_bit_random[i][22]  = reg_curr[i+9]  ^ feedback_bit_random[i][0]  ^ feedback_bit_random[i][20] ^ feedback_bit_random[i][21];
		// assign feedback_bit_random[i][23]  = reg_curr[i+8]  ^ feedback_bit_random[i][1]  ^ feedback_bit_random[i][21] ^ feedback_bit_random[i][22];
		// assign feedback_bit_random[i][25]  = reg_curr[i+6]  ^ feedback_bit_random[i][3]  ^ feedback_bit_random[i][23] ^ feedback_bit_random[i][24];
		// assign feedback_bit_random[i][26]  = reg_curr[i+5]  ^ feedback_bit_random[i][4]  ^ feedback_bit_random[i][24] ^ feedback_bit_random[i][25];
		// assign feedback_bit_random[i][27]  = reg_curr[i+4]  ^ feedback_bit_random[i][5]  ^ feedback_bit_random[i][25] ^ feedback_bit_random[i][26];
		// assign feedback_bit_random[i][24]  = reg_curr[i+7]  ^ feedback_bit_random[i][2]  ^ feedback_bit_random[i][22] ^ feedback_bit_random[i][23];
		// assign feedback_bit_random[i][28]  = reg_curr[i+3]  ^ feedback_bit_random[i][6]  ^ feedback_bit_random[i][26] ^ feedback_bit_random[i][27];
		// assign feedback_bit_random[i][29]  = reg_curr[i+2]  ^ feedback_bit_random[i][7]  ^ feedback_bit_random[i][27] ^ feedback_bit_random[i][28];
		// assign feedback_bit_random[i][30]  = reg_curr[i+1]  ^ feedback_bit_random[i][8]  ^ feedback_bit_random[i][28] ^ feedback_bit_random[i][29];
		// assign feedback_bit_random[i][31]  = reg_curr[i+0]  ^ feedback_bit_random[i][9]  ^ feedback_bit_random[i][29] ^ feedback_bit_random[i][30];

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

		
		// assign reg_next[(i*32)+: 32] <= {feedback_bit_0[i], feedback_bit_10[i], feedback_bit_4[i], feedback_bit_14[i], feedback_bit_6[i], feedback_bit_8[i], feedback_bit_16[i], feedback_bit_3[i], feedback_bit_29[i],
		// 						feedback_bit_12[i], feedback_bit_22[i], feedback_bit_7[i], feedback_bit_11[i], feedback_bit_15[i], feedback_bit_5[i], feedback_bit_13[i], feedback_bit_1[i], feedback_bit_19[i],
		// 						feedback_bit_17[i], feedback_bit_24[i], feedback_bit_20[i], feedback_bit_28[i], feedback_bit_29[i], feedback_bit_30[i], feedback_bit_23[i], feedback_bit_27[i], feedback_bit_26[i],
		// 						feedback_bit_31[i], feedback_bit_18[i], feedback_bit_25[i], feedback_bit_22[i], feedback_bit_21[i]};				
	end
				
endgenerate




always @(*)
begin
	if(~rst_n) 
	begin
		slide_bit = 'd0;
		pre_reg_next = 'd0;
		post_reg_next = 'd0;
		feedback_bit = 'd0;
		valid_next = 'b0;
		reg_next = 'd0;
	end
	
	else
	begin 

		if (load_pattern)
		begin 
			//reg_next = {pattern,reg_next[0:638]};
			reg_next = reg_curr;
			
		end 
		else
		begin 

			case (mask_type)

				1'b0: // Sliding Pattern
				begin 

					valid_next = 1'b1;

					for (int i = 0; i < 32; i++)
					begin 
				
						if (right_sliding) // Shift Right
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
						else // Shift Left
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

				end

				1'b1: // Random Pattern: Fibonacci random number generator
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
				
				default: // Sliding Pattern
				begin 
					valid_next = 1'b1;

					for (int i = 0; i < 32; i++)
					begin 
				
						if (right_sliding) // Shift Right
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
						else // Shift Left
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
		 mg_mask_n ='d0;
		 pre_reg_curr ='d0;
		 post_reg_curr ='d0;
		 seedLoaded = 'd0;
	end 
	else if(clk_en)
	begin

		if (load_pattern)
		begin

			reg_curr = {pattern,reg_curr[0:638]};
			//reg_curr[0:31] = pattern;
			//reg_curr[32:640-1] ='d0;
			rp_valid=1'd0;
			seedCounter = 'd0;
        	pre_reg_curr ='d0;
        	post_reg_curr ='d0;
	       
		end
		else
		begin

			pre_reg_curr =pre_reg_next;
			post_reg_curr =post_reg_next;

			
			rp_valid = valid_next;

			// Controlling the time for outputing the mg_mask
			case (mask_type)

				1'b0: // Sliding Pattern
				begin
					reg_curr = reg_next;
					mg_mask = reg_curr;
					mg_mask_n = ~reg_curr;
				end

				1'b1: // Random Pattern: Fibonacci random number generator
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
						mg_mask_n =~reg_curr;
						// seedCounter = 'd0;
						seedLoaded  = 1'b1; 
					end

				end
		
				default : // Sliding Pattern
				begin
					reg_curr = reg_next;
					mg_mask = reg_curr;
					mg_mask_n = ~reg_curr;

				end
			endcase

		end

	end
end



endmodule