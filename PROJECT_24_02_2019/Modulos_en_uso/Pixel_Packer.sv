`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.02.2019 18:43:24
// Design Name: 
// Module Name: Pixel Packer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// This module handle the the data recived from the UART and packed them to get a pixel, this pixel is then stored in the FIFO. 

//////////////////////////////////////////////////////////////////////////////////


module Pixel_Packer(
    input                   clk,
    input                   reset,
    input                   rx_ready,
    input logic  [7:0]      rx_data, 
    output logic [23:0]     RGB,                            //Pixel stored in the FIFO
    output logic            pixel_ready                     //Triggered when the pixel to stored is ready
    );
    
    logic        [23:0]     RGB_NEXT;
    logic        [7:0]      RED,GREEN,BLUE;
    logic        [7:0]      RED_NEXT,GREEN_NEXT,BLUE_NEXT;
    logic        [9:0]      fifo_counter,fifo_counter_next;
    
enum logic[5:0]{
    WAIT_RED,
    RED_RECIVED,
    WAIT_GREEN,
    GREEN_RECIVED,
    WAIT_BLUE,
    BLUE_RECIVED,
    WRITE_FIFO
}rgb_state=WAIT_RED,rgb_state_next;

always_ff@(posedge clk)begin
    if(reset)begin
        rgb_state       <= WAIT_RED;
        RED             <= 8'd0;
        GREEN           <= 8'd0;
        BLUE            <= 8'd0;
    end
    else begin
        RGB             <=  RGB_NEXT;
        fifo_counter    <=  fifo_counter_next;
        RED             <=  RED_NEXT;
        GREEN           <=  GREEN_NEXT;
        BLUE            <=  BLUE_NEXT;
        rgb_state       <=  rgb_state_next;

    end
end
always_comb begin
    RGB_NEXT            =   RGB;
    RED_NEXT            =   RED;
    GREEN_NEXT          =   GREEN;
    BLUE_NEXT           =   BLUE;
    pixel_ready         =   1'b0;
    rgb_state_next      =   rgb_state;
    
    case(rgb_state)
        WAIT_RED:                                           
            begin 
                if(rx_ready)rgb_state_next = RED_RECIVED;
            end
        RED_RECIVED:                                            //RED color of the pixel recived
            begin
                rgb_state_next = WAIT_GREEN;
                RED_NEXT = rx_data;
            end
        WAIT_GREEN: if(rx_ready)rgb_state_next = GREEN_RECIVED;
    
        GREEN_RECIVED:                                          //GREEN color of the pixel recived
            begin
                rgb_state_next = WAIT_BLUE;
                GREEN_NEXT = rx_data;
            end
        WAIT_BLUE: if(rx_ready)rgb_state_next = BLUE_RECIVED;
    
        BLUE_RECIVED:                                           //BLUE color of the pixel recived
            begin
                rgb_state_next = WRITE_FIFO;
                BLUE_NEXT = rx_data;       
            end
        WRITE_FIFO:                                             //Colours concatenation to get a pixel and store it in the FIFO 
            begin
                pixel_ready= 1'b1;
                RGB_NEXT = {RED,GREEN,BLUE};   
                rgb_state_next = WAIT_RED;   
            end
    default: rgb_state_next = WAIT_RED;
    endcase
    
end


endmodule
