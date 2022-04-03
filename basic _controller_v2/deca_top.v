/*
A Practical Introduction to SRAM Memories Using an FPGA (I)
https://projects.digilentinc.com/salvador-canas/a-practical-introduction-to-sram-memories-using-an-fpga-i-3f3992
https://github.com/salcanmor/SRAM-tester-for-Cmod-A7-35T/tree/master/basic%20controller


// Serial usage:   picocom --imap crcrlf /dev/ttyUSB0 
*/

module deca_top(
  // Clocks
  input wire MAX10_CLK1_50,

  // Buttons
	input wire [1:0] KEY,

  // led
  output wire [7:0] LED,

  // uart
  output wire UART_TXD,
  input wire UART_RXD,

  // sdram (sram wrapper)
  output wire [12:0] DRAM_ADDR, 
  inout  wire  [15:0] DRAM_DQ,     //inout tri
  output wire [1:0] DRAM_BA,   
  output wire DRAM_CLK,       
  output wire DRAM_CKE,
  output wire DRAM_UDQM,    
  output wire DRAM_LDQM,    
  output wire DRAM_CS_N,
  output wire DRAM_WE_N,
  output wire DRAM_RAS_N,
  output wire DRAM_CAS_N

);

wire reset;
wire clk;
assign reset = ~KEY[0];
assign LED = 8'hFE;

//assign clk = MAX10_CLK1_50;

pll pll_inst (
  .inclk0(MAX10_CLK1_50),
  .c0(clk),
  .locked()
  );


  // SRAM
wire [20:0] SRAM_ADDR;
wire [7:0] SRAM_DATA;
wire SRAM_nCE, SRAM_OE_n, SRAM_WE_n;
  
mister_sram sRam_inst ( 
  .SDRAM_A   (DRAM_ADDR ),
  .SDRAM_DQ  (DRAM_DQ   ),
  .SDRAM_BA  (DRAM_BA   ),
  .SDRAM_DQML(DRAM_LDQM ),
  .SDRAM_DQMH(DRAM_UDQM ),
  .SDRAM_nWE (DRAM_WE_N ),
  .SDRAM_nCAS(DRAM_CAS_N),
  .SDRAM_nRAS(DRAM_RAS_N),
  .SDRAM_nCS (DRAM_CS_N ),
  .SDRAM_CKE (DRAM_CKE  ),

  .SRAM_A    (SRAM_ADDR),
  .SRAM_DQ   (SRAM_DATA),
  .SRAM_nCE  (SRAM_nCE ),
  .SRAM_nOE  (SRAM_OE_n),
  .SRAM_nWE  (SRAM_WE_n)
);

assign DRAM_CLK = 1'b0;

// TOP Xilinx code
// https://projects.digilentinc.com/salvador-canas/a-practical-introduction-to-sram-memories-using-an-fpga-i-3f3992

wire [7:0] r_data_bus;
wire [7:0] w_data_bus;
wire [7:0] data_f2s_bus;
wire [7:0] data_s2f_r_bus;
wire [20:0] addr_bus;

wire button_wire;

wire tx_start, rx_done_tick, is_receiving, is_transmitting, tx_ready, mem, rw;

debouncer debouncer_unit (
  .clk(clk),     
  .PB(reset), 
  .PB_state(), 
  .PB_down(), 
  .PB_up(button_wire)
);

// Serial usage:   picocom --imap crcrlf /dev/ttyUSB0 

uart #(
    .baud_rate(9600),            // default is 9600
    .sys_clk_freq(12000000)       // default is 100000000
)
uart_unit(
    .clk(clk),                        // The master clock for this module
    .rst(button_wire),                // Synchronous reset
    .rx(UART_RXD),                    // Incoming serial line
    .tx(UART_TXD),                    // Outgoing serial line
    .transmit(tx_start),              // Signal to transmit
    .tx_byte(w_data_bus),             // Byte to transmit       
    .received(rx_done_tick),          // Indicated that a byte has been received
    .rx_byte(r_data_bus),             // Byte received
    .is_receiving(is_receiving),      // Low when receive line is idle
    .is_transmitting(is_transmitting),// Low when transmit line is idle
    .recv_error()           // Indicates error in receiving packet.
  //.recv_state(recv_state),          // for test bench
  //.tx_state(tx_state)               // for test bench
);

assign tx_ready = ~is_transmitting;


checker checker_unit (
  .clk(clk), 
  .reset(button_wire), 
  .rx_done_tick(rx_done_tick), 
  .tx_ready(tx_ready), 
  .r_data(r_data_bus), 
  .w_data(w_data_bus), 
  .tx_start(tx_start), 
  .mem(mem), 
  .rw(rw), 
  .addr(addr_bus), 
  .data_s2f_r(data_s2f_r_bus), 
  .data_f2s(data_f2s_bus)
);

sram_ctrl5 sram_ctrl_inst (
  .clk(clk), 
//.reset(reset), 
  .start_operation(1'b1),
  
  .rw(rw), 
  .address_input(addr_bus), 
  .data_f2s(data_f2s_bus), 
  
  .data_s2f(data_s2f_r_bus), 
  .address_to_sram_output(SRAM_ADDR), 
  
  .we_to_sram_output(SRAM_WE_n), 
  .oe_to_sram_output(SRAM_OE_n), 
  .ce_to_sram_output(SRAM_nCE),
  
  .data_from_to_sram_input_output(SRAM_DATA), 
  
  .data_ready_signal_output(),
  .writing_finished_signal_output(),
  .busy_signal_output()
  );


endmodule
