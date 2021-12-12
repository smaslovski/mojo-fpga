module mojo_top(
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input rst_n,
    // cclk input from AVR, high when AVR is ready
    input cclk,
    // Outputs to the 8 onboard LEDs
    output [7:0] led,
    // PWM outputs
    output reg [9:0] pwm,
    // AVR SPI connections
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy // AVR Rx buffer full
  );
  
  wire clk_rdy;            // internal clock ready
  wire clk_int;            // internal 5.0 MHz clock signal
  wire rst = ~rst_n;       // make async reset active high
  wire rst_int = ~clk_rdy; // internal synchronous reset
  
  // Clock management module instance
  
  clock_mgmt
  cm_inst (
    .clk(clk),
    .rst(rst),
    .clk_rdy(clk_rdy),
    .clk_int(clk_int)
  );
  
  wire [7:0] rx_data; // rx data from avr to board
  wire new_rx_data;   // flag
  
  // Mojo's avr interface module instance
  // this module allows us to communicate with the FPGA
  
  avr_interface #(
    .CLK_FREQ(5000000),
    .BAUD(500000)
  )
  ai_inst (
    .clk(clk_int),                 // connect to internal clk
    .rst(rst_int),                 // connect to internal reset
    .cclk(cclk),
    .spi_miso(spi_miso),           // connect to spi_miso
    .spi_mosi(spi_mosi),           // connect to spi_mosi
    .spi_sck(spi_sck),             // connect to spi_sck
    .spi_ss(spi_ss),               // connect to spi_ss
    .spi_channel(spi_channel),     // connect to spi_channel
    
    // AVR Serial Signals
    .tx(avr_rx),                   // connect to avr_rx (note that tx->rx)
    .rx(avr_tx),                   // connect to avr_tx (note that rx->tx)
    
    // ADC Interface Signals
    .channel(hF),                  // ADC channel to read from, use hF to disable ADC
    .new_sample(),                 // new ADC sample flag
    .sample(),                     // ADC sample data
    .sample_channel(),             // channel of the new sample
    
    // Serial TX User Interface
    .tx_data(8'b00000000),         // data to send
    .new_tx_data(1'b0),            // new data flag (1 = new data)
    .tx_busy(),                    // transmitter is busy flag (1 = busy)
    .tx_block(avr_rx_busy),        // block the transmitter (1 = block) connect to avr_rx_busy
    
    // Serial RX User Interface
    .rx_data(rx_data),             // data received
    .new_rx_data(new_rx_data)      // new data flag (1 = new data)
  );
    
  // reading of configuration data
  
  reg [7:0] mem[0:9]; // small memory to store the pulse durations for 10 channels
  reg [3:0] addr;     // address (0-9)

  // for debugging
  assign led[7:4] = 4'b0;
  assign led[3:0] = addr;
    
  integer n;
  reg old_new_rx_data;
  
  always @(posedge clk_int)
    if (rst_int)
      begin
        for (n = 0; n < 10; n = n + 1)
          mem[n] <= 8'b0;
        addr <= 4'b0;
        old_new_rx_data <= 1'b0;
      end
    else
      begin
        if (new_rx_data & ~old_new_rx_data)
          begin
            mem[addr] <= rx_data;
            addr <= addr < 9 ? addr + 1 : 0;
          end
        old_new_rx_data <= new_rx_data;
      end
  
  // generation of PWM signals
  
  reg [7:0] cnt;      // counter
  
  always @(posedge clk_int)
    if (rst_int)
      begin
        cnt <= 8'b0;
        pwm <= 10'b0;
      end
    else
      begin
        for (n = 0; n < 10; n = n + 1)
          if (mem[n] <= cnt)
            pwm[n] <= 1'b0;
          else
            pwm[n] <= 1'b1;
        cnt <= cnt + 1;
      end

endmodule