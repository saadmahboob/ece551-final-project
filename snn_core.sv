module snn_core(start, q_input, addr_input_unit, digit, done);

typedef enum reg[2:0] {IDLE, MAC1, MAC2, MAX, DONE} state;
state curr_state, next_state;

output [9:0] addr_input_unit;

input logic clk, we;
input logic q_input;
logic [14:0] hidden_weight_addr;
logic [7:0] q_extended, hidden_weight_q;
logic [7:0] a, b, yk, ram_hidden_data, output_weight_q, yykk;
logic [25:0] acc;
logic clr_n, rst_n;
logic [10:0] addr_LUT;
logic [4:0] addr_ram_hidden;
logic [8:0] output_weight_addr;
logic select_input;
logic [3:0] output_unit_addr;
logic [2:0] output_digit;

rom hidden_weight(.addr(hidden_weight_addr), .clk(clk), .q(hidden_weight_q));
rom output_weight(.addr(output_weight_addr), .clk(clk), .q(output_weight_q));
ram hidden_unit(.data(yk), .addr(addr_ram_hidden), .clk(clk), .we(we), .q(ram_hidden_data));
rom act_func_lut(.addr(.addr_LUT + 11'h0400), .clk(clk), .q(yk));
mac mac(.clk(clk), .(a), .b(b), .acc(acc), .clr_n(clr_n), .rst_n(rst_n));
ram output_unit(.data(yykk), .addr(output_unit_addr), .clk(clk), .we(we), .q(output_digit));

assign q_extended = (q_input) ? 8'h7F : 8'h0;

addr_input_unit = addr_input_unit  + 1;
addr_rom_hidden = addr_rom_hidden + 1;
addr_ram_hidden = addr_ram_hidden + 1;
output_weight_addr = output_weight_addr + 1;
assign hidden_weight_addr_max = hidden_weight_addr == 25088 ? 1 : 0;
assign addr_input_unit_max = addr_input_unit == 784 ? 1 : 0;
assign addr_ram_hidden_max = addr_ram_hidden == 32 ? 1 : 0;
assign output_weight_addr_max = output_weight_addr == 320 ? 1 : 0;

if(acc[25]==0 && |acc[24:17] == 1) begin
addr_LUT = 11'h3ff;
end

else if(acc[25]==1 && &acc[24:17] == 0) begin
addr_LUT = 11'h400;
end

else
addr_LUT = acc[17:7];


// FSM
always_comb begin
  //default values
  select_input = 0;
  done = 0;

  case (state)
    IDLE:
      if (start) begin					//start bit detected
        next_state = MAC1;
      end

    MAC1:
      if (hidden_weight_addr_max)					//at middle of start bit
        next_state = MAC2;
      else begin
        next_state = MAC1;
      end

    MAC2:
      select_input = 1;
      if (output_weight_addr_max) begin	//middle of a bit which isn't the stop bit
        next_state = MAX;
      end
      else begin
        next_state = MAC2;
      end

    MAX:
      if (digit_max) begin
        done = 1;
        next_state = DONE;
      end
      else
        next_state = MAX;

    DONE:

    endcase
  end

endmodule
