`timescale 1ns / 1ps

module ddr_ram_controller_mig #(
	parameter BOARD = "",
	localparam DATA_WIDTH  = (BOARD == "NEXYS_VIDEO")	? 128 :
							 (BOARD == "GENESYS_2")		? 256 :
							 (BOARD == "NEXYS_DDR")		? 128 : 0,
	localparam ADDR_WIDTH  = (BOARD == "NEXYS_VIDEO")	? 26:
							 (BOARD == "GENESYS_2")		? 25 :
						     (BOARD == "NEXYS_DDR")		? 24 : 0,
	localparam DDR_ADDR    = (BOARD == "NEXYS_VIDEO")	? 15:
							 (BOARD == "GENESYS_2")		? 15:
							 (BOARD == "NEXYS_DDR")		? 13 : 0,
	localparam APP_ADDR    =    (BOARD == "NEXYS_VIDEO")	    ? 29:
                                (BOARD == "GENESYS_2")		? 29:
                                (BOARD == "NEXYS_DDR")		? 27 : 0,
    localparam DDR_DQ_WIDTH =   (BOARD == "NEXYS_VIDEO")	    ? 16:
                                (BOARD == "GENESYS_2")		? 32:
                                (BOARD == "NEXYS_DDR")		? 16 : 0,
    localparam DDR_DQS_WIDTH =  (BOARD == "NEXYS_VIDEO")	    ? 2:
                                (BOARD == "GENESYS_2")		? 4:
                                (BOARD == "NEXYS_DDR")		? 2 : 0,
    localparam DDR_MASK_WIDTH = (BOARD == "NEXYS_VIDEO")	    ? 16:
                                (BOARD == "GENESYS_2")		? 32:
                                (BOARD == "NEXYS_DDR")		? 16 : 0
	)(
	// User interface ports
    output						ui_clk,
    output						ui_clk_sync_rst,
    input	[ADDR_WIDTH-1:0]	wr_addr,
    input	[DATA_WIDTH-1:0]	wr_data,
    input	[ADDR_WIDTH-1:0]	rd_addr,
	output	[DATA_WIDTH-1:0]	rd_data,
    input						wr_en,
    input 						rd_en,
	output reg					wr_busy,
	output reg					rd_busy,
    output                      rd_data_valid,
    // Physical ports
    input                       clk,
    input                       clk_ref,
    input                       clk_p,
    input                       clk_n,
    input                       rst,
    output  [DDR_ADDR-1:0]      ddr_addr,
    output  [2:0]               ddr_ba,
    output                      ddr_cas_n,
    output                      ddr_ck_n,
    output                      ddr_ck_p,
    output                      ddr_cke,
    output                      ddr_ras_n,
    output                      ddr_reset_n,
    output                      ddr_we_n,
    inout   [DDR_DQ_WIDTH-1:0]  ddr_dq,
    inout   [DDR_DQS_WIDTH-1:0] ddr_dqs_n,
    inout   [DDR_DQS_WIDTH-1:0] ddr_dqs_p,
    output                      ddr_cs_n,
    output  [DDR_DQS_WIDTH-1:0] ddr_dm,
    output                      ddr_odt
    );

    // Memory interface MIG
    reg [APP_ADDR-1:0]          app_addr;
    reg [2:0]                   app_cmd;
    reg                         app_en;
    reg  [DATA_WIDTH-1:0]       app_wdf_data;
    reg                         app_wdf_end;
    reg                         app_wdf_wren;
    wire [DATA_WIDTH-1:0]       app_rd_data;
    wire                        app_rd_data_end;
    wire                        app_rd_data_valid;
    wire                        app_rdy;
    wire                        app_wdf_rdy;
    wire                        app_sr_req;
    wire                        app_ref_req;
    wire                        app_zq_req;
    wire                        app_sr_active;
    wire                        app_ref_ack;
    wire                        app_zq_ack;
    wire [DDR_MASK_WIDTH-1:0]   app_wdf_mask;
    wire                        init_calib_complete;

    generate
    if (BOARD=="GENESYS_2") begin
        mig_7series_0 _mig (
            // Memory interface ports
            .ddr3_addr                      (ddr_addr),
            .ddr3_ba                        (ddr_ba),
            .ddr3_cas_n                     (ddr_cas_n),
            .ddr3_ck_n                      (ddr_ck_n),
            .ddr3_ck_p                      (ddr_ck_p),
            .ddr3_cke                       (ddr_cke),
            .ddr3_ras_n                     (ddr_ras_n),
            .ddr3_reset_n                   (ddr_reset_n),
            .ddr3_we_n                      (ddr_we_n),
            .ddr3_dq                        (ddr_dq),
            .ddr3_dqs_n                     (ddr_dqs_n),
            .ddr3_dqs_p                     (ddr_dqs_p),
            .ddr3_cs_n                      (ddr_cs_n),
            .ddr3_dm                        (ddr_dm),
            .ddr3_odt                       (ddr_odt),
            // Application interface ports
            .app_addr                       (app_addr),
            .app_cmd                        (app_cmd),
            .app_en                         (app_en),
            .app_wdf_data                   (app_wdf_data),
            .app_wdf_end                    (app_wdf_end),
            .app_wdf_wren                   (app_wdf_wren),
            .app_rd_data                    (app_rd_data),
            .app_rd_data_end                (app_rd_data_end),
            .app_rd_data_valid              (app_rd_data_valid),
            .app_rdy                        (app_rdy),
            .app_wdf_rdy                    (app_wdf_rdy),
            .app_sr_req                     (app_sr_req),
            .app_ref_req                    (app_ref_req),
            .app_zq_req                     (app_zq_req),
            .app_sr_active                  (app_sr_active),
            .app_ref_ack                    (app_ref_ack),
            .app_zq_ack                     (app_zq_ack),
            .ui_clk                         (ui_clk),
            .ui_clk_sync_rst                (ui_clk_sync_rst),
            .app_wdf_mask                   (app_wdf_mask),
            .init_calib_complete            (init_calib_complete),
            // System Clock Ports
            .sys_clk_p                       (clk_p),
            .sys_clk_n                       (clk_n),
            .sys_rst                         (rst)
        );
    end else if (BOARD=="NEXYS_DDR" ) begin
        mig_7series_0 u_mig_7series_0 (
            // Memory interface ports
            .ddr2_addr                      (ddr_addr), 
            .ddr2_ba                        (ddr_ba),  
            .ddr2_cas_n                     (ddr_cas_n),
            .ddr2_ck_n                      (ddr_ck_n), 
            .ddr2_ck_p                      (ddr_ck_p), 
            .ddr2_cke                       (ddr_cke),  
            .ddr2_ras_n                     (ddr_ras_n),
            .ddr2_we_n                      (ddr_we_n), 
            .ddr2_dq                        (ddr_dq),  
            .ddr2_dqs_n                     (ddr_dqs_n),
            .ddr2_dqs_p                     (ddr_dqs_p),
            .init_calib_complete            (init_calib_complete),  
              
            .ddr2_cs_n                      (ddr_cs_n),  
            .ddr2_dm                        (ddr_dm),  
            .ddr2_odt                       (ddr_odt),  
            // Application interface port
            .app_addr                       (app_addr),  
            .app_cmd                        (app_cmd),  
            .app_en                         (app_en),  
            .app_wdf_data                   (app_wdf_data),  
            .app_wdf_end                    (app_wdf_end),  
            .app_wdf_wren                   (app_wdf_wren),  
            .app_rd_data                    (app_rd_data),  
            .app_rd_data_end                (app_rd_data_end),  
            .app_rd_data_valid              (app_rd_data_valid),
            .app_rdy                        (app_rdy),  
            .app_wdf_rdy                    (app_wdf_rdy), 
            .app_sr_req                     (app_sr_req), 
            .app_ref_req                    (app_ref_req), 
            .app_zq_req                     (app_zq_req),  
            .app_sr_active                  (app_sr_active), 
            .app_ref_ack                    (app_ref_ack),  
            .app_zq_ack                     (app_zq_ack),  
            .ui_clk                         (ui_clk),  
            .ui_clk_sync_rst                (ui_clk_sync_rst),  
             
            .app_wdf_mask                   (app_wdf_mask),  
             
            // System Clock Port
            .sys_clk_i                       (clk),
            // Reference Clock Port
            .clk_ref_i                      (clk_ref),
            .sys_rst                        (rst) 
        );
    end else if (BOARD=="NEXYS_VIDEO" ) begin
        mig_7series_0 _mig (
            // Memory interface ports
            .ddr3_addr                      (ddr_addr),
            .ddr3_ba                        (ddr_ba),
            .ddr3_cas_n                     (ddr_cas_n),
            .ddr3_ck_n                      (ddr_ck_n),
            .ddr3_ck_p                      (ddr_ck_p),
            .ddr3_cke                       (ddr_cke),
            .ddr3_ras_n                     (ddr_ras_n),
            .ddr3_reset_n                   (ddr_reset_n),
            .ddr3_we_n                      (ddr_we_n),
            .ddr3_dq                        (ddr_dq),
            .ddr3_dqs_n                     (ddr_dqs_n),
            .ddr3_dqs_p                     (ddr_dqs_p),
            .ddr3_dm                        (ddr_dm),
            .ddr3_odt                       (ddr_odt),
            // Application interface ports
            .app_addr                       (app_addr),
            .app_cmd                        (app_cmd),
            .app_en                         (app_en),
            .app_wdf_data                   (app_wdf_data),
            .app_wdf_end                    (app_wdf_end),
            .app_wdf_wren                   (app_wdf_wren),
            .app_rd_data                    (app_rd_data),
            .app_rd_data_end                (app_rd_data_end),
            .app_rd_data_valid              (app_rd_data_valid),
            .app_rdy                        (app_rdy),
            .app_wdf_rdy                    (app_wdf_rdy),
            .app_sr_req                     (app_sr_req),
            .app_ref_req                    (app_ref_req),
            .app_zq_req                     (app_zq_req),
            .app_sr_active                  (app_sr_active),
            .app_ref_ack                    (app_ref_ack),
            .app_zq_ack                     (app_zq_ack),
            .ui_clk                         (ui_clk),
            .ui_clk_sync_rst                (ui_clk_sync_rst),
            .app_wdf_mask                   (app_wdf_mask),
            .init_calib_complete            (init_calib_complete),
            // System Clock Ports
            .sys_clk_i                      (clk),
            .clk_ref_i                      (clk_ref),
            .sys_rst                        (rst)
        );
    
    end else $error("Invalid Board Option");
    endgenerate

    localparam CMD_WRITE = 3'b000;
    localparam CMD_READ  = 3'b001;

    assign app_sr_req = 1'b0;
    assign app_ref_req = 1'b0;
    assign app_zq_req = 1'b0;

    assign app_wdf_mask = 'b0; // All

    reg [ADDR_WIDTH-1:0]    rd_addr_int, rd_addr_int_next;
    reg [ADDR_WIDTH-1:0]    wr_addr_int, wr_addr_int_next;
	reg [DATA_WIDTH-1:0]    wr_data_int, wr_data_int_next;

    reg wr_queued, wr_queued_next;
    reg rd_queued, rd_queued_next;

    enum {
        CALIBRATION,
        IDLE,
        WRITE,
        READ
    } state = CALIBRATION, state_next;

    always_comb begin
        state_next = CALIBRATION;
        rd_queued_next = 1'b0;
        wr_queued_next = 1'b0;
        rd_busy = 1'b0;
        wr_busy = 1'b0;
        app_en  = 1'b0;
        app_cmd = 3'b011;
        app_wdf_wren = 1'b0;
        app_wdf_end = 1'b0;
        app_addr = 'b0;
        app_wdf_data = 'b0;
        wr_addr_int_next = wr_addr_int;
        wr_data_int_next = wr_data_int;
        rd_addr_int_next = rd_addr_int;

        if (wr_en) begin
            wr_addr_int_next = wr_addr;
            wr_data_int_next = wr_data;
        end
        if (rd_en) begin
            rd_addr_int_next = rd_addr;
        end

        case (state)
            CALIBRATION:
            begin
                rd_busy = 1'b1;
                wr_busy = 1'b1;
                if (init_calib_complete) begin
                    state_next = IDLE;
                end
            end

            IDLE:
            begin
                // nothing happen
                state_next = IDLE;
                rd_queued_next = 1'b0;
                wr_queued_next = 1'b0;
                rd_busy = 1'b0;
                wr_busy = 1'b0;
                app_en  = 1'b0;
                app_cmd = 3'b011;
                app_wdf_wren = 1'b0;
                app_wdf_end = 1'b0;
                app_addr = 'b0;
                app_wdf_data = 'b0;
                //some request
                if (rd_en) begin
                    state_next = READ;
                    wr_queued_next = wr_en; // Read has precedence over write operations
                end else if (wr_en) begin
                    state_next = WRITE;
                end
            end

            READ:
            begin
                state_next = READ;
                rd_queued_next = 1'b0;
                wr_queued_next = wr_queued || wr_en;
                rd_busy = 1'b1;
                wr_busy = wr_queued;
                app_en = 1'b1;
                app_cmd = CMD_READ;
                app_wdf_wren = 1'b0;
                app_wdf_end = 1'b0;
                app_addr = {rd_addr_int,{(APP_ADDR-ADDR_WIDTH){1'b0}}};
                app_wdf_data = 'b0;
                if (app_rdy) begin // Read done
                    state_next = IDLE;
                    rd_busy = 1'b0; // Allows rd_en to be asserted on the same cycle
                    if (wr_queued) begin // Queued write
                        state_next = WRITE;
                        wr_queued_next = 1'b0;
                        rd_queued_next = rd_en;
                    end else if (rd_en) begin // Read request
                        state_next = READ;
                    end else if (wr_en) begin // Write request
                        state_next = WRITE;
                        wr_queued_next = 1'b0;
                    end
                end
            end

            WRITE:
            begin
                state_next = WRITE;
                rd_queued_next = rd_queued || rd_en;
                wr_queued_next = 1'b0;
                rd_busy = rd_queued;
                wr_busy = 1'b1;
                app_en = 1'b1;
                app_cmd = CMD_WRITE;
                app_wdf_wren = 1'b0; // app_wdf_wren is asserted when the write buffer is available
                app_wdf_end = 1'b0; // appapp_wdf_end is asserted when the write buffer is available
                app_addr = {wr_addr_int,{(APP_ADDR-ADDR_WIDTH){1'b0}}};
                app_wdf_data = wr_data_int;
                if (app_rdy && app_wdf_rdy) begin // Write operation
                    state_next = IDLE;
                    app_wdf_wren = 1'b1;
                    app_wdf_end = 1'b1;
                    wr_busy = 1'b0;
                    if (rd_en || rd_queued) begin
                        state_next = READ;
                        rd_queued_next = 1'b0;
                        wr_queued_next = wr_en;
                    end else if (wr_en) begin
                        state_next = WRITE;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge ui_clk) begin
        if (ui_clk_sync_rst) begin
            state       <= CALIBRATION;
            rd_addr_int <= 'd0;
            wr_addr_int <= 'd0;
            wr_data_int <= 'd0;
            wr_queued   <= 'b0;
            rd_queued   <= 'b0;
        end else begin
            state       <= state_next;
            rd_addr_int <= rd_addr_int_next;
            wr_addr_int <= wr_addr_int_next;
            wr_data_int <= wr_data_int_next;
            wr_queued   <= wr_queued_next;
            rd_queued   <= rd_queued_next;
        end
    end

    assign rd_data_valid    = app_rd_data_valid;
    assign rd_data          = app_rd_data;
endmodule
