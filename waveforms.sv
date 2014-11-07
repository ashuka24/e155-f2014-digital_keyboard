module main(input logic sck, sdi, clk,
            input logic [1:0] waveform,
            output logic [5:0] wave);
            
    //period of each note sent from pic over spi
    logic [32:0] prd1, prd2, prd3;
    logic [3:0] wavesq1, wavesq2, wavesq3, 
                wavesaw1, wavesaw2, wavesaw3,
                wavetri1, wavetri2, wavetri3,
                wavesin1, wavesin2, wavesin3;
    
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
            wave <= 4'0000;
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
                cnt <= cnt + 1'b1
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
                cnt <= cnt + 1'b1
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
        if cnt < (period >> 5)
            cnt <= cnt + 1'b1;
        else
            prd64 <= prd64 + 1'b1;
    

    //cases generated in matlab using rounding
    always_comb
        case(prd64)
        4'd0 : wave = 4'b1000;    // exact:0.5          approx:0.5
        4'd1 : wave = 4'b1000;    // exact:0.54901       approx:0.5625
        4'd2 : wave = 4'b1001;    // exact:0.59755       approx:0.625
        4'd3 : wave = 4'b1010;    // exact:0.64514       approx:0.625
        4'd4 : wave = 4'b1011;    // exact:0.69134       approx:0.6875
        4'd5 : wave = 4'b1011;    // exact:0.7357       approx:0.75
        4'd6 : wave = 4'b1100;    // exact:0.77779       approx:0.75
        4'd7 : wave = 4'b1101;    // exact:0.8172       approx:0.8125
        4'd8 : wave = 4'b1101;    // exact:0.85355       approx:0.875
        4'd9 : wave = 4'b1110;    // exact:0.88651       approx:0.875
        4'd10 : wave = 4'b1110;    // exact:0.91573       approx:0.9375
        4'd11 : wave = 4'b1111;    // exact:0.94096       approx:0.9375
        4'd12 : wave = 4'b1111;    // exact:0.96194       approx:0.9375
        4'd13 : wave = 4'b1111;    // exact:0.97847       approx:1
        4'd14 : wave = 4'b1111;    // exact:0.99039       approx:1
        4'd15 : wave = 4'b1111;    // exact:0.99759       approx:1
        4'd16 : wave = 4'b10000;    // exact:1            approx:1
        4'd17 : wave = 4'b1111;    // exact:0.99759       approx:1
        4'd18 : wave = 4'b1111;    // exact:0.99039       approx:1
        4'd19 : wave = 4'b1111;    // exact:0.97847       approx:1
        4'd20 : wave = 4'b1111;    // exact:0.96194       approx:0.9375
        4'd21 : wave = 4'b1111;    // exact:0.94096       approx:0.9375
        4'd22 : wave = 4'b1110;    // exact:0.91573       approx:0.9375
        4'd23 : wave = 4'b1110;    // exact:0.88651       approx:0.875
        4'd24 : wave = 4'b1101;    // exact:0.85355       approx:0.875
        4'd25 : wave = 4'b1101;    // exact:0.8172       approx:0.8125
        4'd26 : wave = 4'b1100;    // exact:0.77779       approx:0.75
        4'd27 : wave = 4'b1011;    // exact:0.7357       approx:0.75
        4'd28 : wave = 4'b1011;    // exact:0.69134       approx:0.6875
        4'd29 : wave = 4'b1010;    // exact:0.64514       approx:0.625
        4'd30 : wave = 4'b1001;    // exact:0.59755       approx:0.625
        4'd31 : wave = 4'b1000;    // exact:0.54901       approx:0.5625
        4'd32 : wave = 4'b1000;    // exact:0.5           approx:0.5
        4'd33 : wave = 4'b0111;    // exact:0.45099       approx:0.4375
        4'd34 : wave = 4'b0110;    // exact:0.40245       approx:0.375
        4'd35 : wave = 4'b0101;    // exact:0.35486       approx:0.375
        4'd36 : wave = 4'b0100;    // exact:0.30866       approx:0.3125
        4'd37 : wave = 4'b0100;    // exact:0.2643       approx:0.25
        4'd38 : wave = 4'b0011;    // exact:0.22221       approx:0.25
        4'd39 : wave = 4'b0010;    // exact:0.1828       approx:0.1875
        4'd40 : wave = 4'b0010;    // exact:0.14645       approx:0.125
        4'd41 : wave = 4'b0001;    // exact:0.11349       approx:0.125
        4'd42 : wave = 4'b0001;    // exact:0.084265       approx:0.0625
        4'd43 : wave = 4'b0000;    // exact:0.059039       approx:0.0625
        4'd44 : wave = 4'b0000;    // exact:0.03806       approx:0.0625
        4'd45 : wave = 4'b0000;    // exact:0.02153       approx:0
        4'd46 : wave = 4'b0000;    // exact:0.0096074       approx:0
        4'd47 : wave = 4'b0000;    // exact:0.0024076       approx:0
        4'd48 : wave = 4'b0000;    // exact:0             approx:0
        4'd49 : wave = 4'b0000;    // exact:0.0024076       approx:0
        4'd50 : wave = 4'b0000;    // exact:0.0096074       approx:0
        4'd51 : wave = 4'b0000;    // exact:0.02153       approx:0
        4'd52 : wave = 4'b0000;    // exact:0.03806       approx:0.0625
        4'd53 : wave = 4'b0000;    // exact:0.059039       approx:0.0625
        4'd54 : wave = 4'b0001;    // exact:0.084265       approx:0.0625
        4'd55 : wave = 4'b0001;    // exact:0.11349       approx:0.125
        4'd56 : wave = 4'b0010;    // exact:0.14645       approx:0.125
        4'd57 : wave = 4'b0010;    // exact:0.1828       approx:0.1875
        4'd58 : wave = 4'b0011;    // exact:0.22221       approx:0.25
        4'd59 : wave = 4'b0100;    // exact:0.2643       approx:0.25
        4'd60 : wave = 4'b0100;    // exact:0.30866       approx:0.3125
        4'd61 : wave = 4'b0101;    // exact:0.35486       approx:0.375
        4'd62 : wave = 4'b0110;    // exact:0.40245       approx:0.375
        4'd63 : wave = 4'b0111;    // exact:0.45099       approx:0.4375
        default

endmodule
