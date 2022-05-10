module mask_gen_VGA_tb ();

	function void close_file(int fd);
		if (!fd) 
		begin
			$fflush(fd);
			$fclose(fd);
		end
	endfunction

	logic clk;
	logic clk_en;
	logic rst_n;

	logic [4:0] pattern_w;
	logic pattern;
	logic [7:0] repeatedPattern;
	logic load_pattern;

	logic [1:0] mask_type;

	logic [0:639] mg_mask;
	logic rp_valid;
	
    mask_generation_VGA uut (.*);
	
    // Clock Generation
    localparam h_period = 5;
    localparam period = 10;
    always
    begin
        clk = 1'b1;
        #h_period;
            
        clk = 1'b0;
        #h_period;
    end
	
	// Testcase read/related
	int fd_tests = $fopen("../testcase_raws/vga_testcases.txt", "r");
	int read_test = 0;
	string line;
	logic [0:31] full_pattern;
	logic [0:639] mg_mask_sliding_init_state;
	
	int fd_tests_raw_output = $fopen("../testcase_raws/vga_testcases_hw_output.txt", "w");
	
	int fd_tests_summary = 0;
	
	// Done logic
	int num_rows_done = 0;	// Max up to 480 rows 
	int done = 0;
	int ret;
	
    initial
    begin 
        clk_en = 1'b1;
        rst_n = 1'b0;
		#(period);
        rst_n = 1'b1;
		
		while($fgets(line, fd_tests))
		begin
			if(line.match("(\/\/.*)?$")) 
				line = line.prematch();
			if (!line.match("[0-f]")) 
				continue;
			full_pattern = 32'h0;
			mg_mask_sliding_init_state = 640'h0;
			read_test = $sscanf(line, "%b %b %b %h\n", mask_type, pattern_w, repeatedPattern, full_pattern);
			if (read_test != 4) // Number corresponds to number of properly read variables
			begin
				$display("Malformed testcase: %s\n", line);
				$display("Please provide in the following order: mask_type (2'b, eg. 01), pattern_w (5'b, eg. 01011), repeatedPattern (8'b, eg. 10101111), pattern (32'h, max len 32 (8 hex characters/half-bytes) for sliding/random (ie. mask_type = 00, 01 / 10) eg. 03D0A052)\n");
				$display("Skipping testcase ... \n");
				continue;
			end
			
			$fwrite(fd_tests_raw_output, line);
			$fwrite(fd_tests_raw_output, "\n");
			$fwrite(fd_tests_raw_output, "Output start:\n");
		
			rst_n = 1'b0;
			#(period);
			rst_n = 1'b1;
			done = 0;		
			
			case (mask_type)
				
				2'b11:  // Repeated Pattern
				begin
					load_pattern = 1'b1;
					#(period);
					load_pattern = 1'b0;
				end
				
				default: // Sliding right, left, Random
				begin
					mg_mask_sliding_init_state = {full_pattern, {640-32{1'b0}}};
					if (mask_type == 2'b00 || mask_type == 2'b01)
					begin
						$fwrite(fd_tests_raw_output, "%h\n", mg_mask_sliding_init_state);
					end
					
					for (int i = 31; i >= 0; i--) // Do sliding right/left only need to load in the specified length?
					begin
						pattern = full_pattern[i];
						load_pattern = 1'b1;
						#(period);
						load_pattern = 1'b0;
					end
				end
			endcase
			
			while (!done) 
			begin
				#(period);   
			end
		end
		
        rst_n = 1'b0;
		#(period);
		
		$fwrite(fd_tests_raw_output, "End\n");
			
		close_file(fd_tests);
		close_file(fd_tests_raw_output);
		close_file(fd_tests_summary);
		
		
		$stop(0);
	
    end
	
	always @(negedge clk) 
	begin
		if (rp_valid)
		begin
			$fwrite(fd_tests_raw_output, "%h\n", mg_mask);
			case (mask_type)
				2'b00, 2'b01: // Sliding right and left
				begin
					if (mg_mask == mg_mask_sliding_init_state)
					begin
						done = 1;
						$fwrite(fd_tests_raw_output, "Output end\n");
					end
				end
				
				2'b11:  // Repeated Pattern
				begin
					done = 1;
					$fwrite(fd_tests_raw_output, "Output end\n");
				end
				
				default : // Random Pattern
				begin
					if (num_rows_done == 480)	// Cycles needed for one frame
					begin
						num_rows_done = 0;
						
						done = 1;
						$fwrite(fd_tests_raw_output, "Output end\n");
					end
					else
					begin
						num_rows_done = num_rows_done + 1;
					end
				end
			endcase
			
			$fflush(fd_tests_raw_output);
		end
	end
endmodule
