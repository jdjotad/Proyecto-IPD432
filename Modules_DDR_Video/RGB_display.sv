`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2018 05:21:16 PM
// Design Name: 
// Module Name: RGB_display
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
RGB_display inst
    (
    .clk(),
    .SW(),
    .hc_visible(),
    .vc_visible(),
    .R_memory(),
    .G_memory(),
    .B_memory(),
    .VGA_R(),
    .VGA_G(),
    .VGA_B()
    );
*/

module RGB_display(
    input logic clk,                                //Clock for sync
    input logic [7:0] SW,                           //Switches for dithering, grayscale and colour scramble
    input logic [10:0] hc_visible,                  //Visible horizontal area in display (hc_visible)
    input logic [10:0] vc_visible,                  //Visible vertical area in display (vc_visible)
    input logic [7:0] R_memory, G_memory, B_memory, //RGB input colours in 8 bits format
    output logic [3:0] vga_r, vga_g, vga_b          //RGB outp�t colours in 4 bits format
    );
    logic [11:0] VGA_COLOUR, VGA_COLOUR_NEXT;
    logic [3:0] R_to_vga, G_to_vga, B_to_vga;
    logic [3:0] R_grayscale, G_grayscale, B_grayscale;
    logic [3:0] R_c, G_c, B_c;
    
   Dithering inst
        (
        .hc_visible(hc_visible[1:0]),   //2 LSb of hc_visible       
        .vc_visible(vc_visible[1:0]),   //2 LSb of vc_visible       
        .SW(SW[0]),                     //For design is SW[0]       
        .R_memory,                      //Red from memory           
        .G_memory,                      //Green from memory         
        .B_memory,                      //Blue from memory          
        .R_grayscale,                   //Red to grayscale module   
        .G_grayscale,                   //Green to grayscale module 
        .B_grayscale                    //Blue to grayscale module  
        );
    Grayscale
        (
        .SW(SW[1]),          //For design is SW[1]                   
        .R_grayscale,        //RGB colours from Dithering module     
        .G_grayscale,
        .B_grayscale,
        .R_c,                //RGB colours to colour scramble module 
        .G_c,
        .B_c
        );
    Colour_scramble
        (
        //SW[15:14] for Red scramble, SW[13:12] for Green scramble and SW[11:10] for Blue scramble
        //In this module SW[7:2] = SW[15:10]
        .SW(SW[7:2]),  
        .R_c,                //RGB from Grayscale                                                                        
        .G_c,
        .B_c,
        .R_to_vga,           //RGB to display                                                                            
        .G_to_vga,
        .B_to_vga
        );    
        
    always_comb begin
        {vga_r, vga_g, vga_b} = VGA_COLOUR;     //Output concatenation
        VGA_COLOUR_NEXT = 12'h000;              //Default for the not visible area
        if ((hc_visible) && (vc_visible)) begin //Visible area
            VGA_COLOUR_NEXT = {R_to_vga, G_to_vga, B_to_vga};   //Using the 4 MSb of RGB input 8 bits
        end
    end
    
    always_ff @(posedge clk) begin
        VGA_COLOUR <= VGA_COLOUR_NEXT;
    end 
    
    
endmodule
