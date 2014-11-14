/*	piano.sv
	
	Sebastian Krupa and Ashuka Xue
	Fall 2014
  	skrupa@hmc.edu and axue@hmc.edu
*/

module digital_keyboard(input logic        sck, sdi, clk,
                        output logic [5:0] wave);

// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 
module spi_slave_receive_only(input logic          sck, //from master
                              input logic          sdi, //from master 
                              output logic [31:0]  q); // data received
	always_ff @(posedge sck)
		q <={q[30:0], sdi}; //shift register
endmodule
