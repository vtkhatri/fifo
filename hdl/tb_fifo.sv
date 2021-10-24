/****************************************************************
 * tb_fifo.sv - testbench for a fifo
 *
 * Author        : Viraj Khatri (vk5@pdx.edu)
 * Last Modified : 22nd October, 2021
 *
 * Description   :
 * -----------
 * 
 ****************************************************************/

module tb_fifo;

localparam WIDTH = 8;
localparam SIZE = 12;
localparam SIZE_LOG_2 = $clog2(SIZE);

// inputs
logic clk, rst_n;
logic read, write;
logic [WIDTH-1:0] write_data;

// outputs
logic [WIDTH-1:0] read_data;
logic [WIDTH-1:0] stor [SIZE];
logic [SIZE_LOG_2-1:0] read_p, write_p;

// instantiate
fifo #(.WIDTH(WIDTH), .SIZE(SIZE)) FIFO0 (.*);

// clock
always #5 clk = ~clk;

// internals
int i;

initial begin
	$monitor("%d %b - rw=%b%b, rp_wp=%d_%d, read_write=%d_%d, stor=%p", $time, rst_n, read, write, read_p, write_p, read_data, write_data, stor);
	fork
		write_data = 8'h54;
		clk = 1;
		rst_n = 1;
		read = 0;
		write = 0;
	join

	#10 rst_n = 0;
	#10;
		rst_n = 1;
		read = 1;
	#10;
		read = 1;
		write = 1;
	#10;
		read = 0;
		for (i = 0; i<20; i++) begin
			write_data = 8'h55+i;
			#10;
		end
	#10;
		read = 1;
	#10;
		read = 0;
	#10;
		read = 1;
		write = 0;
	#150;
	$finish;
end

endmodule : tb_fifo
