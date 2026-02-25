module vga(
	// Incoming clock signal - 25 MHz
	input vgaclk,
	// Incoming reset signal - driven by shift register in top level
	input rst,
	
	// 8-bit color allocates 3 bits for red, 3 for green, 2 for blue
	input [2:0] input_red,
	input [2:0] input_green,
	input [1:0] input_blue,
	
	// Output horizontal and vertical counters for communication with graphics module
	output logic [9:0] hc_out,
	output logic [9:0] vc_out,
	
	// VGA outputs
	output logic hsync,
	output logic vsync,
	// Expect 12 bits for color
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
    );
	
	// VGA protocol constraints
	localparam HPIXELS	= 640;	// Number of visible pixels per horizontal line
	localparam HFP		= 16;	// Length (in pixels) of horizontal front porch
	localparam HSPULSE	= 96;	// Length (in pixels) of hsync pulse
	localparam HBP		= 48;	// Length (in pixels) of horizontal back porch
	
	localparam VPIXELS	= 480;	// Number of visible pixels per vertical line
	localparam VFP		= 10;	// Length (in pixels) of vertical front porch
	localparam VSPULSE	= 2; 	// Length (in pixels) of vsync pulse
	localparam VBP		= 33; 	// Length (in pixels) of vertical back porch
	
	// Sanity check
	initial begin
		if (HPIXELS + HFP + HSPULSE + HBP != 800 ||
			VPIXELS + VFP + VSPULSE + VBP != 525)
			begin
				$error("Expected horizontal pixels to add up to 800 ",
						"and vertical pixels to add up to 525");
			end
	end
	
	/* These registers are for storing the horizontal and vertical counters. We're
	outputting the counter values from this module so that other modules can stay
	in sync with the VGA. */
	logic [9:0] hc;
	logic [9:0] vc;
	
	initial
	begin
		hc = 1'd0;
		vc = 1'd0;
	end
	
	assign hc_out = hc;
	assign vc_out = vc;
	
	// In the sequential block, we update hc and vc based on their current values.
	always_ff @(posedge vgaclk)
	begin
		/* Update the counters, noting:
			a) the reset condition, and
			b) the conditions that cause hc and vc to go back to 0 */
		if (rst) begin
			hc <= 0;
			vc <= 0;
		end
		else if (hc == HPIXELS + HFP + HSPULSE + HBP - 1) begin
			hc <= 0;
			if (vc == VPIXELS + VFP + VSPULSE + VBP - 1)
				vc <= 0;
			else
				vc++;
		end
		else
			hc++;
	end
	
	// hsync and vsync go low
	assign hsync = ~(hc >= (HPIXELS + HFP) && hc < (HPIXELS + HFP + HSPULSE));
	assign vsync = ~(vc >= (VPIXELS + VFP - 1) && vc < (VPIXELS + VFP + VSPULSE));
	
	// In the combinational block, we set red, green, blue outputs
	always_comb
	begin
		/* If within the active video range, drive the RGB outputs with the input color values;
		if not, we're in the blanking interval, so set them all to 0 */
		if (hc < HPIXELS && vc < VPIXELS) begin
			red = {input_red, 1'b0};		// Everything must be 4 bits
			green = {input_green, 1'b0};
			blue = {input_blue, 2'b0};
		end
		else begin
			red = 0;
			green = 0;
			blue = 0;
		end
	end
	
endmodule
