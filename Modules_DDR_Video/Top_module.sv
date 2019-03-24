`timescale 1ns / 1ps

module Top_module
(   
    input   logic   [15:0]   SW,
    output  logic   [0:0]   LED,
    input   logic           button_c,
    input   logic           button_right,
    output  logic   [7:0]   ss_value,
    output  logic   [7:0]   ss_select,
    input   logic           uart_rx_usb,
    input   logic           clk,
    input   logic           cpu_resetn,
    output  logic   [3:0]   VGA_R, VGA_G, VGA_B,
    output  logic           VGA_HS, VGA_VS,
    //memmory signals
    output  logic   [12:0]  ddr2_addr,
    output  logic   [2:0]   ddr2_ba,
    output                  ddr2_cas_n,
    output                  ddr2_ck_n,
    output                  ddr2_ck_p,
    output                  ddr2_cke,
    output                  ddr2_ras_n, 
    output                  ddr2_we_n,
    inout   logic   [15:0]  ddr2_dq,
    inout   logic   [1:0]   ddr2_dqs_n,
    inout   logic   [1:0]   ddr2_dqs_p,
    output  logic           ddr2_cs_n,
    output  logic   [1:0]   ddr2_dm,
    output  logic           ddr2_odt
);
	 logic            clk_ref;
	 //------VGA SIGNALS-------------//
	 logic [10:0] hc_visible, vc_visible;
     logic CLK78_8MHZ;
        
	 
	 logic ui_clk;
	 //----------------------------
    logic end_of_write;
	logic [7:0] rx_data; 
	logic rx_ready;
	logic [1:0] reset_sr;
	logic reset = reset_sr[1];
    /*
     * Convertir la se�al del bot�n reset_n a 'active HIGH'
     * y sincronizar con el reloj.
    */ 
	always_ff@(posedge clk) reset_sr <= {reset_sr[0], ~cpu_resetn};
	/* M�dulo UART a 115200/8 bits datos/No paridad/1 bit stop */
	uart_basic #(
		.CLK_FREQUENCY(100000000),
		.BAUD_RATE(4000000)
	) uart_basic_inst (
		.clk(clk),
		.reset(reset),
		.rx(uart_rx_usb),
		.rx_data(rx_data),
		.rx_ready
	);
	
	logic  [23:0]  fifo_read;
	logic          fifo_read_en;
	logic          fifo_full, fifo_almost_full, fifo_empty, fifo_almost_empty;

    logic[23:0]RGB;
    logic pixel_ready;
    logic valid_fifo;
    //----------------FIFO TO COMMUNICATE UART AND MIG---------------------------------//
    fifo_generator_0 your_instance_name (
      .rst(reset),                      // input wire rst
      .wr_clk(clk),                // input wire wr_clk
      .rd_clk(ui_clk),                // input wire rd_clk
      .din(RGB),                      // input wire [23 : 0] din
      .wr_en(pixel_ready),                  // input wire wr_en
      .rd_en(fifo_read_en),                  // input wire rd_en
      .dout(fifo_read),                    // output wire [23 : 0] dout
      .full(fifo_full),                    // output wire full
      .almost_full(fifo_almost_full),      // output wire almost_full
      .empty(fifo_empty),                  // output wire empty
      .almost_empty(fifo_almost_empty),    // output wire almost_empty
      .valid(valid_fifo),                  // output wire valid
      .wr_rst_busy(),      // output wire wr_rst_busy
      .rd_rst_busy()      // output wire rd_rst_busy
    );
    
    //------------PIXEL PACKER--------------------------------------------//
    // MODULE TO PACK 5 PIXELS (24[bits/pixel] * 5[pixels] = 120 [bits]) TO BE SAVED IN DDR
    // LOSING ONE BYTE FROM EACH ADDRESS IN DDR (BECAUSE CAN BE SAVED UP TO 128[bits] PER ADDRESS
    Pixel_Packer inst_pixel_packer(
        .clk(clk),
        .reset,
        .rx_ready,
        .rx_data,
        .RGB,
        .pixel_ready
    );

 
 
// LED ASSIGNMENT TO INDICATE THE WRITING TASK HAS FINISHED
assign LED[0]=end_of_write;
    
    
/////////////////////////////////
// HERE STARTS THE DDR INTERFACE
    logic          ddr_rd_en;  
    logic          ddr_read_ready;  
    logic          full_read_ready;
	logic          busy_read;
	logic          busy_write;
    logic  [127:0] rd_data_ordered;
	logic          rd_data_valid;
	logic  [23:0]  rd_addr_vga;

    //--------------MEMORY HANDLER-----------------------------//
    // THIS MODULE IS THE INTERFACE TO WRITE AND READ FROM THE DDR, INSIDE HAS A MIG IP AND THE PYSICAL SIGNALS
    // ASK THE GIT REPOSITORY TO CONFIGURE THE MIG FOR NEXYS 4 DDR.
    Memory_handler memory_handler_inst(
        .rst(reset),
        .end_of_write,
        .fifo_read_en,
        .uart_rgb_information(fifo_read),
        .cpu_resetn,
        .clk_ref,
        .busy_read,
        .busy_write,
        .ui_clk,
        //senales para la lectura del 
        .fifo_empty,
        .valid_fifo,//dato leido es valido
        .rd_addr_vga, //direccion de lectura 
        .rd_en_in(ddr_rd_en), //gatilla la lectura desde afuera
        .rd_data_ordered, //datos de la lectura
        .rd_data_valid, //lectura valida
        .ddr_read_ready, //lectura valida y reordenada.
        .full_read_ready,
        // phy signals
        
        .clk                (clk),
        .ddr2_addr          (ddr2_addr),
        .ddr2_cs_n          (ddr2_cs_n), 
        .ddr2_ba            (ddr2_ba),
        .ddr2_cas_n         (ddr2_cas_n),
        .ddr2_ck_n          (ddr2_ck_n), 
        .ddr2_ck_p          (ddr2_ck_p), 
        .ddr2_cke           (ddr2_cke),  
        .ddr2_ras_n         (ddr2_ras_n),
        .ddr2_we_n          (ddr2_we_n), 
        .ddr2_dq            (ddr2_dq),
        .ddr2_dqs_n         (ddr2_dqs_n),
        .ddr2_dqs_p         (ddr2_dqs_p),
        .ddr2_dm            (ddr2_dm),
        .ddr2_odt           (ddr2_odt)
    
    );
    
    // THIS MODULE SENDS A READ ENABLE SIGNAL TO GET A DATA OF 128[bits] AND UNPACK THE DATA TO 5 PIXELS
    // ALSO IT SAVES AN ENTIRE FRAME IN A BRAM AND HOLD THAT FRAME TO WATCH A PARAMETIZABLE QUANTITY OF FPS (DEFAULT IS 24[fps])
    Pixel_reader pixel_reader_uno
            (
             .clk(ui_clk),
             .clk_vga(CLK78_8MHZ),
             .hc_visible,
             .vc_visible,
             .reset(reset),
             .ddr_rd_data_valid(ddr_read_ready),
             .ddr_rd_busy(busy_read), 
             .ddr_data(rd_data_ordered),
             .end_of_write,//le agregue esto para que comenzara a leer una vez se terminara de escribir en memoria ddr
             .end_of_read(full_read_ready),
             .pixel_to_filter,
             .ddr_addr(rd_addr_vga),
             .ddr_rd_en
            );
    
// IP to create one clock of 78.8MHZ for VGA and other of 200MHZ for the reference clock of the MIG
    clk_wiz_0 wiz_0
   (
    // Clock out ports
    .clk_out1(clk_ref),     // output clk_out1
    .clk_out2(CLK78_8MHZ),     // output clk_out2
    // Status and control signals
    .reset(reset), // input reset
    .locked(),       // output locked
   // Clock in ports
    .clk_in1(clk));      // input clk_in1
    
//----------------VGA--------------------------------------
 logic [23:0]pixel_to_filter; 
 logic fifo_read_valid;
 logic fifo_empty_pixel;
    // DRIVER TO SHOW A RESOLUTION OF 1024x768 WITH A CLOCK OF 78.8[MHz]
    driver_vga_1024x768
        (
        .clk_vga(CLK78_8MHZ), 
        .hs(VGA_HS), 
        .vs(VGA_VS),
        .hc_visible,
        .vc_visible
        );
    
    // HERE ENTRY THE PIXELS IN RGB (8[bits] EACH COLOUR) AND DEPENDING ON THE SWITCHES POSITION
    // THE VIDEO CAN BE SHOWED AS THE ORIGINAL ONE, DITHERED, GRAYSCALED OR SWITCH BETWEEN THE COLOURS VALUES
    RGB_display inst
        (
        .clk(CLK78_8MHZ),
        .SW({SW[15:10], SW[1:0]}),
        .hc_visible,
        .vc_visible,
        .R_memory(pixel_to_filter[23:16]),
        .G_memory(pixel_to_filter[15:8]),
        .B_memory(pixel_to_filter[7:0]),
        .vga_r(VGA_R),
        .vga_g(VGA_G),
        .vga_b(VGA_B)
        );
 

endmodule