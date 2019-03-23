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
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//Modulo encargado de recibir los valores correspondiente a los LED de cada pixel y los empaqueta en un registro de 24 bits que forman
//Los valores RGB de cada pixel.

module Pixel_Packer(
    input clk,
    input reset,
    input rx_ready,
    input logic [7:0]rx_data,
    input logic[9:0]fifo_write_count,  
    
    output logic [23:0]RGB,
    output logic pixel_ready
    );
    logic[23:0]RGB_NEXT;
    logic[7:0]RED,GREEN,BLUE;
    logic[7:0]RED_NEXT,GREEN_NEXT,BLUE_NEXT;
    logic[9:0]fifo_counter,fifo_counter_next;
    
enum logic[5:0]{
    wait_r,
    rojo,
    wait_g,
    verde,
    wait_a,
    azul,
    write_fifo
}rgb_state=wait_r,rgb_state_next;

always_ff@(posedge clk)begin
    if(reset)begin
        rgb_state <= wait_r;

        RED <= 8'd0;
        GREEN<= 8'd0;
        BLUE <= 8'd0;
    end
    else begin
        RGB <= RGB_NEXT;
        //pixel_ready<=pixel_ready_next;
        fifo_counter <= fifo_counter_next;
        RED<=RED_NEXT;
        GREEN<= GREEN_NEXT;
        BLUE <= BLUE_NEXT;
        rgb_state <= rgb_state_next;

    end
end
always_comb begin
    RGB_NEXT = RGB;
    fifo_counter_next = fifo_write_count;
    RED_NEXT=RED;
    GREEN_NEXT=GREEN;
    BLUE_NEXT=BLUE;
    pixel_ready=1'b0;
    rgb_state_next = rgb_state;
    case(rgb_state)
    wait_r: //SE RECIBE ROJO
        begin 
            //pixel_ready_next = 1'b0; 
            if(rx_ready)rgb_state_next = rojo;
        end
    rojo: 
        begin
            rgb_state_next = wait_g;
            RED_NEXT = rx_data;
        end
    wait_g: if(rx_ready)rgb_state_next = verde;//SE RECIBE VERDE
    
    verde: 
        begin
            rgb_state_next = wait_a;
            GREEN_NEXT = rx_data;
        end
    wait_a: if(rx_ready)rgb_state_next = azul;
    
    azul:  //SE RECIBE AZUL
        begin
            rgb_state_next = write_fifo;
            BLUE_NEXT = rx_data;
            
        end
    write_fifo:
        begin

                pixel_ready= 1'b1;
                RGB_NEXT = {RED,GREEN,BLUE};   //SE CONCADENA
                rgb_state_next = wait_r;   

        end
    default: rgb_state_next = wait_r;
    endcase
    
end


endmodule
