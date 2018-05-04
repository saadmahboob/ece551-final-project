module rom_hidden_weight (
 input [14:0] addr1,
 input [14:0] addr2,
 input clk,
 output reg [7:0] q1,
 output reg [7:0] q2);
 // Declare the ROM variable
 reg [7:0] rom[2**15-1:0];
 initial
    $readmemh("./Files/memory\ initialization\ files/rom_hidden_weight_contents.txt", rom);

 always @ (posedge clk)
 begin
 q2 <= rom[addr2];
 q1 <= rom[addr1];
 end
endmodule
