`timescale 1ns / 1ps

module sram_ctrl5(clk, start_operation, rw, address_input, data_f2s, data_s2f, address_to_sram_output, we_to_sram_output, oe_to_sram_output, ce_to_sram_output, data_from_to_sram_input_output, data_ready_signal_output, writing_finished_signal_output, busy_signal_output);

  input wire clk ;                                 //  Clock signal

  input wire start_operation;                      //  start operation signal

  input wire rw;                                   //  With this signal, we select reading or writing operation
  input wire [20:0] address_input;                 //  Address bus
  input wire [7:0] data_f2s;                       //  Data to be writteb in the SRAM

  output wire [7:0] data_s2f;                      //  It is the 8-bit registered data retrieved from the SRAM (the -s2f suffix stands for SRAM to FPGA)
  output reg [20:0] address_to_sram_output;        //  Address bus

  output reg we_to_sram_output;                    //  Write enable (active-low)
  output reg oe_to_sram_output;                    //  Output enable (active-low)
  output reg ce_to_sram_output;                    //  Chip enable (active-low). Disables or enables the chip.

  inout wire [7:0] data_from_to_sram_input_output; //  Data bus

  output reg data_ready_signal_output;             //   Ready signal
  output reg writing_finished_signal_output;       //   Writing finished signal
  output reg busy_signal_output;                   //   Busy signal


  //FSM states declaration
  localparam [1:0]
  idle   =   2'b00,
  rd0    =   2'b01,
  wr0    =   2'b10;

  //	signal declaration
  reg [3:0] state_reg;

  reg [7:0] register_for_reading_data;
  reg [7:0] register_for_writing_data;

  reg register_for_splitting;

  initial
    begin

      ce_to_sram_output<=1'b1;
      oe_to_sram_output<=1'b1;
      we_to_sram_output<=1'b1;

      state_reg <= idle;

      register_for_reading_data[7:0]<=8'b0000_0000;
      register_for_writing_data[7:0]<=8'b0000_0000;

      register_for_splitting<=1'b0;

      data_ready_signal_output<=1'b0;
      writing_finished_signal_output<=1'b0;
      busy_signal_output<=1'b0;

    end

  always@(posedge clk)
    begin

      case(state_reg)
        idle: 
          begin

            register_for_splitting<=1'b0;                       //  We configure the data bus for reading
            writing_finished_signal_output<=1'b1;               //  The write operation is not in process

            ce_to_sram_output<=1'b0;
            oe_to_sram_output<=1'b0;
            we_to_sram_output<=1'b1;

            busy_signal_output<=1'b0;                           //  The controller is not busy

            data_ready_signal_output<=1'b0;                     //  No data ready for reading

            if(~start_operation)
              state_reg <= idle;
            else begin
              if(rw) begin

                address_to_sram_output[20:0]<=address_input[20:0];

                state_reg <= rd0;

              end
              else  begin

                address_to_sram_output[20:0]<=address_input[20:0];
                register_for_writing_data[7:0]<=data_f2s[7:0];

                state_reg <= wr0;


              end
            end
          end

        //============================== READING PHASE ==============================

        rd0:
          begin
            register_for_reading_data[7:0]<=data_from_to_sram_input_output[7:0];

            data_ready_signal_output<=1'b1;
            busy_signal_output<=1'b1;

            state_reg <= idle;
          end


        //============================== WRITING PHASE ==============================

        wr0:
          begin
            ce_to_sram_output<=1'b0;
            oe_to_sram_output<=1'b1;
            we_to_sram_output<=1'b0;

            busy_signal_output<=1'b1;
            writing_finished_signal_output<=1'b0;

            register_for_splitting<=1'b1;

            state_reg <= idle;

          end

      endcase

    end

  assign data_s2f = register_for_reading_data;

  assign data_from_to_sram_input_output = (register_for_splitting) ? register_for_writing_data : 8'bz;

endmodule   
