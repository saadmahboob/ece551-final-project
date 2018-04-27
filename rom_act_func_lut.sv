module rom_act_func_lut (
 input [10:0] addr,
 input clk,
 output reg [7:0] q);
 // Declare the ROM variable
 reg [7:0] rom[2**10:0];
 initial
 $readmemh("Initialization file", rom);
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule
