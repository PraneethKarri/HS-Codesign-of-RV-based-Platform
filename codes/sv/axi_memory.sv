`timescale 1ns / 1ps

module axi_memory #(
// Parameters for memory
parameter word_size = 32, // Word size in bits
parameter memory_size = 32, // memory size in words

// Parameters for AXI interface
parameter ADDR_WIDTH = 5, // Address width
parameter DATA_WIDTH = 32 // Data width
)(
// Global Signals
input logic ACLK, // Clock signal
input logic ARESETn, // Active low reset

// Control Signals
input logic R_EN,
input logic W_EN,

// Write Address channel signals
//input logic AWVALID, // Write address valid
//output logic AWREADY, // Write address ready
input logic [ADDR_WIDTH-1:0] AWADDR, // Write address
//input logic AWBURST, // Write burst type
//input logic [7:0] AWLEN, // Write burst length

// Write Data channel signals
//input logic WVALID, // Write data valid
//output logic WREADY, // Write data ready
input logic [DATA_WIDTH-1:0] WDATA,// Write data
//input logic WLAST, // Write last signal

// Write Response channel signals
//output logic BVALID, // Write response valid
//input logic BREADY, // Write response ready
//output logic [1:0] BRESP, // Write response

// Read Address channel signals
input logic ARVALID, // Read address valid
output logic ARREADY, // Read address ready
input logic [ADDR_WIDTH-1:0] ARADDR, // Read address

// Read Data channel signals
output logic RVALID, // Read data valid
input logic RREADY, // Read data ready
output logic  [DATA_WIDTH-1:0] RDATA ,// Read data
output logic [1:0]  RRESP // Read response
);

//typedef enum {waready, wdready, wrready} wprog; // Write transaction states
typedef enum {raready, rdready} rprog; // Read transaction states

logic [0:memory_size - 1][word_size-1:0] memory; // memory array

// Address and burst control signals
logic [ADDR_WIDTH-1:0]/* base_burst_waddr, waddr,*/ raddr;
//logic wburst_type;
//logic [7:0] wburst_len;
//wprog wtransac_prog;
rprog rtransac_prog;
logic rerror/* ,werror*/;

// Reset logic
always_ff @ (posedge ACLK)
if (!ARESETn )
begin
 // Initialize control signals
//  base_burst_waddr <= 'b0;
//  waddr <= 'b0;
  raddr <= 'b0;
//  wtransac_prog <= waready;
  rtransac_prog <= raready;
//  wburst_type <= 'b0;
//  wburst_len <= 'b0;
//  werror <= 'b0;
  rerror <= 'b0; 

//  AWREADY <= 'b0;
//  WREADY <= 'b0;
//  BVALID <= 'b0;
//  BRESP <= 'b0;
  ARREADY <= 'b0;
  RVALID <= 'b0;
  RRESP <= 'b0;
  RDATA <= 'b0;
end

// Write address channel logic
//always_ff @ (posedge ACLK)
//if (ARESETn && W_EN)
//begin
// if (AWVALID & ~AWREADY)
//  AWREADY <= (wtransac_prog == waready) ? 1 : 0;
// else if (AWVALID & AWREADY)
// begin
// base_burst_waddr <= AWADDR;
// waddr <= AWADDR;
// wburst_type <= AWBURST;
// wburst_len <= AWLEN;
// AWREADY <= 'b0;
// wtransac_prog <= wdready;
// end
// else AWREADY <= 'b0;
//end

// Write data channel logic
//always_ff @ (posedge ACLK)
//if (ARESETn && W_EN)
//begin
// WREADY <= (wtransac_prog == wdready) ? 1 : 0;
// if (WVALID & WREADY)
//  case (wburst_type)
//   0: begin // Fixed burst
//       if (base_burst_waddr < memory_size)
//       begin
//        waddr <= base_burst_waddr;
//        memory[waddr] <= WDATA;
//        werror = 0;
//       end
//       else werror = 1;
//       WREADY <= WLAST ? 0 : 1;
//       wtransac_prog <= WLAST ? wrready : wtransac_prog;
//      end
//   1: begin // Incremental burst
//       if (base_burst_waddr < memory_size - wburst_len + 1)
//       begin
//        if (waddr < base_burst_waddr + wburst_len)
//        begin
//         memory[waddr] <= WDATA;
//         waddr <= waddr + 1;
//         werror <= 0;
//        end
//       end
//       else werror <= 1;
//       WREADY <= WLAST ? 0 : 1;
//       wtransac_prog <= WLAST ? wrready : wtransac_prog;
//      end
//  endcase
//end

// Write response channel logic
//always_ff @ (posedge ACLK)
//if (ARESETn && W_EN)
//begin
// if (BREADY && (wtransac_prog == wrready))
// begin
//  BRESP <= werror? 2'b10 : 2'b01;;
//  BVALID <= 1;
//  wtransac_prog <= waready;
// end
// else
// begin
//  BVALID <= 'b0;
//  BRESP <= 'b0;
// end
//end

// Write logic
always_ff @(negedge ACLK)
if(W_EN)
memory[AWADDR] <= WDATA ;

// Read address channel logic
always_ff @ (posedge ACLK)
if (ARESETn && R_EN)
begin
 if (ARVALID & ~ARREADY)
  ARREADY <= (rtransac_prog == raready) ? 1 : 0;
 else if (ARVALID & ARREADY)
 begin
 raddr <= ARADDR;
 ARREADY <= 'b0;
 rtransac_prog <= rdready;
 end
 else ARREADY <= 'b0;
end

// Read data channel logic
always_ff @ (posedge ACLK)
if (ARESETn && R_EN)
begin
 if (RREADY & (rtransac_prog == rdready))
  begin // Fixed burst
   if (raddr < memory_size)
   begin
   RDATA <= memory[raddr];
   rerror = 0;
   end
   else rerror = 1;
   RVALID <= 1;
   RRESP <= rerror ? 2'b10 : 2'b01;
   rtransac_prog <= raready;
  end
 else
 begin
  RVALID <= 'b0;
  RDATA <= 'b0;
  RRESP <= 'b0;
 end
end

endmodule : axi_memory