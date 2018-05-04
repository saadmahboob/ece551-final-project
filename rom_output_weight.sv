module rom_output_weight (
 input [(8):0] addr,
 input clk,
 output reg [(7):0] q);

 // Declare the ROM variable
 reg [7:0] rom[2**9-1:0];

 initial
    $readmemh("./Files/memory\ initialization\ files/rom_output_weight_contents.txt", rom);

 always @ (posedge clk) begin
    q <= rom[addr];
 end
 
endmodule
