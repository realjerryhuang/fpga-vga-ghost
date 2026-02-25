module buffer(	// AKA ping-pong (double) buffer
	input logic clk,					// Synchronizes read and write of buffers to VGA
	input logic [9:0] hc, vc,			// From VGA driver to calculate RAM address to read from
	input logic [9:0] write_address,	// RAM address to write at output by graphics controller
	input logic [7:0] write_data,		// Pixel color to write at specified address
	output logic [7:0] read_data		// Pixel color from read address
    );
    
    // (640/20) * (480/20) = 32 * 24 = 768 blocked pixels
    localparam BUF_SIZE = 768;
    
    // RAM implemented as two arrays of registers (buffers)
    logic [7:0] buf0 [0:BUF_SIZE - 1];
    logic [7:0] buf1 [0:BUF_SIZE - 1];
    
    logic [7:0] next_buf0 [0:BUF_SIZE - 1];
    logic [7:0] next_buf1 [0:BUF_SIZE - 1];
    
    // 1-bit register:
    // 0 = buf0 is read, buf1 is write
    // 1 = buf1 is read, buf0 is write
    logic sel_buf;
        
    // Read address derived from hc/vc
    logic [9:0] read_address;
    logic [4:0] xpos, ypos;
    assign xpos = hc / 20;
    assign ypos = vc / 20;
    assign read_address = ypos*32 + xpos;
    
    // Flip buffer selection when hc and vc both reach 0
    always_ff @(posedge clk) begin
    	if (hc == 0 && vc == 0)
    		sel_buf <= ~sel_buf;
    end
    
    // Write to write buffer; read from read buffer
    always_ff @(posedge clk) begin
    	buf0 <= next_buf0;
    	buf1 <= next_buf1;
    end
    
    always_comb begin
    	next_buf0 = buf0;
    	next_buf1 = buf1;
    
    	if (sel_buf == 0) begin
    		// buf0 = read, buf1 = write
    		next_buf1[write_address] = write_data;
    		read_data = buf0[read_address];
    	end
    	else begin
    		// buf1 = read, buf0 = write
    		next_buf0[write_address] = write_data;
    		read_data = buf1[read_address];
    	end
    end
    
endmodule
