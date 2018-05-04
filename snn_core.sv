/*
 * Author(s)	: Shubham Singh, Naman Singhal, Jon Sharp, Akshat Khanna
 * Module name	: snn_core.sv
 * Modules used	: rom_hidden_weight.sv, rom_output_weight.sv, ram_hidden_unit.sv, rom_act_func_lut.sv, mac.sv
 *
 * Description	: snn_core is the core of a simple neural network that outputs an address
 * to receive a bit at that address from the ram_input_unit. Once receiving each bit of the
 * bit map, it uses a neural network to output what digit the bitmap corresponds to. 
 *
 */
 module snn_core(start, clk, rst_n, q_input, addr_input_unit, digit, done);

  typedef enum reg[1:0] {IDLE, MAC1, MAC2, DONE} state;
  state curr_state, next_state;

  input logic clk, start, rst_n;
  input logic q_input;                  //input coming from address input ram

  output logic [9:0] addr_input_unit;   //output address going to address input ram
  output logic [3:0] digit;             //output digit calculated by the neural network
  output logic done;                    //asserted when snn_core is done

  logic select_input, inc_input_addr, increment_output, check_max, write_hidden;
  logic mac_clr_n, output_clr, hidden_clr, addr_input_unit_clr, digit_clr;

  //MAC 1 - calculate hidden layer
  logic [7:0]   q_extended, ram_hidden_data, hidden_weight_q;
  logic [5:0]   cnt_hidden;     //counter to count up to 32 hidden weights

  //mac and lut registers
  logic [7:0]   a, b, lut_out;
  logic [25:0]  acc;
  logic [10:0]  addr_LUT;

  //MAC 2 - calculate final output
  logic [7:0]   output_weight_q, max_prob;
  logic [3:0]   digit_reg;
  logic [3:0]   cnt_output;

  rom_hidden_weight    hidden_weight(.clk(clk), .addr({cnt_hidden[4:0], addr_input_unit[9:0]}), .q(hidden_weight_q));
  rom_output_weight    output_weight(.clk(clk), .addr({cnt_output[3:0], cnt_hidden[4:0]}), .q(output_weight_q));
  ram_hidden_unit      hidden_unit  (.clk(clk), .we(write_hidden), .data(lut_out), .addr(cnt_hidden [4:0]), .q(ram_hidden_data));
  rom_act_func_lut     act_func_lut (.clk(clk), .addr(addr_LUT + 11'h400),.q(lut_out));
  mac                  mac          (.clk(clk), .a(a), .b(b),  .clr_n(mac_clr_n), .rst_n(rst_n), .acc(acc), .addr_LUT(addr_LUT));

  //MAC 1
  assign q_extended = (q_input) ? 8'h7F : 8'h00;
  assign addr_input_unit_max = addr_input_unit == 10'h306 ? 1 : 0;
  assign cnt_hidden_max = cnt_hidden == 6'h20 ? 1 : 0;

  //MAC 2
  assign cnt_output_max =  (select_input) ? ((cnt_output == 4'ha) ? 1 : 0) : 0;
  assign cnt_hidden_max_out = cnt_hidden == 6'h22 ? 1 : 0;
  assign digit_max = digit_reg == 4'ha ? 1 : 0;
  assign cnt_hidden_zero = cnt_hidden == 6'h0 ? 1 : 0;

  //choose inputs into mac
  assign a = select_input ? ram_hidden_data : q_extended;
  assign b = select_input ? output_weight_q : hidden_weight_q;

  //FSM
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      curr_state <= IDLE;
    else
      curr_state <= next_state;

  //combinational logic for states
  always_comb begin
    //default values
    select_input = 0;
    inc_input_addr = 0;
    increment_output = 0;
    done = 0;
    mac_clr_n = 0;
    output_clr = 0;
    hidden_clr = 0;
    addr_input_unit_clr = 0;
    digit_clr = 0;
    check_max = 0;
    next_state = IDLE;
    write_hidden = 0;
    addr_input_unit_clr = 0;

    case (curr_state)
      //stay in IDLE until start is detected
      IDLE:
        if (start) begin
          //set next state to MAC1 to update hidden weight ram
          next_state = MAC1;
          digit_clr = 1;
          addr_input_unit_clr = 1;
        end

      //stay in MAC1 for 737 * 32 cycles to MAC the input with hidden weights
      MAC1: begin
        output_clr = 1;
        //clear input unit when maximum address from ram_input_unit is read to go to next hidden weight
        //else write MAC output to hidden weight ram
        if (!addr_input_unit_max)
          mac_clr_n = 1;
        else
          write_hidden = 1;

        //if all 32 weights have been multiplied, move to MAC2 to find output weights
        //else increment address to read ram_input_unit
        if (cnt_hidden_max)	begin
          hidden_clr = 1;
          next_state = MAC2;
        end
        else begin
          inc_input_addr = 1;
          next_state = MAC1;
        end
      end

      //stay in MAC2 for 32*10 cycles to MAC the hidden weight ram with output weights and calculate
      //the digit with the maximum probability
      MAC2: begin
        //change inputs to mac
        select_input = 1;
        //when all 10 output weights have been used, to to DONE
        //else increment address for output weight and current digit
        if (digit_max)
            next_state = DONE;
        else begin
          addr_input_unit_clr = 1;  //this should be asserted throughtout MAC2
          increment_output = 1;
          next_state = MAC2;
        end

        //clear mac when first hidden ram input is read
        if (cnt_hidden_zero)
            mac_clr_n = 0;
        else if (!cnt_hidden_max_out)
            mac_clr_n = 1;
        //check if the current digit is maximum once all 32 hidden weights have been multipled for this
        //digit's output weight
        else
          check_max = 1;
      end

      //asserted done for one clock cycle
      DONE: begin
        check_max = 0;
        done = 1;
        next_state = IDLE;
      end

      default:
        next_state = IDLE;

    endcase
  end

  //address input unit counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      addr_input_unit <= 10'h0;
    else
      //clear the address ram_input_unit is being read to 0x22 because the first 36 hidden weights
      //are 0
      if (addr_input_unit_clr)
        addr_input_unit <= 10'h22;
      else if (addr_input_unit_max)
        addr_input_unit <= 10'h22;
      else
        if (inc_input_addr)
          addr_input_unit <= addr_input_unit + 1;

  //hidden weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_hidden <= 6'h0;
    else
      if (hidden_clr)
        cnt_hidden <= 6'h0;
      else if (cnt_hidden_max_out)
        cnt_hidden <=6'h0;
      else if (addr_input_unit_max)
        cnt_hidden <= cnt_hidden + 1;
      else if (increment_output)
        cnt_hidden <= cnt_hidden + 1;

  //output weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_output <= 4'h0;
    else
      if (output_clr)
        cnt_output <= 4'h0;
      else
        if (cnt_hidden_max)
          cnt_output <= cnt_output + 1;

  //digit counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      digit_reg <= 4'h0;
    else
      if (digit_clr)
        digit_reg <= 4'h0;
      else
        if (check_max)
          digit_reg <= digit_reg + 1;

  //probability register
  //updates if the current output weight has a greater probability
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      max_prob <= 8'h00;
    else
      if (digit_clr)
        max_prob <= 8'h00;
      else if (check_max)
        if (lut_out > max_prob)
          max_prob <= lut_out;

  //final digit register
  //updates if the current output weight has a greater probability
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
     digit <= 0;
    else
      if (digit_clr)
        digit <= 0;
      else if (check_max)
        if (lut_out > max_prob)
          digit <= digit_reg;

endmodule
