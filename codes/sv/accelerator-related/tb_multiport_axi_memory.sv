`timescale 1ns / 1ps

module tb_multiport_axi_memory();

    // Parameters
    parameter Num_Subbanks = 32;
    parameter Subbank_size = 32;
    parameter R_ADDR_WIDTH = 5 ;
    parameter W_ADDR_WIDTH = 10 ;
    parameter DATA_WIDTH = 32;
    parameter BURST_LEN = 31;
    parameter CLK_TP = 10;



    // Clock and Reset
    logic ACLK;
    logic ARESETn;
    logic w_en;
    logic r_en;

    // Write Address channel signals
    logic AWVALID;
    logic AWREADY;
    logic [W_ADDR_WIDTH-1:0] AWADDR;
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
    logic [R_ADDR_WIDTH-1:0] ARADDR;

    // Read Data channel signals
    logic  [0:Num_Subbanks-1] RVALID;
    logic  [0:Num_Subbanks-1] RREADY;
    logic [0:Num_Subbanks-1] [DATA_WIDTH-1:0] RDATA ;
    logic [0:Num_Subbanks-1] [1:0]  RRESP;

    // Instantiate the DUT (Device Under Test)
    multirport_axi_memory #(
        .Num_Subbanks(Num_Subbanks),
        .Subbank_size(Subbank_size),
        .word_size(DATA_WIDTH),
        .R_ADDR_WIDTH(R_ADDR_WIDTH),
        .W_ADDR_WIDTH(W_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
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
        .RVALID(RVALID),
        .RREADY(RREADY),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .W_EN(w_en),
        .R_EN(r_en)
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
        for(int i = 0; i<Num_Subbanks;i++)
        RREADY[i] = 0;
        
        r_en = 0;
        

        // Wait for reset deassertion
        wait (ARESETn == 1);
        #5; // Add a small delay after reset deassertion

        // Perform Incremental Write Burst Transaction
        $display("Performing Incremental Write Burst Transaction");

        for(int i = 0; i < Num_Subbanks ; i++)
        begin
        perform_write_burst('d0 + Subbank_size*i,BURST_LEN, 1);
        end

//          perform_write_burst('d0,BURST_LEN,1);
          
          
        // Perform Incremental Read Burst Transaction
        $display("Performing Incremental Read Burst Transaction");
        for(int i = 0; i < Subbank_size ; i++)
        begin
        perform_read('d0+i);
        end

        // End of test
        $display("Test completed successfully");
        #50
        $finish;
    end

    // Task for performing write burst transaction
    task perform_write_burst(input [W_ADDR_WIDTH-1:0] start_addr, input [7:0] len, input burst_type);
        begin
            // Write Address Channel
            w_en = 1;
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
            
             wait (WREADY);#2
            // Write Data Channel
            for (int i = 0; i <= len; i++) begin
                
                WDATA =  (start_addr+i+1);
                WVALID = 1;
                WLAST = (i == (len));
                
//                if (i == 0)
//                begin
//                wait(~ACLK);
//                wait(ACLK);
//                end
                
                wait(~ACLK);
                wait(ACLK);#1;
                
                if(WLAST) 
                begin
                WVALID <=0;
                WDATA  <= 0;
                WLAST  <= 0;
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
        wait(~ACLK);
        wait(ACLK); #1
        w_en = 0;
    endtask

    // Task for performing read burst transaction
    task perform_read(input [R_ADDR_WIDTH-1:0] addr);
        begin
            // Read Address Channel
             r_en = 1;
            ARADDR <= addr;
            ARVALID <= 1;
            wait (ARREADY);
            wait(~ACLK);
            wait(ACLK); #2 
            ARADDR <= 0;
            ARVALID <= 0;

            // Read Data Channel
               
                RREADY = 32'hffffffff;
////                if (RRESP != 1) $fatal("Read transaction failed");
//                wait (RVALID[i]);
//                wait(~ACLK);
//                wait(ACLK); #1 RREADY = 0;
            end
    endtask
endmodule
