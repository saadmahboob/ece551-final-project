module snn_core(start, q_input, addr_input_unit, digit, done);

  
output [9:0] addr_input_unit;
input logic q_input;
input logic clk, we, data;
logic [9:0] addr;
logic [14:0] addr_rom_hidden;
logic [7:0] q_extended, rom_hidden_data;

ram ram_input_unit(.data(data), .addr(addr), .we(we), .clk(clk), .q(q_input));
rom rom_hidden_unit()
assign q_extended = (q_input) ? 8'h7F : 8'h0;
addr_input_unit = addr_input_unit  + 1;

