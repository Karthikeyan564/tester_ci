from utils import read_results

def main():    
    sw_results, sw_results_count = read_results("../testcase_raws/vga_testcases_sw_output.txt")
    hw_results, hw_results_count = read_results("../testcase_raws/vga_testcases_hw_output.txt")
    
    fd_tests_summary = open("../testcase_raws/vga_testcases_summary.txt", "w")
    if sw_results_count != hw_results_count:
        fd_tests_summary.write("Number of results differ for software({}) and hardware({}) files\n".format(sw_results_count, hw_results_count))
        raise Exception("Number of results differ for software({}) and hardware({}) files\n".format(sw_results_count, hw_results_count))
        
    else:
        total_count = sw_results_count
        for index in range(0, total_count):
            if sw_results[index]["testcase"] != hw_results[index]["testcase"]:
                fd_tests_summary.write("Testcase #{}: Mismatched testcase inputs between SW({}) and HW({})\n".format(index, sw_results[index]["testcase"], hw_results[index]["testcase"]))
                raise Exception("Testcase #{}: Mismatched testcase inputs between SW({}) and HW({})\n".format(index, sw_results[index]["testcase"], hw_results[index]["testcase"]))
                continue
                
            sw_output_len = len(sw_results[index]["output"])
            hw_output_len = len(hw_results[index]["output"])
            if sw_output_len != hw_output_len:
                fd_tests_summary.write("Testcase #{}: Length of outputs differ for software({}) and hardware({}) files\n".format(index, sw_output_len, hw_output_len))
                fd_tests_summary.write("{}\tFailed\n".format(sw_results[index]["testcase"]))
                raise Exception("Testcase #{}: Length of outputs differ for software({}) and hardware({}) files\n".format(index, sw_output_len, hw_output_len))
                continue
                
            counter = 0
            output_same = True
            while counter < sw_output_len:
                if sw_results[index]["output"][counter] != hw_results[index]["output"][counter]:
                    fd_tests_summary.write("Testcase #{}: Outputs differ for software and hardware files\n".format(index))
                    fd_tests_summary.write("Software: {}\nHardware: {}\n".format(sw_results[index]["output"][counter], hw_results[index]["output"][counter]))
                    fd_tests_summary.write("{}\tFailed\n".format(sw_results[index]["testcase"]))
                    output_same = False
                    raise Exception("Testcase #{}: Outputs differ for software and hardware files\n".format(index))
                    break
                counter += 1
            
            if not output_same:
                continue
            fd_tests_summary.write("{}\tPassed\n".format(sw_results[index]["testcase"]))
    
        
if __name__ == "__main__":
    main()
    
    
    
    
    
    
    
    
    
    



