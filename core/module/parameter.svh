`ifndef PARAMETER_SVH
`define PARAMETER_SVH   
   parameter logic [3:0] ADD  = 4'b0000;
   parameter logic [3:0] SUB  = 4'b0001;
   parameter logic [3:0] SLT  = 4'b0010;
   parameter logic [3:0] SLTU  = 4'b0011;
   parameter logic [3:0] XOR = 4'b0100;
   parameter logic [3:0] OR  = 4'b0101;
   parameter logic [3:0] AND  = 4'b0110;
   parameter logic [3:0] SLL  = 4'b0111;
   parameter logic [3:0] SRL  = 4'b1000;
   parameter logic [3:0] SRA  = 4'b1001;
`endif