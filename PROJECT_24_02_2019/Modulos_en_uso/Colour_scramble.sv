`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2018 05:44:38 PM
// Design Name: 
// Module Name: Colour_scramble
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
Colour_scramble inst
    (
    .SW(),          //SW[15:14] for Red scramble, SW[13:12] for Green scramble and SW[11:10] for Blue scramble
    .R_c(),         //RGB from Grayscale
    .G_c(),
    .B_c(),
    .R_to_vga(),    //RGB to display
    .G_to_vga(),
    .B_to_vga()
    );
*/

module Colour_scramble(
    input logic [5:0] SW,                                       //Switches for each colour scramble
    input logic [3:0] R_c, G_c, B_c,                            //RGB from Grayscale module
    output logic [3:0] R_to_vga, G_to_vga, B_to_vga             //RGB to VGA
    );
    
    always_comb begin
        R_to_vga = R_c;                 //Default case (When Switches are down) is
        G_to_vga = G_c;                 //original image
        B_to_vga = B_c;
        case(SW[5:4])                   //Case statement to swap red's intensity
            2'd1:   R_to_vga = G_c;     //Set green value on red intensity
            2'd2:   R_to_vga = B_c;     //Set blue value on red intensity
            2'd3:   R_to_vga = 4'd0;    //Set 0 as red intensity
        endcase
        
        case(SW[3:2])                   //Case statement to swap green's intensity
            2'd1:   G_to_vga = R_c;     //Set red value on green intensity
            2'd2:   G_to_vga = B_c;     //Set blue value on green intensity 
            2'd3:   G_to_vga = 4'd0;    //Set 0 as green intensity               
        endcase
        
        case(SW[1:0])                   //Case statement to swap blue's intensity
            2'd1:   B_to_vga = R_c;     //Set red value on blue intensity
            2'd2:   B_to_vga = G_c;     //Set green value on blue intensity 
            2'd3:   B_to_vga = 4'd0;    //Set 0 as blue intensity               
        endcase
                
    end
endmodule
