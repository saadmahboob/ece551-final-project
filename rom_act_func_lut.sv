module rom_act_func_lut (
 input [10:0] addr,
 input clk,
 output reg [7:0] q);
 // Declare the ROM variable
 reg [7:0] rom[2**11-1:0];
 initial
 $readmemh("./Files/memory\ initialization\ files/rom_act_func_lut_contents.txt", rom);
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule
