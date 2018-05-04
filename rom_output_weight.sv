module rom_output_weight (
 input [(8):0] addr1,
 input [(8):0] addr2,
 input clk,
 output reg [(7):0] q1,
 output reg [(7):0] q2);
 // Declare the ROM variable
 reg [7:0] rom[2**9-1:0];
 initial
 $readmemh("./Files/memory\ initialization\ files/rom_output_weight_contents.txt", rom);
 always @ (posedge clk)
 begin
 q1 <= rom[addr1];
 q2 <= rom[addr2];
 end
endmodule
