DD        4'h0
`define SUB        4'h1
`define ADD_CIN    4'h2
`define SUB_CIN    4'h3
`define INC_A      4'h4
`define DEC_A      4'h5
`define INC_B      4'h6
`define DEC_B      4'h7
`define CMP        4'h8
`define MUL_INC    4'h9
`define MUL_SHIFT_LEFT    4'hA
`define S_ADD       4'hB
`define S_SUB       4'hC

`define AND        4'h0
`define NAND       4'h1
`define OR         4'h2
`define NOR        4'h3
`define XOR        4'h4
`define XNOR       4'h5
`define NOT_A      4'h6
`define NOT_B      4'h7
`define SHR1_A     4'h8
`define SHL1_A     4'h9
`define SHR1_B     4'hA
`define SHL1_B     4'hB
`define ROL_A_B    4'hC
`define ROR_A_B    4'hD


`define NONE 3'b000
`define V_NONE     2'b00
`define V_A        2'b01
`define V_B        2'b10
`define V_BOTH     2'b11

module ALU #(parameter N = 8, C = 4)
  (
    input [N-1:0] OPA, OPB,
    input CIN, CLK, RST, CE, MODE,
    input [1:0] INP_VALID,
    input [C-1:0] CMD,
    output reg [2*N -1 :0] RES,
    output reg OFLOW, COUT, G, L, E, ERR		 
  );
  
  reg [N-1:0] r_OPA, r_OPB;
  reg r_CIN, r_MODE;
  reg [1:0] r_INP_VALID;
  reg [C-1:0] r_CMD;
  
  reg signed [2*N -1:0] signed_result;
  reg [2*N -1:0] mul_inc_result, mul_shift_result;
  reg  mul_inc_valid, mul_shift_valid; //valid flag
  
  always @(posedge CLK or posedge RST) begin
    if(RST) begin
      r_OPA <= 0;
      r_OPB <= 0;
      r_CIN <= 0;
      r_CMD <= 0;
      r_MODE <= 0;
      r_INP_VALID <= 0;
      
      ERR <= 0;
      RES <= 0;
      OFLOW <= 0;
      COUT <= 0;
      G <= 0;
      L <= 0;
      E <= 0;
      
      mul_inc_result <= 0; mul_shift_result <= 0;
      mul_inc_valid <= 0; mul_shift_valid <= 0;
      
    end
    else if(CE) begin
      
      r_OPA <= OPA;
      r_OPB <= OPB;
      r_CIN <= CIN;
      r_CMD <= CMD;
      r_MODE <= MODE;
      r_INP_VALID <= INP_VALID;
      
      
      ERR <= 0;
      RES <= 0;
      OFLOW <= 0;
      COUT <= 0;
      G <= 0;
      L <= 0;
      E <= 0;
      
      if (mul_inc_valid && r_CMD == `MUL_INC) begin
                RES       <= mul_inc_result;
                mul_inc_valid <= 0;
            end
      else if (mul_shift_valid && r_CMD == `MUL_SHIFT_LEFT) begin
                RES       <= mul_shift_result;
                mul_shift_valid <= 0;
            end
      else begin
        if(r_MODE) begin
          case(r_CMD) 
            `ADD: begin
              {COUT , RES[N-1:0]} <= (r_INP_VALID == `V_BOTH) ? (r_OPA + r_OPB) : {COUT , RES[N-1:0]};
              ERR <= ~(r_INP_VALID == `V_BOTH);
            end
            
            `SUB: begin
              RES <=  (r_INP_VALID == `V_BOTH) ? (r_OPA - r_OPB): RES;
              ERR <= ~(r_INP_VALID == `V_BOTH);
              OFLOW <= (r_OPB > r_OPA);
            end
            
            `ADD_CIN: begin
              {COUT , RES[N-1:0]} <= (r_INP_VALID == `V_BOTH) ? (r_OPA + r_OPB + r_CIN) : {COUT , RES[N-1:0]};
              ERR <= ~(r_INP_VALID == `V_BOTH);
            end
            
            `SUB_CIN: begin
              RES <=  (r_INP_VALID == `V_BOTH) ? (r_OPA - r_OPB - r_CIN): RES;
              ERR <= ~(r_INP_VALID == `V_BOTH);
              OFLOW <= ({1'b0,r_OPA}  < (r_OPB + r_CIN));
            end
            
            `INC_A: begin
              RES <= (r_INP_VALID == `V_BOTH || r_INP_VALID == `V_A) ? (r_OPA + 1) : RES;
              ERR <= ~(r_INP_VALID == `V_BOTH || r_INP_VALID == `V_A);
            end
            
            `DEC_A: begin
              RES <= (r_INP_VALID == `V_BOTH || r_INP_VALID == `V_A) ? (r_OPA - 1) : RES;
              ERR <= ~(r_INP_VALID == `V_BOTH || r_INP_VALID == `V_A);
            end
            
            `INC_B: begin
              RES <= (r_INP_VALID == `V_BOTH || r_INP_VALID == `V_B) ? (r_OPB + 1) : RES;
              ERR <= ~(r_INP_VALID == `V_BOTH || r_INP_VALID == `V_B);
            end
            
            `DEC_B: begin
              RES <= (r_INP_VALID == `V_BOTH || r_INP_VALID == `V_B) ? (r_OPB - 1) : RES;
              ERR <= ~(r_INP_VALID == `V_BOTH || r_INP_VALID == `V_B);
            end
            
            `CMP: begin
              RES <= 0;
              G <= r_OPA > r_OPB;
              L <= r_OPA < r_OPB;
              E <= r_OPA == r_OPB;
              ERR <= ~(r_INP_VALID == `V_BOTH);             
            end
            
            `MUL_INC: begin
              if(r_INP_VALID == `V_BOTH)  begin
                ERR <= 0;
                mul_inc_result <= (r_OPA + 1)*(r_OPB + 1);
                mul_inc_valid <= 1;
                RES <= 0;
              end
              else ERR <= 1;
            end
            
            `MUL_SHIFT_LEFT: begin
              if(r_INP_VALID == `V_BOTH)  begin
                ERR <= 0;
                mul_shift_result <= (r_OPA << 1)*(r_OPB);
                mul_shift_valid <= 1;
                RES <= 0;
              end
              else ERR <= 1;
            end
            
            `S_ADD: begin
               ERR <= ~(r_INP_VALID == `V_BOTH);
              
              if(r_INP_VALID == `V_BOTH) begin
                signed_result = $signed({1'b0,r_OPA}) + $signed({1'b0,r_OPB});
                RES <= {{N{signed_result[N-1]}}, 
                        signed_result[N-1:0]};
                OFLOW <= (r_OPA[N-1] == r_OPB[N-1]) && (signed_result[N-1] != r_OPA[N-1]);
                G <= ($signed(r_OPA) >  $signed(r_OPB));
                L <= ($signed(r_OPA) <  $signed(r_OPB));
                E <= ($signed(r_OPA) == $signed(r_OPB));
              end
              else begin
                RES <= 0;
                COUT <= 0;
                G <= 0;
                L <= 0;
                E <= 0;
                OFLOW <= 0;
              end
            end
            
            `S_SUB: begin
               ERR <= ~(r_INP_VALID == `V_BOTH);
              
              if(r_INP_VALID == `V_BOTH) begin
                signed_result = $signed({1'b0,r_OPA}) - $signed({1'b0,r_OPB});
                RES <= {{N{signed_result[N-1]}}, 
                        signed_result[N-1:0]};
                OFLOW <= (r_OPA[N-1] != r_OPB[N-1]) && (signed_result[N-1] != r_OPA[N-1]);
                G <= ($signed(r_OPA) >  $signed(r_OPB));
                L <= ($signed(r_OPA) <  $signed(r_OPB));
                E <= ($signed(r_OPA) == $signed(r_OPB));
              end
              else begin
                RES <= 0;
                COUT <= 0;
                G <= 0;
                L <= 0;
                E <= 0;
                OFLOW <= 0;
              end
            end
            
            default: begin
              RES <= 0;
              COUT <= 0;
              G <= 0;
              L <= 0;
              E <= 0;
              OFLOW <= 0;
              ERR <= 1;
            end
            
            
          endcase
        end
        
        else begin
          	RES[2*N-1:N]<=0; 
            OFLOW<=0;
            COUT<=0;
            {G,L,E}<=`NONE;
          case(r_CMD)
            `AND:    begin 
            RES[N-1:0] <= (r_INP_VALID==`V_BOTH) ? (r_OPA & r_OPB) :0; 
            ERR <= ~(r_INP_VALID==`V_BOTH); 
          end
          
          `OR:    begin 
            RES[N-1:0] <= (r_INP_VALID==`V_BOTH) ? (r_OPA | r_OPB) :0; 
            ERR <= ~(r_INP_VALID==`V_BOTH); 
          end
          
          `NAND:    begin 
            RES[N-1:0] <= (r_INP_VALID==`V_BOTH) ? ~(r_OPA & r_OPB) :0; 
            ERR <= ~(r_INP_VALID==`V_BOTH); 
          end
          
          `NOR:    begin 
            RES[N-1:0] <= (r_INP_VALID==`V_BOTH) ? ~(r_OPA | r_OPB) :0; 
            ERR <= ~(r_INP_VALID==`V_BOTH); 
          end
          
          `XOR:    begin 
            RES[N-1:0] <= (r_INP_VALID==`V_BOTH) ? (r_OPA ^ r_OPB) :0; 
            ERR <= ~(r_INP_VALID==`V_BOTH); 
          end
          
          `XNOR:    begin 
            RES[N-1:0] <= (r_INP_VALID==`V_BOTH) ? ~(r_OPA ^ r_OPB) :0; 
            ERR <= ~(r_INP_VALID==`V_BOTH); 
          end
          
          `NOT_A:    begin 
            RES[N-1:0] <= ((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_A)) ? ~r_OPA :0; 
            ERR <= ~((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_A)); 
          end
          
          `NOT_B:    begin 
            RES[N-1:0] <= ((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_B)) ? ~r_OPB :0; 
            ERR <= ~((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_B)); 
          end
          
          `SHR1_A:    begin 
            RES[N-1:0] <= ((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_A))? r_OPA >> 1 :0; 
            ERR <= ~((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_A)); 
          end
          
          `SHL1_A:    begin 
            RES[N-1:0] <= ((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_A)) ? r_OPA << 1 :0; 
            ERR <= ~((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_A)); 
          end
          
          `SHR1_B:    begin 
            RES[N-1:0] <= ((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_B)) ? r_OPB >> 1 :0; 
            ERR <= ~((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_B)); 
          end
          
          `SHL1_B:    begin 
            RES[N-1:0] <= ((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_B)) ? r_OPB << 1 :0; 
            ERR <= ~((r_INP_VALID==`V_BOTH)||(r_INP_VALID==`V_B)); 
          end
          endcase       
        end
      
      
      end
      
    end // CE wala else if
    
    
  end //always ka end
  
endmodule













