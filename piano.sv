/*	piano.sv
	
	Sebastian Krupa and Ashuka Xue
	Fall 2014
  	skrupa@hmc.edu and axue@hmc.edu
*/

module piano(input  logic       sck, sdi, clk,
             output logic [7:0] led,
             output logic dclk, data, load, ldac);

	logic [31:0] q;
	logic [7:0] note1, note2, note3;
   logic [7:0] wave;
	logic [7:0] atten1, atten2, atten3;
	logic [1:0] notescount;

	spi_slave_receive_only spi(sck, sdi, q);
	process_spi proc(sck, q, note1, note2, note3, notescount);
	assign atten1 = note1;
	assign atten2 = note2;
	assign atten3 = note3;
//	attenuation first(clk, note1, atten1);
//	attenuation second(clk, note2, atten2);
//	attenuation third(clk, note3, atten3);
	 add_notes add(atten1, atten2, atten3, notescount, wave);
    //assign wave = note1;
	 assign led = notescount;
    dacProcess dac(clk, wave, data, dclk, load, ldac);
	 
    

endmodule

module dacProcess(input logic clk,
                    input logic [7:0] wave,
                    output logic data, dclk, load, ldac);
    logic [15:0] cnt = '0;
	 logic [6:0] cnt2;
    logic [7:0] wavekeep;
    
    always_ff @(posedge clk)
        begin
        /*if(cnt == 16'b0)
            begin
            wavekeep<=wave;
            end*/
        if(cnt < 16'd160)
            begin
				wavekeep<=wave;
            data <= 1'b0;
            load <= 1'b1;
            ldac <= 1'b1;
				if(cnt2 == 7'd0)
					dclk <= 1'b1;
				if(cnt2 == 7'd20)
					begin
					dclk <= 1'b0;
					end
            end
        else if(cnt < 16'd480)
            begin  
            load <= 1'b1;
            ldac <= 1'b1;
            if(cnt2 == 7'd0)
					begin
					dclk <= 1'b1;
					end
				if (cnt2 == 7'd15)
					begin
					data <= wavekeep[7];
					wavekeep <= {wavekeep[6:0], 1'b0};
					end
				if(cnt2 == 7'd20)
					begin
					dclk <= 1'b0;
					end
            end
        else if(cnt < 16'd520)
            begin
            data <= 1'b0;
            load <= 1'b0;
            ldac <= 1'b1;
            dclk <= 1'b0;;
				end
        else if(cnt < 16'd560)
            begin
            data <= 1'b0;
            load <= 1'b1;
            ldac <= 1'b0;
            dclk <= 1'b0;
            end
        else if(cnt == 16'd560)
            begin
            data <= 1'b0;
            load <= 1'b1;
            ldac <= 1'b1;
            dclk <= 1'd0;
            end
        if(cnt < 16'd561)
            cnt <= cnt + 1'b1;
		  else
				cnt <= 16'b0;
		  if(cnt2 < 7'd40)
				cnt2 <= cnt2 + 1'b1;
		  else
				cnt2 <= 7'd0;
		 end
endmodule

// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 
module spi_slave_receive_only(input  logic        sck, //from master
                              input  logic        sdi, //from master 
                              output logic [31:0] q); // data received
	always_ff @(posedge sck)
		q <={q[30:0], sdi}; //shift register
endmodule

module process_spi( input logic         sck,
                    input logic  [31:0] q,
                    output logic [7:0]  note1, note2, note3,
                    output logic [1:0]  notescount);
    logic [6:0] cnt = 6'b00_0000; 
	 logic moved = 1'b0;
    //logic moved = 1'b0; //makes sure iterator doesn't start until initial signal
	 
	 always_ff @(negedge sck)
		if(moved)
		begin
			if(cnt == 6'd31) // read the note after the entire 32 bit number has come in 
			begin
				note1 <= q[7:0];
				note2 <= q[15:8];
				note3 <= q[23:16];
				notescount <= q[25:24];
				cnt <= '0;
			end
			else
				cnt <= cnt + 1'b1;
		end
		else if(~moved && q == 32'hFFFF)
			moved = 1'b1;
			
endmodule

module add_notes(input logic [7:0] note1, note2, note3,
				 input logic [1:0] notescount,
				 output logic [7:0] notes);
	// adds the three notes together (if there are three) and makes sure the amplitude doesn't change

	logic [9:0] intermed, sft2, sft4, sft6, sft8;
	assign intermed = (note1 + note2 + note3);
	assign sft2 = intermed>>2;
	assign sft4 = intermed>>4;
	assign sft6 = intermed>>6;
	assign sft8 = intermed>>8;

	always_comb 
		if (notescount == 2'b01)
			notes = intermed;
		else if (notescount == 2'b10)
			notes = intermed>>1;
		else if (notescount == 2'b11)
			notes = sft2+sft4+sft6+sft8; //divide by 3.011 = ~3
		else // no note being played
			notes = '0;

endmodule

module attenuation(input  logic       clk,
				   input  logic [7:0] wave,
				   output logic [7:0] attenuated);

	// make it sound like an actual key that, when hit is loud then fades out over time
	// gets to max volume after 0.5 s
	// stays at max for 0.5 s
	// fades out over 3 s

	logic [23:0] cnt = '0;
	logic [7:0] whole01, frac002, frac004, frac008, frac016, frac032, frac064, frac128;
	assign whole01 = wave;
	assign frac002 = wave>>1;
	assign frac004 = wave>>2;
	assign frac008 = wave>>3;
	assign frac016 = wave>>4;
	assign frac032 = wave>>5;
	assign frac064 = wave>>6;
	assign frac128 = wave>>7;

	always_ff@(posedge clk)
		 begin
		 if(cnt < 25'd625000) 
		     attenuated <=frac008 + frac032 + frac064;
		 else if(cnt < 25'd1250000) 
		     attenuated <= frac004;
		 else if(cnt < 25'd1875000) 
		     attenuated <= frac004 + frac032 + frac064 + frac128;
		 else if(cnt < 25'd2500000) 
		     attenuated <= frac004 + frac016 + frac032 + frac128;
		 else if(cnt < 25'd3125000) 
		     attenuated <= frac004 + frac008 + frac064;
		 else if(cnt < 25'd3750000) 
		     attenuated <= frac004 + frac008 + frac032 + frac064 + frac128;
		 else if(cnt < 25'd4375000) 
		     attenuated <= frac004 + frac008 + frac016 + frac064 + frac128;
		 else if(cnt < 25'd5000000) 
		     attenuated <= frac002;
		 else if(cnt < 25'd5625000) 
		     attenuated <= frac002 + frac064 + frac128;
		 else if(cnt < 25'd6250000) 
		     attenuated <= frac002 + frac032 + frac064 + frac128;
		 else if(cnt < 25'd6875000) 
		     attenuated <= frac002 + frac016 + frac064 + frac128;
		 else if(cnt < 25'd7500000) 
		     attenuated <= frac002 + frac016 + frac032 + frac064;
		 else if(cnt < 25'd8125000) 
		     attenuated <= frac002 + frac008 + frac128;
		 else if(cnt < 25'd8750000) 
		     attenuated <= frac002 + frac008 + frac032;
		 else if(cnt < 25'd9375000) 
		     attenuated <= frac002 + frac008 + frac032 + frac064 + frac128;
		 else if(cnt < 25'd10000000) 
		     attenuated <= frac002 + frac008 + frac016 + frac064;
		 else if(cnt < 25'd10625000) 
		     attenuated <= frac002 + frac008 + frac016 + frac032 + frac128;
		 else if(cnt < 25'd11250000) 
		     attenuated <= frac002 + frac004;
		 else if(cnt < 25'd11875000) 
		     attenuated <= frac002 + frac004 + frac064;
		 else if(cnt < 25'd12500000) 
		     attenuated <= frac002 + frac004 + frac032 + frac128;
		 else if(cnt < 25'd13125000) 
		     attenuated <= frac002 + frac004 + frac032 + frac064 + frac128;
		 else if(cnt < 25'd13750000) 
		     attenuated <= frac002 + frac004 + frac016 + frac064;
		 else if(cnt < 25'd14375000) 
		     attenuated <= frac002 + frac004 + frac016 + frac032;
		 else if(cnt < 25'd15000000) 
		     attenuated <= frac002 + frac004 + frac016 + frac032 + frac064;
		 else if(cnt < 25'd15625000) 
		     attenuated <= frac002 + frac004 + frac008 + frac128;
		 else if(cnt < 25'd16250000) 
		     attenuated <= frac002 + frac004 + frac008 + frac064 + frac128;
		 else if(cnt < 25'd16875000) 
		     attenuated <= frac002 + frac004 + frac008 + frac032 + frac128;
		 else if(cnt < 25'd17500000) 
		     attenuated <= frac002 + frac004 + frac008 + frac032 + frac064 + frac128;
		 else if(cnt < 25'd18125000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac128;
		 else if(cnt < 25'd18750000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac064 + frac128;
		 else if(cnt < 25'd19375000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac032 + frac128;
		 else if(cnt < 25'h2625A00) //sustain
		     attenuated <= whole01;
		 else if(cnt < 27'd42500000) //decay
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac032 + frac064;
		 else if(cnt < 27'd43750000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac032 + frac128;
		 else if(cnt < 27'd45000000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac032;
		 else if(cnt < 27'd46250000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac064 + frac128;
		 else if(cnt < 27'd47500000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac064;
		 else if(cnt < 27'd48750000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016 + frac128;
		 else if(cnt < 27'd50000000) 
		     attenuated <= frac002 + frac004 + frac008 + frac016;
		 else if(cnt < 27'd51250000) 
		     attenuated <= frac002 + frac004 + frac008 + frac032 + frac064 + frac128;
		 else if(cnt < 27'd52500000) 
		     attenuated <= frac002 + frac004 + frac008 + frac032 + frac064;
		 else if(cnt < 27'd53750000) 
		     attenuated <= frac002 + frac004 + frac008 + frac032 + frac128;
		 else if(cnt < 27'd55000000) 
		     attenuated <= frac002 + frac004 + frac008 + frac032;
		 else if(cnt < 27'd56250000) 
		     attenuated <= frac002 + frac004 + frac008 + frac064 + frac128;
		 else if(cnt < 27'd57500000) 
		     attenuated <= frac002 + frac004 + frac008 + frac064;
		 else if(cnt < 27'd58750000) 
		     attenuated <= frac002 + frac004 + frac008 + frac128;
		 else if(cnt < 27'd60000000) 
		     attenuated <= frac002 + frac004 + frac008;
		 else if(cnt < 27'd61250000) 
		     attenuated <= frac002 + frac004 + frac016 + frac032 + frac064;
		 else if(cnt < 27'd62500000) 
		     attenuated <= frac002 + frac004 + frac016 + frac032 + frac128;
		 else if(cnt < 27'd63750000) 
		     attenuated <= frac002 + frac004 + frac016 + frac032;
		 else if(cnt < 27'd65000000) 
		     attenuated <= frac002 + frac004 + frac016 + frac064 + frac128;
		 else if(cnt < 27'd66250000) 
		     attenuated <= frac002 + frac004 + frac016 + frac064;
		 else if(cnt < 27'd67500000) 
		     attenuated <= frac002 + frac004 + frac016;
		 else if(cnt < 27'd68750000) 
		     attenuated <= frac002 + frac004 + frac032 + frac064 + frac128;
		 else if(cnt < 27'd70000000) 
		     attenuated <= frac002 + frac004 + frac032 + frac064;
		 else if(cnt < 27'd71250000) 
		     attenuated <= frac002 + frac004 + frac032 + frac128;
		 else if(cnt < 27'd72500000) 
		     attenuated <= frac002 + frac004 + frac064 + frac128;
		 else if(cnt < 27'd73750000) 
		     attenuated <= frac002 + frac004 + frac064;
		 else if(cnt < 27'd75000000) 
		     attenuated <= frac002 + frac004 + frac128;
		 else if(cnt < 27'd76250000) 
		     attenuated <= frac002 + frac004;
		 else if(cnt < 27'd77500000) 
		     attenuated <= frac002 + frac008 + frac016 + frac032 + frac064;
		 else if(cnt < 27'd78750000) 
		     attenuated <= frac002 + frac008 + frac016 + frac032 + frac128;
		 else if(cnt < 27'd80000000) 
		     attenuated <= frac002 + frac008 + frac016 + frac064 + frac128;
		 else if(cnt < 27'd81250000) 
		     attenuated <= frac002 + frac008 + frac016 + frac064;
		 else if(cnt < 27'd82500000) 
		     attenuated <= frac002 + frac008 + frac016 + frac128;
		 else if(cnt < 27'd83750000) 
		     attenuated <= frac002 + frac008 + frac032 + frac064 + frac128;
		 else if(cnt < 27'd85000000) 
		     attenuated <= frac002 + frac008 + frac032 + frac064;
		 else if(cnt < 27'd86250000) 
		     attenuated <= frac002 + frac008 + frac032;
		 else if(cnt < 27'd87500000) 
		     attenuated <= frac002 + frac008 + frac064 + frac128;
		 else if(cnt < 27'd88750000) 
		     attenuated <= frac002 + frac008 + frac128;
		 else if(cnt < 27'd90000000) 
		     attenuated <= frac002 + frac008;
		 else if(cnt < 27'd91250000) 
		     attenuated <= frac002 + frac016 + frac032 + frac064;
		 else if(cnt < 27'd92500000) 
		     attenuated <= frac002 + frac016 + frac032;
		 else if(cnt < 27'd93750000) 
		     attenuated <= frac002 + frac016 + frac064 + frac128;
		 else if(cnt < 27'd95000000) 
		     attenuated <= frac002 + frac016 + frac128;
		 else if(cnt < 27'd96250000) 
		     attenuated <= frac002 + frac032 + frac064 + frac128;
		 else if(cnt < 27'd97500000) 
		     attenuated <= frac002 + frac032 + frac128;
		 else if(cnt < 27'd98750000) 
		     attenuated <= frac002 + frac064 + frac128;
		 else if(cnt < 27'd100000000) 
		     attenuated <= frac002 + frac128;
		 else if(cnt < 27'd101250000) 
		     attenuated <= frac002;
		 else if(cnt < 27'd102500000) 
		     attenuated <= frac004 + frac008 + frac016 + frac032 + frac128;
		 else if(cnt < 27'd103750000) 
		     attenuated <= frac004 + frac008 + frac016 + frac064 + frac128;
		 else if(cnt < 27'd105000000) 
		     attenuated <= frac004 + frac008 + frac016 + frac128;
		 else if(cnt < 27'd106250000) 
		     attenuated <= frac004 + frac008 + frac032 + frac064 + frac128;
		 else if(cnt < 27'd107500000) 
		     attenuated <= frac004 + frac008 + frac032 + frac128;
		 else if(cnt < 27'd108750000) 
		     attenuated <= frac004 + frac008 + frac064;
		 else if(cnt < 27'd110000000) 
		     attenuated <= frac004 + frac008;
		 else if(cnt < 27'd111250000) 
		     attenuated <= frac004 + frac016 + frac032 + frac128;
		 else if(cnt < 27'd112500000) 
		     attenuated <= frac004 + frac016 + frac064;
		 else if(cnt < 27'd113750000) 
		     attenuated <= frac004 + frac032 + frac064 + frac128;
		 else if(cnt < 27'd115000000) 
		     attenuated <= frac004 + frac064 + frac128;
		 else if(cnt < 27'd116250000) 
		     attenuated <= frac004;
		 else if(cnt < 27'd117500000) 
		     attenuated <= frac008 + frac016 + frac064 + frac128;
		 else if(cnt < 27'd118750000) 
		     attenuated <= frac008 + frac032 + frac064;
		 else if(cnt < 27'd120000000) 
		     attenuated <= frac008;
		 else
		     cnt <= '0;
		 
		 cnt <= cnt+1'b1;
		 end
endmodule
