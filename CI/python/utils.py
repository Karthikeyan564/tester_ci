def read_results(output_filename):
    results_list = []
    with open(output_filename, "r") as fd_results:
        results = fd_results.readlines()
        
        result_dict = {}
        
        is_testcase_line = True
        is_output_line = False
        
        for result in results:
            
            if result.strip() == "End":
                break
                
            if result.strip() == "Output start:":
                result_dict["output"] = []
                is_output_line = True
                continue
                
            if result.strip() == "Output end":
                results_list.append(result_dict)
                
                result_dict = {}
            
                is_testcase_line = True
                is_output_line = False
                continue
            
            if is_testcase_line:
                result_dict["testcase"] = result.strip()
                is_testcase_line = False
                continue
                
            if is_output_line:
                result_dict["output"].append(result.strip())
                continue
                
        return results_list, len(results_list)
        
def halfbyte_to_binary_list(halfbyte):
    if halfbyte == '0':
        return [0, 0, 0, 0]
    elif halfbyte == '1':
        return [0, 0, 0, 1]
    elif halfbyte == '2':
        return [0, 0, 1, 0]
    elif halfbyte == '3':
        return [0, 0, 1, 1]
    elif halfbyte == '4':
        return [0, 1, 0, 0]
    elif halfbyte == '5':
        return [0, 1, 0, 1]
    elif halfbyte == '6':
        return [0, 1, 1, 0]
    elif halfbyte == '7':
        return [0, 1, 1, 1]
    elif halfbyte == '8':
        return [1, 0, 0, 0]
    elif halfbyte == '9':
        return [1, 0, 0, 1]
    elif halfbyte == 'A' or halfbyte == 'a':
        return [1, 0, 1, 0]
    elif halfbyte == 'B' or halfbyte == 'b':
        return [1, 0, 1, 1]
    elif halfbyte == 'C' or halfbyte == 'c':
        return [1, 1, 0, 0]
    elif halfbyte == 'D' or halfbyte == 'd':
        return [1, 1, 0, 1]
    elif halfbyte == 'E' or halfbyte == 'e':
        return [1, 1, 1, 0]
    elif halfbyte == 'F' or halfbyte == 'f':
        return [1, 1, 1, 1]
    else:
        return []

def convert_hexstring_to_bin_list(hexstring, binary_list):
    for halfbyte in hexstring:
        temp_binary_list = halfbyte_to_binary_list(halfbyte)
        if not temp_binary_list:
            print("{} from hexstring is malformatted.".format(halfbyte))
        binary_list.extend(temp_binary_list)

def convert_binstring_to_bin_list(binstring, binary_list):
    for binary in binstring:
        if binary == '0':
            binary_list.append(0)
        elif binary == '1':
            binary_list.append(1)
        else:
            print("{} from binstring is malformatted.".format(binary))
    
def convert_bin_list_to_hexstring(binary_list):
    result = ""
    
    for index in range(3, 640, 4):
        decimal_val = binary_list[index-3]*8 + binary_list[index-2]*4 + binary_list[index-1]*2 + binary_list[index]
        result += hex(decimal_val)[2:]
        
    return result