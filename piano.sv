/*	piano.sv
	
	Sebastian Krupa and Ashuka Xue
	Fall 2014
  	skrupa@hmc.edu and axue@hmc.edu
*/

module digital_keyboard(input  logic        sck, sdi, clk,
                        output logic [7:0] wave);

	logic [31:0] q;
	logic sdi,
    
	spi_slave_receive_only spi(sck, sdi, q);
	process_spi proc(sck, clk, q, );
    

endmodule

// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 
module spi_slave_receive_only(input  logic        sck, //from master
                              input  logic        sdi, //from master 
                              output logic [31:0] q); // data received
	always_ff @(posedge sck)
		q <={q[30:0], sdi}; //shift register
endmodule

module process_spi(input  logic        sck, clk,
				   input  logic [31:0] q,
				   output logic [ 7:0] wave);

