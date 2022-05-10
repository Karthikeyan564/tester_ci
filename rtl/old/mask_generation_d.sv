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

module mask_generation 
#(
	parameter max_image_sensor_w = 1920, 	// Max Width of the image sensor = 1920 (FHD)
	parameter max_image_sensor_h = 1080  	// Max Height of the image sensor = 1080 (FHD)		
	//parameter max_num_subframes = 1000   // Max Number of Subframes = 1000
 )
(
	input clk,    // Clock
	input clk_en, // Clock Enable
	input rst_n,  // Asynchronous reset active low

	// Image Sensor Signals

	input [10:0] image_sensor_w, // Width of the image sensor
	input [10:0] image_sensor_h, // Height of the image sensor
//	input [9:0]  num_subframes,  // Number of subframes

	// Pattern Input passed through the micro-processor

	input [4:0] pattern_w, // size of the pattern W 
	input [0:31] pattern,	// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	input right_sliding,	// Direction of sliding 1-- right / 0 -- left
	input load_pattern, // to load the pattern for repetition


	input [1:0] mask_type,	// Choose the type of mask between  Repeated pattern 00 - sliding pattern 01 - Random Mask 10 

	//input rp_ready, // Ready signal for the module to verify the input

	//output logic rp_mask_bit, // output of the repeated mask bit by bit
	output logic [0:max_image_sensor_w-1] mg_mask, 
	output logic rp_valid // Valid signal for the output
);

	// (LSB) 0 1 2 3 4 ..... 299(e.g.) (MSB)
	logic [0:max_image_sensor_w-1] reg_curr, reg_next;
	logic [0:31]stored_pattern;
    
	logic [0:31]LFSR_seed;					// LFSR used to generate seeds in the first 60 clock cycles
	logic [0:31]LFSRs[0:59];				// LFSRs used to generate pseudorandom rows using permutations of their state
	
	// feedback bits used in random pattern generation
	logic feedback_bit_0, feedback_bit_1, feedback_bit_2, feedback_bit_3, feedback_bit_4, feedback_bit_5, feedback_bit_6, feedback_bit_7, feedback_bit_8, feedback_bit_9, feedback_bit_10, feedback_bit_11,
		  feedback_bit_12, feedback_bit_13, feedback_bit_14, feedback_bit_15, feedback_bit_16, feedback_bit_17, feedback_bit_18, feedback_bit_19, feedback_bit_20, feedback_bit_21, feedback_bit_22, feedback_bit_23, 
		  feedback_bit_24, feedback_bit_25, feedback_bit_26, feedback_bit_27, feedback_bit_28, feedback_bit_29, feedback_bit_30, feedback_bit_31;
	
	logic valid_next, valid_mid;
	logic feedback_bit, seed_done;

	logic [21:0] counter; 					// counter for repeating the pattern across multiple columns based on the image_sensor_w
	integer counter_random = 0;				// counter used to generate seeds for LFSRs and pseudorandom masks
	//logic [21:0] counter_subframes; 		// Counter for outputing the pattern up to number of subframes x image_sensor_h
	

	// Registers for Sliding Pattern
	logic [0:31] temp_reg_curr,temp_reg_next,LFSR_curr,LFSR_next;
	logic slide_bit;
	localparam N = 60;                      // Number of seeds needed to be generated for the LFSRs by LFSR_seed


always @(*)
begin
	case (mask_type)

		2'b00: // Repeated Pattern
		begin 

			for (int i = 0; i < 32; i++) begin

				if(pattern_w == (i+1))
				begin 
					feedback_bit = reg_curr[i];	
				end
					
			end


			if (counter < image_sensor_w)
			begin
				reg_next = {feedback_bit,reg_curr[0:max_image_sensor_w-2]};
				valid_next =1'b0;
			end
			else
				valid_next =1'b1;		

		end

		2'b01: // Sliding Pattern
		begin 
            
            // set the next register as valid
			valid_next = 1'b1;

			for (int i = 0; i < max_image_sensor_w; i++)
			begin 
		
				if (right_sliding) // Shift Right
				begin

					// Define the Sliding bit to the extra post reg
					if(image_sensor_w == (i+1))
					begin
					
						slide_bit = reg_curr[i];
						temp_reg_next = {slide_bit,temp_reg_curr[0:30]};

					end

					// Define the feedback bit to slide the pattern right
					if(pattern_w == (i+1))
					begin 

						feedback_bit = temp_reg_curr[i];
						reg_next = {feedback_bit, reg_curr[0:max_image_sensor_w-2]};

					end
				
				end
				else // Shift Left
				begin

					// Update the next template register
					if (pattern_w == (i + 1))
					begin 

						// save the bit to be slided out of the row
						slide_bit = reg_curr[0];
						// shift and save the slided bit in the next template register
						temp_reg_next = temp_reg_curr << 1;
						temp_reg_next[i] = slide_bit;
                        
					end
					
                    // Carry out sliding and feedback
                    if (image_sensor_w == (i+1))
                    begin
                        
						// save the feedback bit for left shifting as the first entry in the current state
						feedback_bit = temp_reg_curr[0];
						// slide and feedback in the correct index
						reg_next = reg_curr << 1;
						reg_next[i] = feedback_bit;	
                        
                    end
				end

			end

		end

		2'b10: // Random Pattern: Fibonacci 
		begin 
			if(seed_done)
			begin
				// calculate feedback bits for each LFSR and update them to the next state
				for (counter_random = 0; counter_random < N; counter_random = counter_random + 1)
				begin
					
					if (counter_random == 0)
					begin
						LFSRs[counter_random] = LFSR_curr;
					end
					
					// calculate feedback bits using a single feedback polynomial
					feedback_bit_0 = LFSRs[counter_random][31]^LFSRs[counter_random][21]^LFSRs[counter_random][1]^LFSRs[counter_random][0];
					feedback_bit_1 = LFSRs[counter_random][30]^LFSRs[counter_random][20]^LFSRs[counter_random][0]^feedback_bit_0;
					feedback_bit_2 = LFSRs[counter_random][29]^LFSRs[counter_random][19]^feedback_bit_0^feedback_bit_1;
					feedback_bit_3 = LFSRs[counter_random][28]^LFSRs[counter_random][18]^feedback_bit_1^feedback_bit_2;
					feedback_bit_4 = LFSRs[counter_random][27]^LFSRs[counter_random][17]^feedback_bit_2^feedback_bit_3;
					feedback_bit_5 = LFSRs[counter_random][26]^LFSRs[counter_random][16]^feedback_bit_3^feedback_bit_4;
					feedback_bit_6 = LFSRs[counter_random][25]^LFSRs[counter_random][15]^feedback_bit_4^feedback_bit_5;
					feedback_bit_7 = LFSRs[counter_random][24]^LFSRs[counter_random][14]^feedback_bit_5^feedback_bit_6;
					feedback_bit_8 = LFSRs[counter_random][23]^LFSRs[counter_random][13]^feedback_bit_6^feedback_bit_7;
					feedback_bit_9 = LFSRs[counter_random][22]^LFSRs[counter_random][12]^feedback_bit_7^feedback_bit_8;
					feedback_bit_10 = LFSRs[counter_random][21]^LFSRs[counter_random][11]^feedback_bit_8^feedback_bit_9;
					feedback_bit_11 = LFSRs[counter_random][20]^LFSRs[counter_random][10]^feedback_bit_9^feedback_bit_10;
					feedback_bit_12 = LFSRs[counter_random][19]^LFSRs[counter_random][9]^feedback_bit_10^feedback_bit_11;
					feedback_bit_13 = LFSRs[counter_random][18]^LFSRs[counter_random][8]^feedback_bit_11^feedback_bit_12;
					feedback_bit_14 = LFSRs[counter_random][17]^LFSRs[counter_random][7]^feedback_bit_12^feedback_bit_13;
					feedback_bit_15 = LFSRs[counter_random][16]^LFSRs[counter_random][6]^feedback_bit_13^feedback_bit_14;
					feedback_bit_16 = LFSRs[counter_random][15]^LFSRs[counter_random][5]^feedback_bit_14^feedback_bit_15;
					feedback_bit_17 = LFSRs[counter_random][14]^LFSRs[counter_random][4]^feedback_bit_15^feedback_bit_16;
					feedback_bit_18 = LFSRs[counter_random][13]^LFSRs[counter_random][3]^feedback_bit_16^feedback_bit_17;
					feedback_bit_19 = LFSRs[counter_random][12]^LFSRs[counter_random][2]^feedback_bit_17^feedback_bit_18;
					feedback_bit_20 = LFSRs[counter_random][11]^LFSRs[counter_random][1]^feedback_bit_18^feedback_bit_19;
					feedback_bit_21 = LFSRs[counter_random][10]^LFSRs[counter_random][0]^feedback_bit_19^feedback_bit_20;
					feedback_bit_22 = LFSRs[counter_random][9]^feedback_bit_0^feedback_bit_20^feedback_bit_21;
					feedback_bit_23 = LFSRs[counter_random][8]^feedback_bit_1^feedback_bit_21^feedback_bit_22;
					feedback_bit_24 = LFSRs[counter_random][7]^feedback_bit_2^feedback_bit_22^feedback_bit_23;
					feedback_bit_25 = LFSRs[counter_random][6]^feedback_bit_3^feedback_bit_23^feedback_bit_24;
					feedback_bit_26 = LFSRs[counter_random][5]^feedback_bit_4^feedback_bit_24^feedback_bit_25;
					feedback_bit_27 = LFSRs[counter_random][4]^feedback_bit_5^feedback_bit_25^feedback_bit_26;
					feedback_bit_28 = LFSRs[counter_random][3]^feedback_bit_6^feedback_bit_26^feedback_bit_27;
					feedback_bit_29 = LFSRs[counter_random][2]^feedback_bit_7^feedback_bit_27^feedback_bit_28;
					feedback_bit_30 = LFSRs[counter_random][1]^feedback_bit_8^feedback_bit_28^feedback_bit_29;
					feedback_bit_31 = LFSRs[counter_random][0]^feedback_bit_9^feedback_bit_29^feedback_bit_30;
					
														  
					if (counter_random == N - 1)
					begin
						
						// save the next seed at LFSR_next to be loaded in LFSR_curr in the next clock cycle
						LFSR_next = {feedback_bit_31, feedback_bit_30, feedback_bit_29, feedback_bit_28, feedback_bit_27, feedback_bit_26, feedback_bit_25, feedback_bit_24, feedback_bit_23,
									feedback_bit_22, feedback_bit_21, feedback_bit_20, feedback_bit_19, feedback_bit_18, feedback_bit_17, feedback_bit_16, feedback_bit_15, feedback_bit_14,
									feedback_bit_13, feedback_bit_12, feedback_bit_11, feedback_bit_10, feedback_bit_9, feedback_bit_8, feedback_bit_7, feedback_bit_6, feedback_bit_5,
									feedback_bit_4, feedback_bit_3, feedback_bit_2, feedback_bit_1, feedback_bit_0};
									 
						// populate reg_next accordingly
						reg_next[((N-counter_random-1)*32)+: 32] = {feedback_bit_0, feedback_bit_10, feedback_bit_4, feedback_bit_14, feedback_bit_6, feedback_bit_8, feedback_bit_16, feedback_bit_3, feedback_bit_29,
																	feedback_bit_12, feedback_bit_22, feedback_bit_7, feedback_bit_11, feedback_bit_15, feedback_bit_5, feedback_bit_13, feedback_bit_1, feedback_bit_19,
																	feedback_bit_17, feedback_bit_24, feedback_bit_20, feedback_bit_28, feedback_bit_29, feedback_bit_30, feedback_bit_23, feedback_bit_27, feedback_bit_26,
																	feedback_bit_31, feedback_bit_18, feedback_bit_25, feedback_bit_22, feedback_bit_21};
									
					end
					else
					begin
					
						// update the LFSR
						LFSRs[counter_random + 1] = {feedback_bit_31, feedback_bit_30, feedback_bit_29, feedback_bit_28, feedback_bit_27, feedback_bit_26, feedback_bit_25, feedback_bit_24, feedback_bit_23,
													feedback_bit_22, feedback_bit_21, feedback_bit_20, feedback_bit_19, feedback_bit_18, feedback_bit_17, feedback_bit_16, feedback_bit_15, feedback_bit_14,
													feedback_bit_13, feedback_bit_12, feedback_bit_11, feedback_bit_10, feedback_bit_9, feedback_bit_8, feedback_bit_7, feedback_bit_6, feedback_bit_5,
													feedback_bit_4, feedback_bit_3, feedback_bit_2, feedback_bit_1, feedback_bit_0}; 
					
						// populate reg_next accordingly
						reg_next[((N-counter_random-1)*32)+: 32] = {feedback_bit_0, feedback_bit_10, feedback_bit_4, feedback_bit_14, feedback_bit_6, feedback_bit_8, feedback_bit_16, feedback_bit_3, feedback_bit_29,
																	feedback_bit_12, feedback_bit_22, feedback_bit_7, feedback_bit_11, feedback_bit_15, feedback_bit_5, feedback_bit_13, feedback_bit_1, feedback_bit_19,
																	feedback_bit_17, feedback_bit_24, feedback_bit_20, feedback_bit_28, feedback_bit_29, feedback_bit_30, feedback_bit_23, feedback_bit_27, feedback_bit_26,
																	feedback_bit_31, feedback_bit_18, feedback_bit_25, feedback_bit_22, feedback_bit_21};
					end
				
				end
				
				valid_next <= 1'b1;
				
			end
			
		end
		
		default: // Repeating Pattern
		begin 

			for (int i = 0; i < 32; i++) begin

				if(pattern_w == (i+1))
				begin 
					feedback_bit = reg_curr[i];	
				end
				
			end

			if (counter < image_sensor_w)
			begin
				reg_next = {feedback_bit,reg_curr[0:max_image_sensor_w-2]};
				valid_next =1'b1;
			end
			else
				valid_next =1'b0;		

		end

	endcase

end

always_ff @(posedge clk or negedge rst_n) 
begin

	if(~rst_n) 
	begin
		 //rp_mask_bit<= 'd0;
		 rp_valid <= 1'b0;
		 valid_mid <= 1'b0;
		 reg_curr <= 'd0;
		 counter <= 'd0;
		 mg_mask <= 'd0;
		 temp_reg_curr <= 'd0;
		 LFSR_curr <= 32'd0;
		 LFSR_next <= 32'd0;
		 seed_done <= 1'b0;
		 LFSR_seed <= 32'd0;
		 counter_random <= 0;
		 valid_next <= 1'b0;
//		 counter_subframes <= 'd0;
	end 
	else if(clk_en)
	begin

		if (load_pattern)
		begin

			stored_pattern = pattern;
			reg_curr[0:31] = pattern;
            LFSR_curr = pattern;
            LFSR_next = pattern;
			LFSR_seed = pattern;
			seed_done <= 1'b0;
			reg_curr[32:max_image_sensor_w-1] = 'd0;
			rp_valid = 1'd0;
			valid_next = 1'b0;
			valid_mid = 1'b0;
			counter = 'd0;
			counter_random = 0;
        	temp_reg_curr = 'd0;
//        	counter_subframes <='d0;
	       
		end
		else
		begin


			reg_curr <= reg_next;
			LFSR_curr <= LFSR_next;
			temp_reg_curr <= temp_reg_next;

			// Output the 1-bit for the mask pixel by pixel
			// case (mask_type)
			// 	2'b00: // Repeated Pattern
			// 	begin 
			// 		//rp_mask_bit <= feedback_bit;
			// 	end

			// 	2'b01: // Sliding Pattern
			// 	begin 

			// 		mg_mask <= reg_curr;
			// 		// if(right_sliding)
			// 		// 	rp_mask_bit <= reg_curr[image_sensor_w-1];
			// 		// else
			// 		// 	rp_mask_bit <= reg_curr[0];
			// 	end
		
			// 	default : rp_mask_bit <= feedback_bit;
			// endcase

		// Controlling the time for outputing the mg_mask
			case (mask_type)
				2'b00: // Repeated Pattern
				begin 
						
					if (counter < image_sensor_w)
					begin 

						counter = counter + 22'd1;
						rp_valid <=1'b0;

					end 
					else
					begin 
						mg_mask <= reg_curr;
						rp_valid <= valid_next;
					end
						
				end

				2'b01: // Sliding Pattern
				begin

					mg_mask <= reg_curr;
					rp_valid <= valid_next;

					// if (counter_subframes < num_subframes)
					// 	counter_subframes = counter_subframes + 22'd1;

					// If you want to reset the pattern after reaching the max subframes
					// else
					// begin 

					// 	counter_subframes = 'd0; 
					// 	reg_curr[0:31] <= pattern;
					// 	reg_curr[32:max_image_sensor_w-1] <='d0;

					// end



				end

				2'b10: // Random Pattern: Fibonacci random number generator
				begin 
				
					// check if all 60 seeds needed to create pseudorandom rows have been generated
					if (seed_done)
					begin
					
						mg_mask <= reg_curr;
						valid_mid <= valid_next;
			            rp_valid <= valid_mid;
						
					end
					else
					begin
						
						if (counter_random < N) 
						begin
						
							// shift and feedback in the LFSR
							LFSR_seed = {(LFSR_seed[31]^LFSR_seed[21]^LFSR_seed[1]^LFSR_seed[0]),LFSR_seed[0:30]};
							
							// load the seed to the respective LFSR
							LFSRs[counter_random] = {LFSR_seed[0], LFSR_seed[23], LFSR_seed[10],  LFSR_seed[25], LFSR_seed[4], LFSR_seed[19], LFSR_seed[14],
													 LFSR_seed[6], LFSR_seed[21], LFSR_seed[8], LFSR_seed[30], LFSR_seed[16], LFSR_seed[18], LFSR_seed[3], 
													 LFSR_seed[9], LFSR_seed[26], LFSR_seed[12], LFSR_seed[28], LFSR_seed[7], LFSR_seed[31], LFSR_seed[15], 
													 LFSR_seed[5], LFSR_seed[13], LFSR_seed[1], LFSR_seed[24], LFSR_seed[29], LFSR_seed[17], LFSR_seed[20], 
													 LFSR_seed[22], LFSR_seed[27], LFSR_seed[2], LFSR_seed[11]};
													 
							// set rp_valid to 0 until the generation begins
							rp_valid = 1'b0;
							
							// increment counter_random
							counter_random = counter_random + 1;
						
						end
						else if (counter_random == N)
						begin
						
							// all seeds have been generated --> ready to generate pseudorandom rows of length
							seed_done = 1'b1;
							
							//set rp_valid to 0 until generation begins in the next clock cycle
							rp_valid = 1'b0;
							
						end
					end
					
				end
		
				default : 
				begin

					if (counter < image_sensor_w) 
						counter = counter + 22'd1;
					else
					begin 
					   mg_mask <=reg_curr;
						counter = 'd0;
					end

				end
			endcase

		end

	end
end



endmodule