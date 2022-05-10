import re
from utils import convert_hexstring_to_bin_list
from utils import convert_binstring_to_bin_list
from utils import convert_bin_list_to_hexstring
import sys

def main():
    print("Running version:" + sys.version)

    with open("../testcase_raws/vga_testcases.txt", "r") as fd_tests:
        fd_tests_raw_output = open("../testcase_raws/vga_testcases_sw_output.txt", "w")
        
        testcases = fd_tests.readlines()
        for testcase in testcases:
            if re.match("(\/\/.*)?$", testcase) or not re.match("[0-f]", testcase):
                continue
            
            inputs = testcase.strip().split(" ")
            mask_type_dec = int(inputs[0], 2)
            pattern_w = inputs[1]
            repeatedPattern = inputs[2]
            full_pattern = inputs[3]
            
            pattern_w_dec = int(pattern_w, 2)
            repeatedPattern_dec = int(repeatedPattern, 2)
            
            pattern_w_bits = []
            repeatedPattern_bits = []
            full_pattern_bits = []
            
            convert_binstring_to_bin_list(pattern_w, pattern_w_bits)
            pattern_w_bits.reverse()
            convert_binstring_to_bin_list(repeatedPattern, repeatedPattern_bits)
            repeatedPattern_bits.reverse()
            convert_hexstring_to_bin_list(full_pattern, full_pattern_bits)
            full_pattern_bits.reverse()
            
            # Checking if testcases are valid
            if mask_type_dec < 0 or mask_type_dec > 3:
                print("Malformed testcase ({}), mask_type out of range".format(testcase))
            if mask_type_dec == 0 or mask_type_dec == 1:
                if pattern_w_dec <= 0 or pattern_w_dec >= 32:
                    print("Malformed testcase ({}), sliding pattern_w out of range".format(testcase))
            if mask_type_dec == 3:
                if repeatedPattern_dec == 0:
                    print("Warning, testcase ({}) for repeated pattern has no repeatedPattern set".format(testcase))
            
            fd_tests_raw_output.write("{} {} {} {}\n".format(inputs[0], inputs[1], inputs[2], inputs[3]))
            fd_tests_raw_output.write("Output start:\n")
            
            mg_mask = []
            
            if mask_type_dec == 0 or mask_type_dec == 1: # 2'b00 (right), 2'b01 (left) Sliding pattern
                # Loading
                counter = 0
                full_pattern_index = 32
                buffer = []
                while counter < 640:
                    if full_pattern_index > 0:
                        buffer.append(0)
                        mg_mask.append(full_pattern_bits[full_pattern_index-1])
                        full_pattern_index -= 1
                    else:
                        mg_mask.append(0)
                    counter += 1
                
                mg_mask_string_initial = convert_bin_list_to_hexstring(mg_mask)
                fd_tests_raw_output.write("{}\n".format(mg_mask_string_initial))
                
                done_shifting = False
                
                while not done_shifting:
                    if mask_type_dec == 0: # Shifting right, shfiting values to higher index values in mg_mask
                        msb_buffer = buffer[pattern_w_dec-1]
                        for index in range(pattern_w_dec-1, 0, -1):
                            buffer[index] = buffer[index-1]
                        #buffer[1:pattern_w_dec-1] = buffer[0:pattern_w_dec-2]
                        
                        buffer[0] = mg_mask[639]
                        
                        for index in range(639, 0, -1):
                            mg_mask[index] = mg_mask[index-1]
                        #mg_mask[1:639] = buffer[0:638]
                        
                        mg_mask[0] = msb_buffer
                    
                    else: # Shifting left
                        lsb_buffer = buffer[0]
                        
                        for index in range(0, pattern_w_dec-1, 1):
                            buffer[index] = buffer[index+1]
                        #buffer[0:pattern_w_dec-2] = buffer[1:pattern_w_dec-1]
                        
                        buffer[pattern_w_dec-1] = mg_mask[0]
                        
                        for index in range(0, 639, 1):
                            mg_mask[index] = mg_mask[index+1]    
                        #mg_mask[0:638] = buffer[1:639]
                        
                        mg_mask[639] = lsb_buffer
                    
                    mg_mask_string = convert_bin_list_to_hexstring(mg_mask)
                    fd_tests_raw_output.write("{}\n".format(mg_mask_string))
                    
                    if mg_mask_string == mg_mask_string_initial:
                        done_shifting = True
                        
            elif mask_type_dec == 2: # 2'b10 Random pattern
                
                counter = 0
                full_pattern_index = 32
                mg_mask_prev = []
                while counter < 640:
                    if full_pattern_index > 0:
                        mg_mask_prev.append(full_pattern_bits[full_pattern_index-1])
                        full_pattern_index -= 1
                    else:
                        mg_mask_prev.append(0)
                    counter += 1
                    
                feedback_bit_random = []
                for _ in range(0, 20, 1):
                    temp = []
                    for _ in range(0, 32, 1):
                        temp.append(0)
                    feedback_bit_random.append(temp)
                    
                num_of_rows_done = 0
                skip = 2 # To skip one cycle in the beginning to align with hardware, skip another because the first line is not written to file in time in testbench
                while num_of_rows_done <= (480+2):
                    for i in range(0, 20, 1):
                        feedback_bit_random[i][0]   = mg_mask_prev[i+31] ^ mg_mask_prev[i+21]  ^  mg_mask_prev[i+1]   ^ mg_mask_prev[i+0];
                        feedback_bit_random[i][1]   = mg_mask_prev[i+30] ^ mg_mask_prev[i+20]  ^  mg_mask_prev[i+0]   ^ mg_mask_prev[i+16];
                        feedback_bit_random[i][2]   = mg_mask_prev[i+29] ^ mg_mask_prev[i+19]  ^  mg_mask_prev[i+2]   ^ mg_mask_prev[i+15];
                        feedback_bit_random[i][3]   = mg_mask_prev[i+28] - mg_mask_prev[i+18]  ^  mg_mask_prev[i+3]   ^ mg_mask_prev[i+14];
                        feedback_bit_random[i][4]   = mg_mask_prev[i+27] ^ mg_mask_prev[i+17]  ^  mg_mask_prev[i+4]   ^ mg_mask_prev[i+13];
                        feedback_bit_random[i][5]   = mg_mask_prev[i+26] ^ mg_mask_prev[i+16]  ^  mg_mask_prev[i+5]   ^ mg_mask_prev[i+12];
                        feedback_bit_random[i][6]   = mg_mask_prev[i+25] ^ mg_mask_prev[i+15]  ^  mg_mask_prev[i+6]   ^ mg_mask_prev[i+11];
                        feedback_bit_random[i][7]   = mg_mask_prev[i+24] ^ mg_mask_prev[i+14]  ^  mg_mask_prev[i+7]   ^ mg_mask_prev[i+10];
                        feedback_bit_random[i][8]   = mg_mask_prev[i+23] ^ mg_mask_prev[i+13]  ^  mg_mask_prev[i+8]   ^ mg_mask_prev[i+1];
                        feedback_bit_random[i][9]   = mg_mask_prev[i+22] ^ mg_mask_prev[i+12]  ^  mg_mask_prev[i+9]   ^ mg_mask_prev[i+2];
                        feedback_bit_random[i][10]  = mg_mask_prev[i+21] ^ mg_mask_prev[i+11]  ^  mg_mask_prev[i+20]  ^ mg_mask_prev[i+3];
                        feedback_bit_random[i][11]  = mg_mask_prev[i+20] ^ mg_mask_prev[i+10]  ^  mg_mask_prev[i+21]  ^ mg_mask_prev[i+4];
                        feedback_bit_random[i][12]  = mg_mask_prev[i+19] ^ mg_mask_prev[i+9]   ^  mg_mask_prev[i+22]  ^ mg_mask_prev[i+5];
                        feedback_bit_random[i][13]  = mg_mask_prev[i+18] ^ mg_mask_prev[i+8]   ^  mg_mask_prev[i+23]  ^ mg_mask_prev[i+6];
                        feedback_bit_random[i][14]  = mg_mask_prev[i+17] ^ mg_mask_prev[i+7]   ^  mg_mask_prev[i+24]  ^ mg_mask_prev[i+30];
                        feedback_bit_random[i][15]  = mg_mask_prev[i+16] ^ mg_mask_prev[i+6]   ^  mg_mask_prev[i+25]  ^ mg_mask_prev[i+29];
                        feedback_bit_random[i][16]  = mg_mask_prev[i+15] ^ mg_mask_prev[i+5]   ^  mg_mask_prev[i+26]  ^ mg_mask_prev[i+28];
                        feedback_bit_random[i][17]  = mg_mask_prev[i+14] ^ mg_mask_prev[i+4]   ^  mg_mask_prev[i+27]  ^ mg_mask_prev[i+27];
                        feedback_bit_random[i][18]  = mg_mask_prev[i+13] ^ mg_mask_prev[i+3]   ^  mg_mask_prev[i+31]  ^ mg_mask_prev[i+26];
                        feedback_bit_random[i][19]  = mg_mask_prev[i+12] ^ mg_mask_prev[i+2]   ^  mg_mask_prev[i+29]  ^ mg_mask_prev[i+25];
                        feedback_bit_random[i][20]  = mg_mask_prev[i+11] ^ mg_mask_prev[i+1]   ^  mg_mask_prev[i+30]  ^ mg_mask_prev[i+24];
                        feedback_bit_random[i][21]  = mg_mask_prev[i+10] ^ mg_mask_prev[i+0]   ^  mg_mask_prev[i+10]  ^ mg_mask_prev[i+23];
                        feedback_bit_random[i][22]  = mg_mask_prev[i+9]  ^ mg_mask_prev[i+31]  ^  mg_mask_prev[i+28]  ^ mg_mask_prev[i+22];
                        feedback_bit_random[i][23]  = mg_mask_prev[i+8]  ^ mg_mask_prev[i+30]  ^  mg_mask_prev[i+11]  ^ mg_mask_prev[i+21];
                        feedback_bit_random[i][25]  = mg_mask_prev[i+6]  ^ mg_mask_prev[i+29]  ^  mg_mask_prev[i+12]  ^ mg_mask_prev[i+20];
                        feedback_bit_random[i][26]  = mg_mask_prev[i+5]  ^ mg_mask_prev[i+28]  ^  mg_mask_prev[i+13]  ^ mg_mask_prev[i+19];
                        feedback_bit_random[i][27]  = mg_mask_prev[i+4]  ^ mg_mask_prev[i+27]  ^  mg_mask_prev[i+14]  ^ mg_mask_prev[i+18];
                        feedback_bit_random[i][24]  = mg_mask_prev[i+7]  ^ mg_mask_prev[i+26]  ^  mg_mask_prev[i+15]  ^ mg_mask_prev[i+17];
                        feedback_bit_random[i][28]  = mg_mask_prev[i+3]  ^ mg_mask_prev[i+25]  ^  mg_mask_prev[i+16]  ^ mg_mask_prev[i+9];
                        feedback_bit_random[i][29]  = mg_mask_prev[i+2]  ^ mg_mask_prev[i+24]  ^  mg_mask_prev[i+17]  ^ mg_mask_prev[i+8];
                        feedback_bit_random[i][30]  = mg_mask_prev[i+1]  ^ mg_mask_prev[i+23]  ^  mg_mask_prev[i+18]  ^ mg_mask_prev[i+6];
                        feedback_bit_random[i][31]  = mg_mask_prev[i+0]  ^ mg_mask_prev[i+22]  ^  mg_mask_prev[i+19]  ^ mg_mask_prev[i+7];
                        
                        mg_mask[(i*32):(i*32)+32] = [
                            feedback_bit_random[i][0], feedback_bit_random[i][10], feedback_bit_random[i][4], 
                            feedback_bit_random[i][14], feedback_bit_random[i][6], feedback_bit_random[i][8], 
                            feedback_bit_random[i][16], feedback_bit_random[i][3], feedback_bit_random[i][29],
                            feedback_bit_random[i][12], feedback_bit_random[i][22], feedback_bit_random[i][7], 
                            feedback_bit_random[i][11], feedback_bit_random[i][15], feedback_bit_random[i][5], 
                            feedback_bit_random[i][13], feedback_bit_random[i][1], feedback_bit_random[i][19],
                            feedback_bit_random[i][17], feedback_bit_random[i][24], feedback_bit_random[i][20],
                            feedback_bit_random[i][28], feedback_bit_random[i][29], feedback_bit_random[i][30], 
                            feedback_bit_random[i][23], feedback_bit_random[i][27], feedback_bit_random[i][26],
                            feedback_bit_random[i][31], feedback_bit_random[i][18], feedback_bit_random[i][25], 
                            feedback_bit_random[i][22], feedback_bit_random[i][21]
                        ]
                    
                    
                    num_of_rows_done += 1
                    mg_mask_prev = mg_mask[:]
                    
                    if skip > 0: 
                        skip -= 1
                        continue
                        
                    fd_tests_raw_output.write("{}\n".format(convert_bin_list_to_hexstring(mg_mask)))
                        
        
            else: # 2'b11 Repeated pattern
                
                counter = 0
                to_be_repeated_index = 0
                repeat_pattern_length = 0
                if pattern_w_bits[1] == 0 and pattern_w_bits[0] == 0: # 5'bxxx00, len = 5
                    repeat_pattern_length = 5
                elif pattern_w_bits[1] == 0 and pattern_w_bits[0] == 1: # 5'bxxx01, len = 6
                    repeat_pattern_length = 6
                elif pattern_w_bits[1] == 1 and pattern_w_bits[0] == 0: # 5'bxxx10, len = 7
                    repeat_pattern_length = 7
                elif pattern_w_bits[1] == 1 and pattern_w_bits[0] == 1: # 5'bxxx11, len = 8
                    repeat_pattern_length = 8
                else:
                    print("{} pattern_w is not valid for repeated pattern".format(pattern_w))
                
                while counter < 640:
                    mg_mask.append(repeatedPattern_bits[to_be_repeated_index])
                    
                    counter += 1
                    to_be_repeated_index += 1
                    if to_be_repeated_index == repeat_pattern_length:
                        to_be_repeated_index = 0
                
                mg_mask.reverse()
                fd_tests_raw_output.write("{}\n".format(convert_bin_list_to_hexstring(mg_mask)))
        
            
            fd_tests_raw_output.write("Output end\n")
            fd_tests_raw_output.flush()
        
        fd_tests_raw_output.write("End\n")
        fd_tests_raw_output.flush()
        fd_tests_raw_output.close()
        

if __name__ == "__main__":
    main()
    
    
    
    
    
    
    
    
    
    



