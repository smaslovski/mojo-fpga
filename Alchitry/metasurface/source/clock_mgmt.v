module clock_mgmt (
    input  wire clk,      // 50 MHz external clock input
    input  wire rst,      // asynchronous reset input
    output wire clk_rdy,  // set to 1 when clk_int signal is valid
    output wire clk_int   // internal 5.0 MHz clock output
  );
  
  wire clk_ibufg;
  wire clk_dcm_out;
  
  // Spartan-6's input clock buffer
  
  IBUFG
  clk_ibufg_inst(
    .I(clk),
    .O(clk_ibufg)
  );
  
  // Spartan-6's Digital Clock Management block used as a frequency divider by 10
  
  DCM_SP #(
    .CLKIN_PERIOD(20),
    .CLK_FEEDBACK("NONE"),
    .CLKDV_DIVIDE(10.0),
    .CLKFX_MULTIPLY(1.0),
    .CLKFX_DIVIDE(1.0),
    .PHASE_SHIFT(0),
    .CLKOUT_PHASE_SHIFT("NONE"),
    .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
    .STARTUP_WAIT("FALSE"),
    .CLKIN_DIVIDE_BY_2("FALSE")
  )
  clk_dcm_inst (
    .CLKIN(clk_ibufg),
    .CLKFB(1'b0),
    .RST(rst),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSCLK(1'b0),
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLKDV(clk_dcm_out),
    .CLKFX(),
    .CLKFX180(),
    .STATUS(),
    .LOCKED(clk_rdy),
    .PSDONE()
  );
  
  // Spartan-6 output clock buffer
  
  BUFG
  clk_bufg_inst (
    .I(clk_dcm_out),
    .O(clk_int)
  );
  
endmodule