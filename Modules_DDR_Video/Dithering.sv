`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2018 05:44:13 PM
// Design Name: 
// Module Name: Dithering
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
/*
Dithering inst
    (
    .hc_visible(),      //2 LSB of hc_visible
    .vc_visible(),      //2 LSB of vc_visible
    .SW(),              //For design is SW[0]
    .R_memory(),        //Red from memory
    .G_memory(),        //Green from memory
    .B_memory(),        //Blue from memory
    .R_grayscale(),     //Red to grayscale module
    .G_grayscale(),     //Green to grayscale module
    .B_grayscale()      //Blue to grayscale module
    );
*/

module Dithering(
    input [1:0]hc_visible,
    input [1:0]vc_visible,
    input logic SW,
    input logic [7:0] R_memory, G_memory, B_memory,
    output logic [3:0] R_grayscale, G_grayscale, B_grayscale
    );
    
    logic [3:0] dithering_matrix;

    always_comb begin
       
       case ({vc_visible[1:0], hc_visible[1:0]})
           4'd0 : dithering_matrix = 4'd0;           
           4'd1 : dithering_matrix = 4'd8;         
           4'd2 : dithering_matrix = 4'd2;
           4'd3 : dithering_matrix = 4'd10; 
           4'd4 : dithering_matrix = 4'd12;
           4'd5 : dithering_matrix = 4'd4;
           4'd6 : dithering_matrix = 4'd14;
           4'd7 : dithering_matrix = 4'd6;
           4'd8 : dithering_matrix = 4'd3;
           4'd9 : dithering_matrix = 4'd11;
           4'hA : dithering_matrix = 4'd1;
           4'hB : dithering_matrix = 4'd9;
           4'hC : dithering_matrix = 4'd15;
           4'hD : dithering_matrix = 4'd7;
           4'hE : dithering_matrix = 4'd13;
           4'hF : dithering_matrix = 4'd5;
       endcase

       
    end
    
    always_comb begin
        R_grayscale = R_memory[7:4];
        G_grayscale = G_memory[7:4];
        B_grayscale = B_memory[7:4];
    
        if (SW) begin
            // If colour's value is 4'hF it is kept, in other case if its greater than matrix
            // reference value the output colour is the original one plus 4'd1 
            
            //Red
            if (R_memory[7:4] == 4'hF)                                      R_grayscale = 4'hF;
            else if (R_memory[3:0] > dithering_matrix)                      R_grayscale = R_memory[7:4] + 4'd1;
            //Green
            if (G_memory[7:4] == 4'hF)                                      G_grayscale = 4'hF;
            else if (G_memory[3:0] > dithering_matrix)                      G_grayscale = G_memory[7:4] + 4'd1;
            //Blue
            if (B_memory[7:4] == 4'hF)                                      B_grayscale = 4'hF;
            else if (B_memory[3:0] > dithering_matrix)                      B_grayscale = B_memory[7:4] + 4'd1;    
        end                                                       
    end
    
    
endmodule
