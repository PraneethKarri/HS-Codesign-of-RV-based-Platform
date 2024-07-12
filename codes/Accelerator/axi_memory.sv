`timescale 1ns / 1ps

// Title       : AXI Read enabled memory
// Designer    : Praneeth KSS
// Project     : HW - SW Codesign
// Description : This is a memory that supports traditional write transaction and a AXI based read transaction.
// version     : 1

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

input logic [ADDR_WIDTH-1:0] AWADDR, // Write address
input logic [DATA_WIDTH-1:0] WDATA,// Write data

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

typedef enum {raready, rdready} rprog; // Read transaction states

logic [0:memory_size - 1][word_size-1:0] memory; // memory array

// Address and burst control signals
logic [ADDR_WIDTH-1:0] raddr;
rprog rtransac_prog;
logic rerror;

// Reset logic
always_ff @ (posedge ACLK)
if (!ARESETn )
begin
 // Initialize control signals
  raddr <= 'b0;
  rtransac_prog <= raready;
  rerror <= 'b0; 

  ARREADY <= 'b0;
  RVALID <= 'b0;
  RRESP <= 'b0;
  RDATA <= 'b0;
end

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