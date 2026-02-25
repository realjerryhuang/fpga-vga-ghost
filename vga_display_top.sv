module vga_display_top(
	input clk,
	input rst,
	
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
	);

	// 25 MHz clock
	logic my_clk;
	clock_divider my_clk_divider(clk, rst, my_clk);
	
	// Reset synchronization (4-bit shift register for rst)
	logic [1:0] rst_shift = 2'b00;
	//	FF0						FF1
	//	rst_shift[1]			rst_shift[0]
	logic my_rst;
	always_ff @(posedge my_clk) begin
		rst_shift <= {rst_shift[0], rst};
	end
	assign my_rst = rst_shift[1];
	
	// 640 x 480 VGA color generation
	logic [9:0] hc, vc;
	
	// VGA driver
	logic [9:0] my_px_address;
	logic [7:0] my_px_color;
	vga_driver my_vga_driver(
		.hc(hc),
		.vc(vc),
		.px_address(my_px_address),
		.px_color(my_px_color)
	);
	
	// Ping-pong buffer
	logic [7:0] buf_read_data;
	buffer my_buf(
		.clk(my_clk),
		.hc(hc),
		.vc(vc),
		.write_address(my_px_address),
		.write_data(my_px_color),
		.read_data(buf_read_data)
	);
	
	// Color pattern
	logic [2:0] r_in, g_in;
	logic [1:0] b_in;
	assign r_in = buf_read_data[7:5];
	assign g_in = buf_read_data[4:2];
	assign b_in = buf_read_data[1:0];
	
	// VGA
	vga my_vga(
		.vgaclk(my_clk), 
		.rst(my_rst),
		.input_red(r_in),
		.input_green(g_in),
		.input_blue(b_in),
		.hc_out(hc),
		.vc_out(vc),
		.hsync(hsync),
		.vsync(vsync),
		.red(red),
		.green(green),
		.blue(blue)
	);
		
endmodule