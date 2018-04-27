module rom_hidden_weight (
 input [14:0] addr,
 input clk,
 output reg [7:0] q);
 // Declare the ROM variable
 reg [7:0] rom[2**14:0];
 initial
 $readmemh("Initialization file", rom);
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule
