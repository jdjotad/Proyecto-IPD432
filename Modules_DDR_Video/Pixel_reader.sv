`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2019 02:57:32 PM
// Design Name: 
// Module Name: Pixel_converter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Pixel_reader #(
    parameter DDR_DATA_WIDTH = 128,
    parameter NUMBER_OF_PIXELS = 196608
    )(
     input logic 		      	          clk,
     input logic 		      	          clk_vga,
     input logic 		      	          reset,
     input logic    [10:0]                hc_visible, vc_visible,
     input logic                          fps,
     input logic 		      	          ddr_rd_data_valid,
     input logic 		      	          ddr_rd_busy, 
     input logic    [DDR_DATA_WIDTH-1:0]  ddr_data,
     input logic                          end_of_write, //agregado para saber cuando termina de escribir en la DDR 
     input logic                          end_of_read,                           
     output logic   [23:0] 	      	      pixel_to_filter,
     output logic   [23:0] 	      	      ddr_addr,
     output logic 		      	          ddr_rd_en
    );				
   
   enum logic [4:0] {IDLE, WAIT_VALID, PIXEL_TO_BRAM, NEXT_PIXEL, HOLD_FRAME} state = IDLE, state_next;

   logic	[31:0]	    ddr_addr_next = 'd0;
   logic    [31:0]      cycles_counter = 'd0, cycles_counter_next, cycles_to_reach_fps;
   logic	[23:0]	    data_to_bram = 'd0, data_to_bram_next;
   logic		        bram_wr_en = 'd0, bram_wr_en_next;
   logic    [17:0]      pixel_number = 'd0, pixel_number_next, bram_pixel;
   logic    [2:0]       pixel_count = 'd0, pixel_count_next;
   logic    [17:0]      counter_pixel_to_show = 'd0;
   
   
    // A frame should be in the display for 1/fps [s] or (MHZ of clk)/fps [clock cycles] to see the input fps.
    // To calculate the (MHZ of clk)/fps [clock cycles] we will use this ip
    always_ff@(posedge clk) begin
        cycles_to_reach_fps <= cycles_to_reach_fps;
        if(state != HOLD_FRAME) begin
            case(fps)
                1'b0: cycles_to_reach_fps <= 31'd2_084_000;
                1'b1: cycles_to_reach_fps <= 31'd1_042_000;
                default: cycles_to_reach_fps <= 31'd2_084_000;
            endcase
        end
    end
   
   // Logic to show 1024x768 with a picture or video in 512x384 native resolution, this happen repeating the same pixel 4 times.
    always_ff @(posedge clk_vga) begin
        counter_pixel_to_show <= counter_pixel_to_show;
        if ((hc_visible == 11'd1) && (vc_visible == 11'd1)) counter_pixel_to_show <= 18'd0;
        else if (hc_visible && vc_visible) begin
            if (hc_visible[0])
                counter_pixel_to_show <= counter_pixel_to_show + 18'd1;
            if (vc_visible[0] && (hc_visible == 11'd1))
                counter_pixel_to_show <= counter_pixel_to_show - 18'd511;
        end     
    end
   
   
   // There is the description of a state machine which first send the read enable to the DDR, then wait for read valid to be asserted.
   // Each read valid means 5 pixels have arrived and they are saved in a BRAM to show a complete frame in the screen. The frame is hold
   // 'cycles_to_reach_fps' [cycles] which is defined by the parameter 'fps'. 
   always_ff@(posedge clk) begin
      state <= state_next;
      ddr_addr <= ddr_addr_next;
      data_to_bram <= data_to_bram_next;
      pixel_number <= pixel_number_next;
      bram_pixel <= pixel_number;
      pixel_count <= pixel_count_next;
      bram_wr_en <= bram_wr_en_next;
      cycles_counter <= cycles_counter_next;
      if(reset) begin
	       state <= IDLE;
	       ddr_addr <= 13'd0;
      end
   end 
    
    always_comb begin
        pixel_number_next = pixel_number ; 
        pixel_count_next = pixel_count; 
        state_next = state;
        bram_wr_en_next = 1'b0;
        cycles_counter_next = 12'd0;
        ddr_rd_en = 1'b0;
        data_to_bram_next = data_to_bram;
        ddr_addr_next = ddr_addr;
        case(state)
            IDLE:
                begin
                    if(~ddr_rd_busy && end_of_write) begin
                        ddr_rd_en = 1'b1;
                        state_next = WAIT_VALID;
                    end
                end
            WAIT_VALID:  
                begin
                    if(ddr_rd_data_valid) 
                        state_next = PIXEL_TO_BRAM;
                    if(end_of_read) begin               // Replay the video from the beginning
                        ddr_addr_next = 'd0;
                        pixel_count_next ='d0;
                        pixel_number_next = 'd0;
                        state_next = HOLD_FRAME;
                    end   
                end
            PIXEL_TO_BRAM:
                begin
                    bram_wr_en_next = 1'b1;
                    case(pixel_count)
                        'd0:
                            begin
                                data_to_bram_next = ddr_data[23:0];
                            end
                        'd1:
                            begin
                                data_to_bram_next = ddr_data[47:24];
                                end
                        'd2:
                            begin
                                data_to_bram_next = ddr_data[71:48];
                            end
                        'd3:
                            begin
                                data_to_bram_next = ddr_data[95:72];
                            end
                        'd4:
                            begin
                                data_to_bram_next = ddr_data[119:96];
                            end
                        default: data_to_bram_next = 'd0;
                    endcase
                    pixel_count_next = pixel_count + 'd1;
                    pixel_number_next = pixel_number +'d1;
                    if(pixel_number == NUMBER_OF_PIXELS-1) begin  // Reset the number of pixels because was read an entire frame
                        ddr_addr_next = ddr_addr + 'd1;    
                        pixel_number_next = 'd0;
                        pixel_count_next = 'd0;
                        state_next = HOLD_FRAME;       
                    end  
                    if(pixel_count == 'd4) begin        // When we finish to read 4 pixels (120 bits) 
                        ddr_addr_next = ddr_addr + 'd1;
                        pixel_count_next ='d0;
                        state_next = IDLE;
                    end
                end
            HOLD_FRAME:
                begin
                    cycles_counter_next = cycles_counter + 'd1;
                    if (cycles_counter == (cycles_to_reach_fps - 'd1)) begin
                        state_next = IDLE;
                    end
                end
          endcase
       end  // always_comb

   blk_mem_gen_0 blk_frame 
    (
        .clka(clk),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(bram_wr_en),      // input wire [0 : 0] wea
        .addra(bram_pixel),  // input wire [17 : 0] addra
        .dina(data_to_bram),    // input wire [23 : 0] dina
        .clkb(clk_vga),    // input wire clkbwrite_bram
        .addrb(counter_pixel_to_show),  // input wire [17 : 0] addrb
        .doutb(pixel_to_filter)  // output wire [23 : 0] doutb
    );
    

endmodule
