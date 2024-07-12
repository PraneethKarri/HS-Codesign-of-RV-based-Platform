`timescale 1ns / 1ps

// Title       : Multi Addressable AXI Memory
// Designer    : Praneeth KSS
// Project     : HW - SW Codesign
// Description : Contains multiple subbanks of memories and suppored AXI based read and write transactions. 
//               Data from all the subbanks is read concurrently based on single read address channel.
//               This supports both fixed and burst transactions for write operation. 
// version     : 1                 

module multirport_axi_memory #(

/// Parameters for Top Memory Module
parameter Num_Subbanks = 32,// No.of sub memory banks
parameter Subbank_size = 32,// size of each sub memory bank

// Parameters for RAM
parameter word_size = 32, // Word size in bits

// Parameters for AXI interface
parameter R_ADDR_WIDTH = 5, // Read Address width
parameter W_ADDR_WIDTH = 10, // Write Address width
parameter DATA_WIDTH = 32 // Data width 
)(
// Global Signals
input logic ACLK, // Clock signal
input logic ARESETn, // Active low reset

// Control Signals
input logic W_EN,
input logic R_EN,

// Write Address channel signals
input logic  AWVALID, // Write address valid
output logic AWREADY, // Write address ready
input logic  [W_ADDR_WIDTH-1:0] AWADDR, // Write address
input logic  AWBURST, // Write burst type
input logic  [7:0] AWLEN, // Write burst length

// Write Data channel signals
input logic  WVALID, // Write data valid
output logic WREADY, // Write data ready
input logic  [DATA_WIDTH-1:0] WDATA,// Write data
input logic  WLAST, // Write last signal

// Write Response channel signals
output logic BVALID, // Write response valid
input logic BREADY, // Write response ready
output logic [1:0] BRESP, // Write response

// Read Address channel signals
input logic ARVALID, // Read address valid
output logic ARREADY, // Read address ready
input logic [R_ADDR_WIDTH-1:0] ARADDR, // Read address

// Read Data channel signals
output logic  [0:Num_Subbanks-1] RVALID, // Read data valid
input logic  [0:Num_Subbanks-1] RREADY, // Read data ready
output logic [0:Num_Subbanks-1]  [DATA_WIDTH-1:0] RDATA,// Read data
output logic  [0:Num_Subbanks-1] [1:0]   RRESP  // Read response
);

// Write transaction status
typedef enum logic [1:0] {waready = 2'b00, wdready = 2'b01, wrready = 2'b10 } wprog; 

// Address and burst control signals
logic [W_ADDR_WIDTH-1:0]base_burst_waddr, waddr;
logic wburst_type;
logic [7:0] wburst_len;
wprog wtransac_prog;
logic werror;
logic [0:Num_Subbanks-1] write_en,arready;

// Reset logic
always_ff @ (posedge ACLK)
if (!ARESETn )
begin
// Initialize control signals
  base_burst_waddr <= 'b0;
  waddr <= 'b0;
  wtransac_prog <= waready;
  wburst_type <= 'b0;
  wburst_len <= 'b0;
  werror <= 'b0;

  AWREADY <= 'b0;
  WREADY <= 'b0;
  BVALID <= 'b0;
  BRESP <= 'b0;
end

// Write address channel logic
always_ff @ (posedge ACLK)
if (ARESETn && W_EN)
begin
 if (AWVALID & ~AWREADY)
  AWREADY <= (wtransac_prog == waready) ? 1 : 0;
 else if (AWVALID & AWREADY)
 begin
 base_burst_waddr <= AWADDR;
 waddr <= AWADDR;
 wburst_type <= AWBURST;
 wburst_len <= AWLEN;
 AWREADY <= 'b0;
 wtransac_prog <= wdready;
 end
 else AWREADY <= 'b0;
end

// Write data channel logic
always_ff @ (posedge ACLK)
if (ARESETn && W_EN)
begin
 if(~WREADY)
 WREADY <= (wtransac_prog == wdready) ? 1 : 0;
 else if (WVALID & WREADY)
  case (wburst_type)
   0: begin // Fixed burst
       if (base_burst_waddr < Num_Subbanks * Subbank_size)
       begin
        waddr <= base_burst_waddr;
        werror = 0;
       end
       else werror = 1;
       WREADY <= WLAST ? 0 : 1;
       wtransac_prog <= WLAST ? wrready : wtransac_prog;
      end
   1: begin // Incremental burst
       if (base_burst_waddr < (Num_Subbanks * Subbank_size - wburst_len ))
       begin
        if (waddr <= base_burst_waddr + wburst_len)
        begin
         waddr <= waddr+1;
         werror <= 0;
        end
       end
       else werror <= 1;
       WREADY <= WLAST ? 0 : 1;
       wtransac_prog <= WLAST ? wrready : wtransac_prog;
      end
  endcase
  
end

// Write response channel logic
always_ff @ (posedge ACLK)
if (ARESETn && W_EN)
begin
 if (BREADY && (wtransac_prog == wrready))
 begin
  BRESP <= werror? 2'b10 : 2'b01;;
  BVALID <= 1;
  wtransac_prog <= waready;
 end
 else
 begin
  BVALID <= 'b0;
  BRESP <= 'b0;
 end
end

// Read Address signal logic
assign ARREADY = &arready;

// Write enable logic for Subbanks
always_comb
begin
write_en = 'b0;
write_en[waddr[W_ADDR_WIDTH-1:R_ADDR_WIDTH]] = W_EN & (wtransac_prog == wdready)  ;
end

// Subbanks generation
generate
for( genvar i = 0; i < Num_Subbanks;i++ )
axi_memory #(
        .word_size(word_size),
        .memory_size(Subbank_size),
        .ADDR_WIDTH(R_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem_subbank (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .AWADDR(waddr[R_ADDR_WIDTH-1:0]),
        .WDATA(WDATA),
        .ARVALID(ARVALID),
        .ARREADY(arready[i]),
        .ARADDR(ARADDR),
        .RVALID(RVALID[i]),
        .RREADY(RREADY[i]),
        .RDATA(RDATA[i]),
        .RRESP(RRESP[i]),
        .R_EN(R_EN),
        .W_EN(write_en[i])
    );
endgenerate
    
// Note : Read channels are defined in mem_subbank.

endmodule :multirport_axi_memory