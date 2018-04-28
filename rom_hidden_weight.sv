module rom_hidden_weight (
 input [14:0] addr,
 input clk,
 output reg [7:0] q);
 // Declare the ROM variable
 reg [7:0] rom[2**15-1:0];
 initial
 $readmemh("./Files/memory\ initialization\ files/rom_hidden_weight_contents.txt", rom);
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule
