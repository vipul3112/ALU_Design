module ALU_Design #(parameter N=8, C=4)
(
    input  [N-1:0]      OPA,
    input  [N-1:0]      OPB,
    input               CIN,
    input               CLK,
    input               RST,
    input               CE,
    input               MODE,
    input  [1:0]        INP_VALID,  // [BA]
    input  [C-1:0]      CMD,
    
    output reg [2*N-1:0] RES,
    output reg           ERR,
    output               OFLOW,
    output               COUT,
    output               G,
    output               L,
    output               E
);

    reg [C-1:0]     prev_CMD;
    reg [1:0]       count;
    reg [N-1:0]     tmp_a, tmp_b;       // multiplication sampling 
    //reg [2*N-1:0]   tmp_res;

    // Carry out for unsigned ADD and ADD with CIN
    assign COUT = ((CMD == 'd0 || CMD == 'd2) && MODE == 1'b1) ? RES[N] : 1'b0;

    // Comparison outputs: Greater, Less, Equal (for COMP and signed operations)
    assign {G, L, E} = ((CMD == 'd8 || CMD == 'd11 || CMD == 'd12) && MODE == 1'b1) ? 
                       ({$signed(OPA) > $signed(OPB), 
                         $signed(OPA) < $signed(OPB), 
                         $signed(OPA) == $signed(OPB)}) : 3'b0;

    // Overflow flag for unsigned SUB/SUB_CIN and signed ADD/SUB
    assign OFLOW = ((CMD == 'd1 || CMD == 'd3 || CMD == 'd11 || CMD == 'd12) && MODE == 1'b1) ? 
                   (~RES[N]) : 1'b0;

    always @(posedge CLK) begin
        if (RST) begin
            RES      <= {(2*N){1'b0}};
            ERR      <= 1'b0;
            count    <= 2'd0;
            prev_CMD <= {C{1'b0}};
        end
        else if (CE) begin
            prev_CMD <= CMD;
            
            // Counter logic for multiplication operations
            if ((prev_CMD != CMD) || count >= 2'b01)
                count <= 2'd0;
            else if ((CMD == 'd9) || (CMD == 'd10))
                count <= count + 1;
            else
                count <= 2'd0;
            
            // MODE = 1: ARITHMETIC operations
            if (MODE) begin
                case (CMD)
                    'd0: begin  // Unsigned ADD
                        RES <= OPA + OPB;
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                    end
                    
                    'd1: begin  // Unsigned SUB
                        RES <= OPA - OPB;
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                    end
                    
                    'd2: begin  // Unsigned ADD with CIN
                        RES <= OPA + OPB + CIN;
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                    end
                    
                    'd3: begin  // Unsigned SUB with CIN
                        RES <= OPA - OPB - CIN;
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                    end
                    
                    'd4: begin  // Increment A
                        RES <= OPA + 1'b1;
                        ERR <= (INP_VALID[0]) ? 1'b0 : 1'b1;
                    end
                    
                    'd5: begin  // Decrement A
                        RES <= OPA - 1'b1;
                        ERR <= (INP_VALID[0]) ? 1'b0 : 1'b1;
                    end
                    
                    'd6: begin  // Increment B
                        RES <= OPB + 1'b1;
                        ERR <= (INP_VALID[1]) ? 1'b0 : 1'b1;
                    end
                    
                    'd7: begin  // Decrement B
                        RES <= OPB - 1'b1;
                        ERR <= (INP_VALID[1]) ? 1'b0 : 1'b1;
                    end
                    
                    'd8: begin  // Comparator (handled using assign statement)
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                    end
                    
                    'd9: begin  // Increment & Multiply
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                        {tmp_a, tmp_b} <= (count == 2'd0 || count == 2'd2) ? 
                                          {OPA, OPB} : {tmp_a, tmp_b};
                        RES <= (count >= 2'd1) ? ((tmp_a + 1'b1) * (tmp_b + 1'b1)) : RES;
                    end
                    
                    'd10: begin  // Shift & Multiply
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                        {tmp_a, tmp_b} <= (count == 2'd0 || count == 2'd2) ? 
                                          {OPA, OPB} : {tmp_a, tmp_b};
                        RES <= (count >= 2'd1) ? ((tmp_a << 1'b1) * tmp_b) : RES;
                    end
                    
                    'd11: begin  // Signed Addition
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                        RES <= ($signed(OPA) + $signed(OPB));
                    end
                    
                    'd12: begin  // Signed Subtraction
                        ERR <= (INP_VALID == 2'b11) ? 1'b0 : 1'b1;
                        RES <= ($signed(OPA) - $signed(OPB));
                    end
                    
                    default: RES <= RES;
                endcase
            end
            
            // MODE = 0: LOGICAL operations
            else begin
                case (CMD)
                    'd0: begin  // AND
                        RES <= OPA & OPB;
                        ERR <= (INP_VALID == 2'd3) ? 1'b0 : 1'b1;
                    end
                    
                    'd1: begin  // NAND
                        RES <= {8'd0, ~(OPA & OPB)};
                        ERR <= (INP_VALID == 2'd3) ? 1'b0 : 1'b1;
                    end
                    
                    'd2: begin  // OR
                        RES <= OPA | OPB;
                        ERR <= (INP_VALID == 2'd3) ? 1'b0 : 1'b1;
                    end
                    
                    'd3: begin  // NOR
                        RES <= {8'd0, ~(OPA | OPB)};
                        ERR <= (INP_VALID == 2'd3) ? 1'b0 : 1'b1;
                    end
                    
                    'd4: begin  // XOR
                        RES <= OPA ^ OPB;
                        ERR <= (INP_VALID == 2'd3) ? 1'b0 : 1'b1;
                    end
                    
                    'd5: begin  // XNOR
                        RES <= {8'd0, ~(OPA ^ OPB)};
                        ERR <= (INP_VALID == 2'd3) ? 1'b0 : 1'b1;
                    end
                    
                    'd6: begin  // NOT A
                        RES <= {8'd0, ~OPA};
                        ERR <= (INP_VALID[0]) ? 1'b0 : 1'b1;
                    end
                    
                    'd7: begin  // NOT B
                        RES <= {8'd0, ~OPB};
                        ERR <= (INP_VALID[1]) ? 1'b0 : 1'b1;
                    end
                    
                    'd8: begin  // Logical Shift Right A
                        RES <= {{N{1'b0}}, (OPA >> 1)};
                        ERR <= (INP_VALID[0]) ? 1'b0 : 1'b1;
                    end
                    
                    'd9: begin  // Logical Shift Left A
                        RES <= {{N{1'b0}}, (OPA << 1)};
                        ERR <= (INP_VALID[0]) ? 1'b0 : 1'b1;
                    end
                    
                    'd10: begin  // Logical Shift Right B
                        RES <= {{N{1'b0}}, (OPB >> 1)};
                        ERR <= (INP_VALID[1]) ? 1'b0 : 1'b1;
                    end
                    
                    'd11: begin  // Logical Shift Left B
                        RES <= {{N{1'b0}}, (OPB << 1)};
                        ERR <= (INP_VALID[1]) ? 1'b0 : 1'b1;
                    end
                    
                    'd12: begin  // Variable Shift Left A by B
                        RES <= {{N{1'b0}}, (OPA << OPB[($clog2(N)-1):0])};
                        ERR <= (OPB[N-1:($clog2(N))+1] > 4'd0 || (INP_VALID != 2'd3)) ? 
                               1'b1 : 1'b0;
                    end
                    
                    'd13: begin  // Variable Shift Right A by B
                        RES <= {{N{1'b0}}, (OPA >> OPB[($clog2(N)-1):0])};
                        ERR <= (OPB[N-1:($clog2(N))+1] > 4'd0 || (INP_VALID != 2'd3)) ? 
                               1'b1 : 1'b0;
                    end
                    
                    default: RES <= RES;
                endcase
            end
        end
    end

endmodule
