module digital_keyboard(input logic sck, sdi, clk,
            output logic [5:0] wave);
            
    //period of each note sent from pic over spi
    logic [32:0] prd1, prd2, prd3, q;
    logic [3:0] wavesq1, wavesq2, wavesq3, 
                wavesaw1, wavesaw2, wavesaw3,
                wavetri1, wavetri2, wavetri3,
                wavesin1, wavesin2, wavesin3;
    logic[1:0] waveform, notes;
    
    //store sent value in q
    spi_slave_receive_only spi(sck, sdi, q);
    
    process_spi proc(sck, clk, q, prd1, prd2, prd3, waveform, notes);
    
    square sqr1(clk, prd1, wavesq1);
    square sqr2(clk, prd2, wavesq2);
    square sqr3(clk, prd3, wavesq3);
    
    sawtooth saw1(clk, prd1, wavesaw1);
    sawtooth saw2(clk, prd2, wavesaw2);
    sawtooth saw3(clk, prd3, wavesaw3);
    
    triangle trg1(clk, prd1, wavetri1);
    triangle trg2(clk, prd2, wavetri2);
    triangle trg3(clk, prd3, wavetri3);
    
    sine sin1(clk, prd1, wavesin1);
    sine sin2(clk, prd2, wavesin2);
    sine sin3(clk, prd3, wavesin3);
    
    generateOutput genOut(  wavesq1, wavesq2, wavesq3, 
                            wavesaw1, wavesaw2, wavesaw3,
                            wavetri1, wavetri2, wavetri3,
                            wavesin1, wavesin2, wavesin3,
                            waveform, notes, wave);
    
    
endmodule

module generateOutput(input logic [3:0] wavesq1, wavesq2, wavesq3, 
                                        wavesaw1, wavesaw2, wavesaw3,
                                        wavetri1, wavetri2, wavetri3,
                                        wavesin1, wavesin2, wavesin3,
                      input logic [1:0] waveform, notes,
                      output logic [5:0] wave);
    always_comb
        case({waveform, notes})
            4'b0001 : wave = wavesq1<<1 + wavesq1;
            4'b0101 : wave = wavesaw1<<1 + wavesaw1;
            4'b1001 : wave = wavetri1<<1 + wavetri1;
            4'b1101 : wave = wavesin1<<1 + wavesin1;
            4'b0010 : wave = (wavesq1 + wavesq2)>>1 + (wavesq1 + wavesq2);
            4'b0110 : wave = (wavesaw1 + wavesaw2)>>1 + (wavesaw1 + wavesaw2);
            4'b1010 : wave = (wavetri1 + wavetri2)>>1 + (wavetri1 + wavetri2);
            4'b1110 : wave = (wavesin1 + wavesin2)>>1 + (wavesin1 + wavesin2);
            4'b0111 : wave = wavesq1 + wavesq2 + wavesq3;
            4'b0111 : wave = wavesaw1 + wavesaw2 + wavesaw3;
            4'b0111 : wave = wavetri1 + wavetri2 + wavetri3;
            4'b0111 : wave = wavesin1 + wavesin2 + wavesin3;
            default : wave = 6'b0000;
			endcase
            
    
endmodule

// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 
module spi_slave_receive_only(  input   logic       sck, //from master
                                input   logic       sdi, //from master 
                                output  logic [31:0]  q); // data received
	always_ff @(posedge sck)
		q <={q[30:0], sdi}; //shift register
endmodule

module process_spi( input logic         sck, clk,
                    input logic  [7:0]  q,
                    output logic [31:0] prd1, prd2, prd3, 
                    output logic [1:0]  waveform, notes);
    logic [6:0] cnt = '0;
    logic moved = 1'b0; //makes sure iterator doesn't start until initial signal
	 
	 always_ff @(negedge sck)
            //don't really need cnt++ since it'll overflow
			 if(cnt == 7'd31) //first 32 bits are prd1
					begin
					prd1 <= q;
					cnt <= cnt + 1'b1;
					end
			 else if (cnt == 7'd63) //second 32 bits are prd1
					begin
					prd2 <= q;
					cnt <= cnt + 1'b1;
					end
			 else if (cnt == 7'd95) //third 32 bits are prd1
					begin
					prd3 <= q;
					cnt <= cnt + 1;
					end
			 else if (cnt == 7'd127) //last 32 bits hold waveform
					begin
					waveform <= q[1:0];
                    notes <= q[3:2];
					cnt <= 7'd000_0000; //reset cnt
					end
			 else if (moved == 1'b1)
               cnt <= cnt + 1'b1; //base case after initialize
			 else if(q == 32'hFFFF) //first initial signal
					moved <= 1'b1; //allow counting
                    
endmodule

module square(input logic clk,
              input logic [32:0] period,
              output logic [3:0] wave);
    logic [32:0] cnt = '0;
    
    always_ff @(posedge clk)
        //first half of full period == 0
        if(cnt < period>>1)
            begin
            cnt <= cnt + 1'b1;
            wave <= 4'b0000;
            end
        //second half of period == 1
        else if (cnt < period)
            begin
            cnt <= cnt + 1'b1;
            wave <= 4'b1111;
            end
        //reset counter
        else
            cnt <= '0;            
endmodule

module sawtooth(input logic clk,
              input logic [32:0] period,
              output logic [3:0] wave);
    logic [15:0] cnt = '0;
            
    always_ff @(posedge clk)
        //1/16 of period updates count
        if(cnt < period>>4)
            begin
                cnt <= cnt + 1'b1;
            end
        else
            begin
            cnt <= '0;
            wave <= wave + 1'b1; //overflow to reset
            end
endmodule

module triangle(input logic clk,
              input logic [32:0] period,
              output logic [3:0] wave);
    logic [32:0] cnt = '0;
    logic firsthalf = 1'b1;
    
    always_ff @(posedge clk)
        //period is in half because we want to alternate between going up and down
        if(cnt < period>>5)
            begin
                cnt <= cnt + 1'b1;
            end
        //first half is same as sawtooth with half the period
        else if (firsthalf)
            begin
            cnt <= '0;
            wave <= wave + 1'b1;
            
            //once we hit max value, start down slope
            if (wave == 4'b1111)
                firsthalf <= 1'b0;
            end
        //second half is the reverse of above
        else if(!firsthalf)
            begin
            cnt <= cnt <= '0;
            wave <= wave - 1'b1;
            
            // once we go back down to zero, start climbing again
            if (wave == 4'b0000)
                firsthalf <= 1'b1;
            end
endmodule

module sine(input logic clk,
              input logic [32:0] period,
              output logic [3:0] wave);
    logic [32:0] cnt = '0;
    //this will act as a clock of with a period of 1/32 period
    //this will be used to create a sine wave from 32 samples
    logic [5:0] prd64 = '0;
    
    always_ff @(posedge clk)
        if (cnt < (period>>5))
            cnt <= cnt + 1'b1;
        else
            prd64 <= prd64 + 1'b1;
    

    //cases generated in matlab using rounding
    always_comb
        case(prd64)
        6'd0 : wave = 4'b1000;    // exact:0.5          approx:0.5
        6'd1 : wave = 4'b1000;    // exact:0.54901       approx:0.5625
        6'd2 : wave = 4'b1001;    // exact:0.59755       approx:0.625
        6'd3 : wave = 4'b1010;    // exact:0.64514       approx:0.625
        6'd4 : wave = 4'b1011;    // exact:0.69134       approx:0.6875
        6'd5 : wave = 4'b1011;    // exact:0.7357       approx:0.75
        6'd6 : wave = 4'b1100;    // exact:0.77779       approx:0.75
        6'd7 : wave = 4'b1101;    // exact:0.8172       approx:0.8125
        6'd8 : wave = 4'b1101;    // exact:0.85355       approx:0.875
        6'd9 : wave = 4'b1110;    // exact:0.88651       approx:0.875
        6'd10 : wave = 4'b1110;    // exact:0.91573       approx:0.9375
        6'd11 : wave = 4'b1111;    // exact:0.94096       approx:0.9375
        6'd12 : wave = 4'b1111;    // exact:0.96194       approx:0.9375
        6'd13 : wave = 4'b1111;    // exact:0.97847       approx:1
        6'd14 : wave = 4'b1111;    // exact:0.99039       approx:1
        6'd15 : wave = 4'b1111;    // exact:0.99759       approx:1
        6'd16 : wave = 4'b10000;    // exact:1            approx:1
        6'd17 : wave = 4'b1111;    // exact:0.99759       approx:1
        6'd18 : wave = 4'b1111;    // exact:0.99039       approx:1
        6'd19 : wave = 4'b1111;    // exact:0.97847       approx:1
        6'd20 : wave = 4'b1111;    // exact:0.96194       approx:0.9375
        6'd21 : wave = 4'b1111;    // exact:0.94096       approx:0.9375
        6'd22 : wave = 4'b1110;    // exact:0.91573       approx:0.9375
        6'd23 : wave = 4'b1110;    // exact:0.88651       approx:0.875
        6'd24 : wave = 4'b1101;    // exact:0.85355       approx:0.875
        6'd25 : wave = 4'b1101;    // exact:0.8172       approx:0.8125
        6'd26 : wave = 4'b1100;    // exact:0.77779       approx:0.75
        6'd27 : wave = 4'b1011;    // exact:0.7357       approx:0.75
        6'd28 : wave = 4'b1011;    // exact:0.69134       approx:0.6875
        6'd29 : wave = 4'b1010;    // exact:0.64514       approx:0.625
        6'd30 : wave = 4'b1001;    // exact:0.59755       approx:0.625
        6'd31 : wave = 4'b1000;    // exact:0.54901       approx:0.5625
        6'd32 : wave = 4'b1000;    // exact:0.5           approx:0.5
        6'd33 : wave = 4'b0111;    // exact:0.45099       approx:0.4375
        6'd34 : wave = 4'b0110;    // exact:0.40245       approx:0.375
        6'd35 : wave = 4'b0101;    // exact:0.35486       approx:0.375
        6'd36 : wave = 4'b0100;    // exact:0.30866       approx:0.3125
        6'd37 : wave = 4'b0100;    // exact:0.2643       approx:0.25
        6'd38 : wave = 4'b0011;    // exact:0.22221       approx:0.25
        6'd39 : wave = 4'b0010;    // exact:0.1828       approx:0.1875
        6'd40 : wave = 4'b0010;    // exact:0.14645       approx:0.125
        6'd41 : wave = 4'b0001;    // exact:0.11349       approx:0.125
        6'd42 : wave = 4'b0001;    // exact:0.084265       approx:0.0625
        6'd43 : wave = 4'b0000;    // exact:0.059039       approx:0.0625
        6'd44 : wave = 4'b0000;    // exact:0.03806       approx:0.0625
        6'd45 : wave = 4'b0000;    // exact:0.02153       approx:0
        6'd46 : wave = 4'b0000;    // exact:0.0096074       approx:0
        6'd47 : wave = 4'b0000;    // exact:0.0024076       approx:0
        6'd48 : wave = 4'b0000;    // exact:0             approx:0
        6'd49 : wave = 4'b0000;    // exact:0.0024076       approx:0
        6'd50 : wave = 4'b0000;    // exact:0.0096074       approx:0
        6'd51 : wave = 4'b0000;    // exact:0.02153       approx:0
        6'd52 : wave = 4'b0000;    // exact:0.03806       approx:0.0625
        6'd53 : wave = 4'b0000;    // exact:0.059039       approx:0.0625
        6'd54 : wave = 4'b0001;    // exact:0.084265       approx:0.0625
        6'd55 : wave = 4'b0001;    // exact:0.11349       approx:0.125
        6'd56 : wave = 4'b0010;    // exact:0.14645       approx:0.125
        6'd57 : wave = 4'b0010;    // exact:0.1828       approx:0.1875
        6'd58 : wave = 4'b0011;    // exact:0.22221       approx:0.25
        6'd59 : wave = 4'b0100;    // exact:0.2643       approx:0.25
        6'd60 : wave = 4'b0100;    // exact:0.30866       approx:0.3125
        6'd61 : wave = 4'b0101;    // exact:0.35486       approx:0.375
        6'd62 : wave = 4'b0110;    // exact:0.40245       approx:0.375
        6'd63 : wave = 4'b0111;    // exact:0.45099       approx:0.4375
        default : wave = 4'b0000;
	endcase

endmodule
