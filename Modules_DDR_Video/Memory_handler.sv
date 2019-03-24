`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.10.2018 23:02:58
// Design Name: 
// Module Name: Memory_handler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// This module is divided into two sections, a section for the write process and another one for the read process. Both parts have 
// interaction with the DDR ram controller instantiated at the end of the module. Read and write processes are just state machines 
// controlled both by DDR signals and user's signals. Read and write process are never perfomed together.   
//////////////////////////////////////////////////////////////////////////////////


module Memory_handler#(
    parameter MAX_ADDRESS = 39322, //Number of the max address iqual to total number of pixels divided by 5(in a frame)
    parameter NUMBER_OF_PIXELS = 196608, //Number of pixels in a frame, depends on the size of the image
    parameter PIXEL_WIDTH = 20, //log2(NUMBER_OF_PIXELS)
    parameter NUMBER_OF_FRAMES = 200 //Number of frames in the video
)(
        input   logic           rst,                   //Global reset
        input   logic   [23:0]  uart_rgb_information,  //Pixel recieved 
        output  logic           end_of_write,          //Signal that rises when the video is fully loaded
        //
        input   logic           clk,                   //Global clock
        input   logic           clk_ref,               //Reference clock
        input   logic           cpu_resetn,
        output  logic           fifo_read_en,          //FIFO read enable
        output  logic           busy_read,             //DDR busy read output 
        output  logic           busy_write,            //DDR busy write output  
        output  logic           ui_clk,                //DDR Clock output for user's logic
        
        //
        input   logic           fifo_empty,             //Signal from the FIFO, rises if it's empty 
        input   logic           valid_fifo,             //High if the read data of the FIFO is valid
        input   logic           rd_en_in,               //Trigger for DDR read process
        input   logic   [23:0]  rd_addr_vga,            //Reading address
        output  logic   [127:0] rd_data_ordered,        //Reading data
        output  logic           rd_data_valid,          //High if the read data of the DDR is valid
        output  logic           ddr_read_ready,         //High when the DDR read finishes
        output  logic           full_read_ready,        //High when the last frame is read
        
        //DDR controller port
        output  logic   [12:0]  ddr2_addr,
        output  logic   [2:0]   ddr2_ba,
        output  logic           ddr2_cas_n,
        output  logic           ddr2_ck_n,
        output  logic           ddr2_ck_p,
        output  logic           ddr2_cke,
        output  logic           ddr2_ras_n, 
        output  logic           ddr2_we_n,
        inout   logic           [15:0] ddr2_dq,
        inout   logic           [1:0] ddr2_dqs_n,
        inout   logic           [1:0] ddr2_dqs_p,
        output  logic           ddr2_cs_n,
        output  logic           [1:0] ddr2_dm,
        output  logic           ddr2_odt
    );
    
    logic                       ui_clk_sync_rst; 
    logic   [127:0]             rd_data, rd_data_ordered_next;
    logic   [127:0]             wr_data, wr_data_next;
    logic                       rd_busy;
    logic                       wr_busy;
    logic   [23:0]              wr_addr, wr_addr_next;
    logic                       rd_en;
    logic                       wr_en;
    
    
  
    logic                       end_of_write_next; 
    logic   [127:0]             rd_data_out_next; 
    logic   [2:0]               pixel_in_line,pixel_in_line_next;               //Number of pixels in a DDR data word before write
    logic   [PIXEL_WIDTH-1:0]   pixel_number,pixel_number_next;                 //Number of pixels that have been saved in the DDR
    logic   [23:0]              write_address_number,write_address_number_next; 
    logic   [8:0]               frame_number,frame_number_next;                   
    
    //------------Start of the logic for the DDR write process------------------------------------------------------------------
    enum logic [4:0] {IDLE_WRITE,READ_FIFO, WRITE,WAIT_BUSY,NEXT_MEMORY_ADDRESS} state = IDLE_WRITE, state_next;

    
    always_ff@(posedge ui_clk) begin
        if(ui_clk_sync_rst)begin
            end_of_write            <=  'd0;
            wr_addr                 <=  'd0;
            pixel_in_line           <=  'd0;
            pixel_number            <=  'd0;
            frame_number            <=  'd0;
            write_address_number    <=  'd0;
            state                   <=  IDLE_WRITE;
        end
        else begin
            write_address_number    <=  write_address_number_next;
            wr_addr                 <=  wr_addr_next;
            pixel_in_line           <=  pixel_in_line_next;
            pixel_number            <=  pixel_number_next;
            wr_data                 <=  wr_data_next;
            state                   <=  state_next;
            end_of_write            <=  end_of_write_next;
            frame_number            <=  frame_number_next;
        end
    end
    always_comb begin
        wr_en                       = 1'b0;
        fifo_read_en                = 1'b0;
        end_of_write_next           = end_of_write;
        wr_addr_next                = wr_addr;
        write_address_number_next   = write_address_number;
        pixel_in_line_next          = pixel_in_line;
        pixel_number_next           = pixel_number;
        frame_number_next           = frame_number;
        wr_data_next                = wr_data;
        state_next                  = state;
        case(state)
            IDLE_WRITE: 
                begin
                    if(!fifo_empty) begin                                           //If the FIFO its not empty start with the pixel saving
                        state_next = READ_FIFO;
                        fifo_read_en = 1'b1;
                    end
                end      
            READ_FIFO:                                                              //State that acumulate pixels in a DDR data word
                begin
                    if(valid_fifo)begin
                        case(pixel_in_line)
                        3'd0:wr_data_next[23:0]   = uart_rgb_information;
                        3'd1:wr_data_next[47:24]  = uart_rgb_information;
                        3'd2:wr_data_next[71:48]  = uart_rgb_information;
                        3'd3:wr_data_next[95:72]  = uart_rgb_information;
                        3'd4:wr_data_next[127:96] = {8'd0,uart_rgb_information};    
                        endcase
                        
                        pixel_number_next = pixel_number +'d1;
                        pixel_in_line_next = pixel_in_line +'d1;
                        state_next = IDLE_WRITE;
                        if(pixel_in_line == 3'd4||pixel_number==NUMBER_OF_PIXELS-1)begin //If 5 pixels have been accumulated or the total number of pixels is reached
                            state_next  =   WRITE;                                          //go to the next state for data write
                        end    
                    end
                
                end
            
            WRITE:                                                                         //Write in the DDR
                begin
                    if(!wr_busy)begin                
                        wr_en = 1'b1;
                        state_next      =   WAIT_BUSY;
                    end
                end
            WAIT_BUSY:                                                                     //Wait for the write busy signal to be cleared to 0
                begin
                    if(!wr_busy)state_next  =   NEXT_MEMORY_ADDRESS;                           
                end
            
            NEXT_MEMORY_ADDRESS:                                                            //Next DDR address and finish detection state
                begin
                    pixel_in_line_next          =       'd0; 
                    wr_data_next                =   128'd0;
                    state_next                  = IDLE_WRITE;
                    wr_addr_next                = wr_addr + 24'd1;
                    write_address_number_next   = write_address_number +'d1;
                    if(write_address_number == MAX_ADDRESS-1)begin
                        frame_number_next           = frame_number + 'd1;
                        write_address_number_next   = 'd0;
                        pixel_number_next           = 'd0;
                        if(frame_number == NUMBER_OF_FRAMES-1)begin
                            end_of_write_next = 1'b1;
                            pixel_number_next = 'd0;
                            frame_number_next = 'd0;
                        end
                    end
                end

        endcase
            
    end
    //--------------End of the logic for the write process------------------------------------------------------------------
    
    //THE VOID
    
    //--------------Start of the logic for the read process------------------------------------------------------------------
    enum logic[1:0]{IDLE_READ,READ_FINISH}state_act,next_state;
    
    logic                       ddr_read_ready_next;
    logic [8:0]                 rd_number_frames,rd_number_frames_next; //Number of frames already read 
    logic [PIXEL_WIDTH-1:0]     rd_address_number,rd_address_number_next; //Number of address already read
    logic                       full_read_ready_next;  
      
    always_ff@(posedge ui_clk)begin
        if(ui_clk_sync_rst)begin
            state_act           <=  IDLE_READ;
            rd_address_number   <=   'd0;
            rd_data_ordered     <=   'd0;
        end
        else begin
            state_act           <=  next_state;
            rd_data_ordered     <=  rd_data_ordered_next;
            ddr_read_ready      <=  ddr_read_ready_next;
            rd_address_number   <=  rd_address_number_next;
            rd_number_frames    <=  rd_number_frames_next;
            full_read_ready     <=  full_read_ready_next;
        end
    end
    
    always_comb begin
        next_state              =   state_act;
        ddr_read_ready_next     =   ddr_read_ready;
        rd_data_ordered_next    =   rd_data_ordered;
        rd_address_number_next  =   rd_address_number;
        rd_number_frames_next   =   rd_number_frames;
        full_read_ready_next    =   full_read_ready;
        rd_en = 1'b0;
        case(state_act)
            IDLE_READ:                                                  //Wait for the rd_en_in to be asserted 
                begin
                    ddr_read_ready_next  = 1'b0;
                    full_read_ready_next = 1'b0;
                    if(!wr_busy && end_of_write_next && rd_en_in)begin     //read process it's not possible if the write process isn't finished
                        rd_en = 1'b1;
                        next_state = READ_FINISH;
                    end
                end      
            READ_FINISH: 
                begin
                    if(rd_data_valid) begin                            //Wait for the data valid before reading the next address
                        rd_data_ordered_next = rd_data;
                        ddr_read_ready_next  = 1'b1;
                        next_state           = IDLE_READ;
                     
                        if(rd_address_number == MAX_ADDRESS-1)begin
                            if(rd_number_frames == NUMBER_OF_FRAMES-1)begin
                                 rd_number_frames_next = 'd0;
                                 full_read_ready_next  = 1'b1;                   
                            end
                            else rd_number_frames_next = rd_number_frames +'d1;       
                            
                            rd_address_number_next  = 'd0;
                        end
                        else rd_address_number_next = rd_address_number +'d1;
                    end
                end
        endcase
    
    end


 //------------DDR ram controller instance ------------------------------------------------------------------ 
    
    
    
    ddr_ram_controller_mig #(
        .BOARD("NEXYS_DDR")) ddr2(
        // user interface signals
        .ui_clk             (ui_clk),
        .ui_clk_sync_rst    (ui_clk_sync_rst),
        .wr_addr            (wr_addr),
        .wr_data            (wr_data),
        .rd_addr            (rd_addr_vga),
        .rd_data            (rd_data),
        .wr_en              (wr_en),
        .rd_en              (rd_en),
        .wr_busy            (wr_busy),
        .rd_busy            (rd_busy),
        .rd_data_valid      (rd_data_valid),
        // phy signals
        .clk_p(),
        .clk_n(),
        
        .clk                (clk),
        .clk_ref            (clk_ref),
        .rst                (cpu_resetn),
        .ddr_addr          (ddr2_addr),
        .ddr_cs_n          (ddr2_cs_n), 
        .ddr_ba            (ddr2_ba),
        
        .ddr_cas_n         (ddr2_cas_n),
        .ddr_ck_n          (ddr2_ck_n), 
        .ddr_ck_p          (ddr2_ck_p), 
        .ddr_cke           (ddr2_cke),  
        .ddr_ras_n         (ddr2_ras_n),
        .ddr_reset_n       (reset),
        .ddr_we_n          (ddr2_we_n), 
        .ddr_dq            (ddr2_dq),
        .ddr_dqs_n         (ddr2_dqs_n),
        .ddr_dqs_p         (ddr2_dqs_p),
        .ddr_dm            (ddr2_dm),
        .ddr_odt           (ddr2_odt)
    );


endmodule
