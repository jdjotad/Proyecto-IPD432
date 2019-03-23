`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// vga_driver.v -- basic video driver
//
// Author:  W. Freund, UTFSM, Valparaiso, Chile
//          (based on vga_main.vhd from Barron Barnett, Digilent, Inc.) 
//          03/05/06, 14/06/12
//Modifier: Mauricio Solis
//				28/05/2014
//Modifier: Mauricio Solis
//				09/06/2017
//Modifier: Juan Escárate
//				20-10-2018
////////////////////////////////////////////////////////////////////////////////
//http://tinyvga.com/vga-timing/1024x768@75Hz

module driver_vga_1024x768(clk_vga, hs, vs,hc_visible,vc_visible);
	input clk_vga;                      // 78.8 MHz !
	output hs, vs; 
	output [10:0] hc_visible;
	output [10:0] vc_visible; 

	localparam hpixels = 11'd1312;  // --Value of pixels in a horizontal line
	localparam vlines  = 11'd800;  // --Number of horizontal lines in the display

	localparam hfp  = 11'd16;      // --Horizontal front porch
	localparam hsc  = 11'd96;      // --Horizontal sync
	localparam hbp  = 11'd176;      // --Horizontal back porch
	
	localparam vfp  = 11'd1;       // --Vertical front porch
	localparam vsc  = 11'd3;       // --Vertical sync
	localparam vbp  = 11'd28;      // --Vertical back porch
	
	
	logic [10:0] hc, hc_next, vc, vc_next;             // --These are the Horizontal and Vertical counters    
	
	assign hc_visible = ((hc < (hpixels - hfp)) && (hc > (hsc + hbp)))?(hc - (hsc + hbp)):11'd0;
	assign vc_visible = ((vc < (vlines - vfp)) && (vc > (vsc + vbp)))?(vc - (vsc + vbp)):11'd0;
	
	
	// --Runs the horizontal counter

	always_comb begin
		if (hc == hpixels)				// --If the counter has reached the end of pixel count
			hc_next = 11'd0;			// --reset the counter
		else
			hc_next = hc + 11'd1;		// --Increment the horizontal counter
	end

	// --Runs the vertical counter
	always_comb begin
		if (hc == 11'd0) begin
			if (vc == vlines)
				vc_next = 11'd0;
			else
				vc_next = vc + 11'd1;
		end
		else
			vc_next = vc;
	end

	always_ff @(posedge clk_vga)
		{hc, vc} <= {hc_next, vc_next};
		
	assign hs = (hc < hsc) ? 1'b0 : 1'b1;   // --Horizontal Sync Pulse
	assign vs = (vc < vsc) ? 1'b0 : 1'b1;   // --Vertical Sync Pulse
	
endmodule: driver_vga_1024x768
