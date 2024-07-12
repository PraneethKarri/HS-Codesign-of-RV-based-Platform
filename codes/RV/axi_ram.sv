`timescale 1ns / 1ps

module axi_ram #(
// Parameters for RAM
parameter word_size = 32, // Word size in bits
parameter ram_size = 1024, // RAM size in words

// Parameters for AXI interface
parameter ADDR_WIDTH = 16, // Address width
parameter DATA_WIDTH = 32 // Data width
)(
// Global Signals
input logic ACLK, // Clock signal
input logic ARESETn, // Active low reset

// Control Signals
input logic RAM_EN,

// Write Address channel signals
input logic AWVALID, // Write address valid
output logic AWREADY, // Write address ready
input logic [ADDR_WIDTH-1:0] AWADDR, // Write address
input logic AWBURST, // Write burst type
input logic [7:0] AWLEN, // Write burst length

// Write Data channel signals
input logic WVALID, // Write data valid
output logic WREADY, // Write data ready
input logic [DATA_WIDTH-1:0] WDATA,// Write data
input logic WLAST, // Write last signal

// Write Response channel signals
output logic BVALID, // Write response valid
input logic BREADY, // Write response ready
output logic [1:0] BRESP, // Write response

// Read Address channel signals
input logic ARVALID, // Read address valid
output logic ARREADY, // Read address ready
input logic [ADDR_WIDTH-1:0] ARADDR, // Read address
input logic [1:0] ARBURST, // Read burst type
input logic [7:0] ARLEN, // Read burst length

// Read Data channel signals
output logic RVALID, // Read data valid
input logic RREADY, // Read data ready
output logic [DATA_WIDTH-1:0] RDATA,// Read data
output logic [1:0] RRESP, // Read response
output logic RLAST // Read last signal
);

typedef enum {waready, wdready, wrready} wprog; // Write transaction states
typedef enum {raready, rdready} rprog; // Read transaction states

logic [word_size-1:0] ram [0:ram_size]; // RAM array

// Address and burst control signals
logic [ADDR_WIDTH-1:0] base_burst_waddr, base_burst_raddr, waddr, raddr;
logic wburst_type, rburst_type;
logic [7:0] wburst_len, rburst_len;
wprog wtransac_prog;
rprog rtransac_prog;
logic werror, rerror;

// Reset logic
always_ff @ (posedge ACLK)
if (!ARESETn && RAM_EN)
begin

 // Initialize control signals
  base_burst_waddr <= 'b0;
  base_burst_raddr <= 'b0;
  waddr <= 'b0;
  raddr <= 'b0;
  wtransac_prog <= waready;
  rtransac_prog <= raready;
  wburst_type <= 'b0;
  wburst_len <= 'b0;
  rburst_type <= 'b0;
  rburst_len <= 'b0;
  werror <= 'b0;
  rerror <= 'b0; 

  AWREADY <= 'b0;
  WREADY <= 'b0;
  BVALID <= 'b0;
  BRESP <= 'b0;
  ARREADY <= 'b0;
  RVALID <= 'b0;
  RRESP <= 'b0;
  RLAST <= 'b0;
  RDATA <= 'b0;
end

// Write address channel logic
always_ff @ (posedge ACLK)
if (ARESETn && RAM_EN)
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
if (ARESETn && RAM_EN)
begin
 WREADY <= (wtransac_prog == wdready) ? 1 : 0;
 if (WVALID & WREADY)
  case (wburst_type)
   0: begin // Fixed burst
       if (base_burst_waddr < ram_size)
       begin
        waddr <= base_burst_waddr;
        ram[waddr] <= WDATA;
        werror = 0;
       end
       else werror = 1;
       WREADY <= WLAST ? 0 : 1;
       wtransac_prog <= WLAST ? wrready : wtransac_prog;
      end
   1: begin // Incremental burst
       if (base_burst_waddr < ram_size - wburst_len + 1)
       begin
        if (waddr < base_burst_waddr + wburst_len)
        begin
         ram[waddr] <= WDATA;
         waddr <= waddr + 1;
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
if (ARESETn && RAM_EN)
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

// Read address channel logic
always_ff @ (posedge ACLK)
if (ARESETn && RAM_EN)
begin
 if (ARVALID & ~ARREADY)
  ARREADY <= (rtransac_prog == raready) ? 1 : 0;
 else if (ARVALID & ARREADY)
 begin
 base_burst_raddr <= ARADDR;
 raddr <= ARADDR;
 rburst_type <= ARBURST;
 rburst_len <= ARLEN;
 ARREADY <= 'b0;
 rtransac_prog <= rdready;
 end
 else ARREADY <= 'b0;
end

// Read data channel logic
always_ff @ (posedge ACLK)
if (ARESETn && RAM_EN)
begin
 if (RREADY & (rtransac_prog == rdready))
  case (rburst_type)
  0: begin // Fixed burst
      if (base_burst_raddr < ram_size)
      begin
      raddr <= base_burst_raddr;
      RDATA <= ram[raddr];
      rerror = 0;
      end
      else rerror = 1;
      RVALID <= 1;
      RLAST <= 1;
      RRESP <= rerror ? 2'b10 : 2'b01;
      rtransac_prog <= raready;
     end
  1: begin // Incremental burst
      if (base_burst_raddr < ram_size - rburst_len + 1)
      begin
       if (raddr < base_burst_raddr + rburst_len)
       begin
        RDATA <= ram[raddr];
        RVALID <= 1;
        rerror <= 0;
        RLAST <= (raddr == base_burst_raddr + rburst_len - 1) ? 1 : 0;
        raddr <= raddr + 1;
        rtransac_prog <= RLAST ? raready : rtransac_prog;
        RRESP <= rerror ? 2'b10 : 2'b01;
       end
       else 
       begin
       RDATA <= 'b0;
       RVALID <= 'b0;
       RLAST <= 'b0;
       RRESP <= 'b0;
       end
      end
      else rerror <= 1;
      end
  endcase
 else
 begin
  RVALID <= 'b0;
  RDATA <= 'b0;
  RRESP <= 'b0;
  RLAST <= 'b0;
 end
end

endmodule : axi_ram