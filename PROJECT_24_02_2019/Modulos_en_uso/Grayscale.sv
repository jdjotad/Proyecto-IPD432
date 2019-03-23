`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2018 05:43:49 PM
// Design Name: 
// Module Name: Grayscale
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
Grayscale inst
    (
    .SW(),              //For design is SW[1]
    .R_grayscale(),     //RGB colours from Dithering module
    .G_grayscale(),     
    .B_grayscale(),     
    .R_c(),             //RGB colours to colour scramble module
    .G_c(),
    .B_c()
    );
*/

module Grayscale(
    input logic SW,
    input logic [3:0] R_grayscale, G_grayscale, B_grayscale,    //RGB Colours from dithering module
    output logic [3:0] R_c, G_c, B_c                            //RGB Colour to colour scramble module
    );
    
    always_comb begin
        R_c = R_grayscale;
        G_c = G_grayscale;
        B_c = B_grayscale;
        if (SW) begin
            R_c = (R_grayscale >> 2) + (G_grayscale >> 1) + (B_grayscale >> 3);
            G_c = (R_grayscale >> 2) + (G_grayscale >> 1) + (B_grayscale >> 3);
            B_c = (R_grayscale >> 2) + (G_grayscale >> 1) + (B_grayscale >> 3);
        end
    end
endmodule
