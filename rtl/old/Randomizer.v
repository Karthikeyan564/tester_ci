module Randomizer(clk, reset, load, rand_ready, seed_load,Data_in, Data_out, Rand_valid);

    input clk, reset, load, rand_ready, Data_in;
    input [0:14]seed_load;
    output reg Data_out, Rand_valid;
    
    reg [0:14]r_reg, r_next; 
    reg Rand_valid_next, Data_out_next;
    reg [6:0]counter;
    
    always @(posedge clk or reset)
    begin
        if (reset)
        begin
            r_reg <= 15'd0;
            r_next <= 15'd0;
            Data_out <= 1'b0;
            Rand_valid <= 1'b0;
            counter <= 7'd0;
            Rand_valid_next <=1'b0;

        end
        else
        begin

            if (load)
            begin
                r_reg <= seed_load;
            end
            
            if ((!load) & rand_ready)
            begin
                r_reg <= r_next;
                Data_out <= Data_out_next;
                Rand_valid <= Rand_valid_next;
            end
            
            if ((!load) & (!rand_ready))
            begin
                Rand_valid <= Rand_valid_next;
            end
            
            if ((counter < 7'b1011111) & (rand_ready))
            begin
                counter<= counter + 7'd1;
                // if (counter == 7'b1011111)
                // begin
                //     counter <= 7'b0;
                //     r_reg <= seed_load;
                // end
            end
            else
            begin
                counter <= 7'd0;
                r_reg <= seed_load;

            end
            

        end

        
    end
    

    always @(*)
    begin

            if (rand_ready & (!reset) & (!load))
            begin
             /*   r_next <= {r_reg[14],(r_reg[13]^r_reg[14])^r_reg[13],(r_reg[13]^r_reg[14])^r_reg[12],(r_reg[13]^r_reg[14])^r_reg[11],(r_reg[13]^r_reg[14])^r_reg[10],
                (r_reg[13]^r_reg[14])^r_reg[9],(r_reg[13]^r_reg[14])^r_reg[8],(r_reg[13]^r_reg[14])^r_reg[7],(r_reg[13]^r_reg[14])^r_reg[6],
                (r_reg[13]^r_reg[14])^r_reg[5],(r_reg[13]^r_reg[14])^r_reg[4],(r_reg[13]^r_reg[14])^r_reg[3],(r_reg[13]^r_reg[14])^r_reg[2],
                (r_reg[13]^r_reg[14])^r_reg[1],(r_reg[13]^r_reg[14])^r_reg[0]};
             */
                r_next = {(r_reg[13]^r_reg[14]),r_reg[0:13]};
                Data_out_next = Data_in ^ (r_reg[13] ^ r_reg[14]);
                Rand_valid_next = 1'b1;
            end
            
            if ((!rand_ready) & (!reset) & (!load))
            begin
                Rand_valid_next = 1'b0;
            end

    end    
    
endmodule