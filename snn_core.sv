module snn_core(start, q_input, addr_input_unit, digit, done);


output [9:0] addr_input_unit;
input logic q_input;
input logic clk, we, data;
logic [9:0] addr;
logic [14:0] addr_rom_hidden;
logic [7:0] q_extended, rom_hidden_data;
logic [7:0] a, b;
logic [25:0] acc;
logic clr_n, rst_n;
logic [10:0] addr_LUT;


mac mac(.clk(clk), .(a), .b(b), .acc(acc), .clr_n(clr_n), .rst_n(rst_n));
ram ram_input_unit(.data(data), .addr(addr), .we(we), .clk(clk), .q(q_input));
rom rom_hidden_unit(.addr(addr_rom_hidden), .clk(clk), .q(rom_hidden_data));
assign q_extended = (q_input) ? 8'h7F : 8'h0;
addr_input_unit = addr_input_unit  + 1;
addr_rom_hidden = addr_rom_hidden + 1;


if(acc[25]==0 && |acc[24:17] == 1) begin
addr_LUT = 11'h3ff;
end

else if(acc[25]==1 && &acc[24:17] == 0) begin
addr_LUT = 11'h400;
end

else
addr_LUT = acc[17:7];
