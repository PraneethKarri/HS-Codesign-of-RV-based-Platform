`timescale 1ns / 1ps

module Testbench();

    // Parameters
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter RAM_SIZE = 1024;
    parameter BURST_LEN = 10;
    parameter CLK_TP = 10;

    // Clock and Reset
    logic ACLK;
    logic ARESETn;
    logic ram_en;

    // Write Address channel signals
    logic AWVALID;
    logic AWREADY;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic AWBURST;
    logic [7:0] AWLEN;

    // Write Data channel signals
    logic WVALID;
    logic WREADY;
    logic [DATA_WIDTH-1:0] WDATA;
    logic WLAST;

    // Write Response channel signals
    logic BVALID;
    logic BREADY;
    logic [1:0] BRESP;

    // Read Address channel signals
    logic ARVALID;
    logic ARREADY;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic  ARBURST;
    logic [7:0] ARLEN;

    // Read Data channel signals
    logic RVALID;
    logic RREADY;
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0] RRESP;
    logic RLAST;

    // Instantiate the DUT (Device Under Test)
    axi_ram #(
        .word_size(DATA_WIDTH),
        .ram_size(RAM_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .RAM_EN(ram_en),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .AWADDR(AWADDR),
        .AWBURST(AWBURST),
        .AWLEN(AWLEN),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .WDATA(WDATA),
        .WLAST(WLAST),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .BRESP(BRESP),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .ARADDR(ARADDR),
        .ARBURST(ARBURST),
        .ARLEN(ARLEN),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .RLAST(RLAST)
    );

    // Clock Generation
    initial begin
        ACLK = 0;
        forever #(CLK_TP/2) ACLK = ~ACLK; 
    end

    // Reset Generation
    initial begin
        ARESETn = 0;
        #10 ARESETn = 1;
    end

    // Test Sequence
    initial begin
        // Initialize signals
        AWVALID = 0;
        AWADDR = 0;
        AWBURST = 1; // Incremental burst
        AWLEN = BURST_LEN;
        WVALID = 0;
        WDATA = 0;
        WLAST = 0;
        BREADY = 0;
        ARVALID = 0;
        ARADDR = 0;
        ARBURST = 1; // Incremental burst
        ARLEN = BURST_LEN;
        RREADY = 0;
        ram_en = 1;

        // Wait for reset deassertion
        wait (ARESETn == 1);
        #5; // Add a small delay after reset deassertion

        // Perform Incremental Write Burst Transaction
        $display("Performing Incremental Write Burst Transaction");
        perform_write_burst(16'h0005, BURST_LEN, 1);

        // Perform Incremental Read Burst Transaction
        $display("Performing Incremental Read Burst Transaction");
        perform_read_burst(16'h0005, BURST_LEN, 1);

        // End of test
        $display("Test completed successfully");
        #50
        $finish;
    end

    // Task for performing write burst transaction
    task perform_write_burst(input [ADDR_WIDTH-1:0] start_addr, input [7:0] len, input burst_type);
        begin
            // Write Address Channel
            AWADDR <= start_addr;
            AWBURST <= burst_type;
            AWLEN <= len;
            AWVALID <= 1;
            wait (AWREADY);
            wait(~ACLK);
            wait(ACLK); #1 
            AWADDR <= 0;
            AWBURST <=0;
            AWLEN <= 0;
            AWVALID <= 0;

            // Write Data Channel
            for (int i = 0; i < len; i++) begin
                WDATA = 32'h00000005 + i;
                WVALID = 1;
                WLAST = (i == (len - 1));
                wait (WREADY);
                wait(~ACLK);
                wait(ACLK);#1
                if(WLAST) 
                begin
                WVALID <=0;
                WDATA <= 0;
                WLAST <= 0;
                end
            end
            

            // Write Response Channel
            BREADY = 1;
            wait (BVALID);
//            if (BRESP != 1) $fatal("Write transaction failed");
            wait(~ACLK);
            wait(ACLK); #1
            BREADY = 0;
        end
    endtask

    // Task for performing read burst transaction
    task perform_read_burst(input [ADDR_WIDTH-1:0] start_addr, input [7:0] len, input burst_type);
        begin
            // Read Address Channel
            ARADDR <= start_addr;
            ARBURST <= burst_type;
            ARLEN <= len;
            ARVALID <= 1;
            wait (ARREADY);
            wait(~ACLK);
            wait(ACLK); #2 
            ARADDR <= 0;
            ARBURST <= 0;
            ARLEN <= 0;
            ARVALID <= 0;

            // Read Data Channel
            for (int i = 0; i < len; i++) begin
                RREADY = 1;
//                if (RRESP != 1) $fatal("Read transaction failed");
                wait (RVALID);
                wait(~ACLK);
                wait(ACLK); #1 RREADY = 0;
            end
        end
    endtask
endmodule
