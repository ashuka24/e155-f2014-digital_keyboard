/*	keyboard_control.c
	
	Sebastian Krupa and Ashuka Xue
	Fall 2014
  	skrupa@hmc.edu and axue@hmc.edu
*/

#include <p32xxxx.h> 
#include <stdio.h>
/*****************************************************************************
 Internal Function Prototypes
*****************************************************************************/
void initspi(void);
int spi_send_receive(int);

void initTimers(void);
void initSquare(void);
void initSawtooth(void);
void initTriangle(void);
void initSine(void);

void getPeriods(unsigned short);
unsigned int octave_adjust(unsigned int);
void octave_read(void);
void getWave(unsigned int);

/*****************************************************************************
 Macros and Global Variables
*****************************************************************************/
unsigned char octave = 4; // default on middle C
unsigned int notearray[12];
unsigned int periods[3];

unsigned int periodarray[12] = {(1000000000)/261.6,  //C4
		                   (1000000000)/277.2,  //C#4
		                   (1000000000)/293.7,  //D4
		                   (1000000000)/311.1,  //Eb4
		                   (1000000000)/329.6,  //E4
		                   (1000000000)/349.2,  //F4
		                   (1000000000)/370.0,  //F#4
		                   (1000000000)/392.0,  //G4
		                   (1000000000)/415.3,  //G#4
		                   (1000000000)/440,    //A4
		                   (1000000000)/466.2,  //Bb4
		                   (1000000000)/493.9}; //B4;
unsigned char square[512], 
              sawtooth[512], 
              triangle[512]; 
unsigned char* currWave;
unsigned char sine[512] = {128, 130, 131, 133, 134, 136, 137, 139, 141, 142, 144, 145, 147, 148, 150, 151, 153, 
					155, 156, 158, 159, 161, 162, 164, 165, 167, 168, 170, 171, 173, 174, 176, 177, 178, 
					180, 181, 183, 184, 186, 187, 188, 190, 191, 192, 194, 195, 196, 198, 199, 200, 202, 
					203, 204, 206, 207, 208, 209, 210, 212, 213, 214, 215, 216, 217, 219, 220, 221, 222, 
					223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 234, 235, 236, 237, 238, 
					239, 239, 240, 241, 242, 242, 243, 244, 244, 245, 246, 246, 247, 247, 248, 249, 249, 
					250, 250, 250, 251, 251, 252, 252, 253, 253, 253, 254, 254, 254, 254, 255, 255, 255, 
					255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
					255, 255, 255, 255, 255, 254, 254, 254, 254, 253, 253, 253, 252, 252, 251, 251, 250, 
					250, 250, 249, 249, 248, 247, 247, 246, 246, 245, 244, 244, 243, 242, 242, 241, 240, 
					239, 239, 238, 237, 236, 235, 234, 234, 233, 232, 231, 230, 229, 228, 227, 226, 225, 
					224, 223, 222, 221, 220, 219, 217, 216, 215, 214, 213, 212, 210, 209, 208, 207, 206, 
					204, 203, 202, 200, 199, 198, 196, 195, 194, 192, 191, 190, 188, 187, 186, 184, 183, 
					181, 180, 178, 177, 176, 174, 173, 171, 170, 168, 167, 165, 164, 162, 161, 159, 158, 
					156, 155, 153, 151, 150, 148, 147, 145, 144, 142, 141, 139, 137, 136, 134, 133, 131, 
					130, 128, 126, 125, 123, 122, 120, 119, 117, 115, 114, 112, 111, 109, 108, 106, 105, 
					103, 101, 100, 98, 97, 95, 94, 92, 91, 89, 88, 86, 85, 83, 82, 80, 79, 78, 76, 75,
					73, 72, 70, 69, 68, 66, 65, 64, 62, 61, 60, 58, 57, 56, 54, 53, 52, 50, 49, 48, 47, 
				    46, 44, 43, 42, 41, 40, 39, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 
				    23, 22, 22, 21, 20, 19, 18, 17, 17, 16, 15, 14, 14, 13, 12, 12, 11, 10, 10, 9, 9, 8, 
				    7, 7, 6, 6, 6, 5, 5, 4, 4, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 
				    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 6, 6, 6, 7, 
				    7, 8, 9, 9, 10, 10, 11, 12, 12, 13, 14, 14, 15, 16, 17, 17, 18, 19, 20, 21, 22, 22, 
				    23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 39, 40, 41, 42, 43, 44, 
				    46, 47, 48, 49, 50, 52, 53, 54, 56, 57, 58, 60, 61, 62, 64, 65, 66, 68, 69, 70, 72, 
				    73, 75, 76, 78, 79, 80, 82, 83, 85, 86, 88, 89, 91, 92, 94, 95, 97, 98, 100, 101, 
				    103, 105, 106, 108, 109, 111, 112, 114, 115, 117, 119, 120, 122, 123, 125, 126};
unsigned char canUpdate = 0;
unsigned int countNotes = 0;
/*****************************************************************************
 Main
*****************************************************************************/
void main(void) { 

	TRISB = 0xFFFF; // input from keys
	AD1PCFG = 0xFFFF; //digital
    TRISD = 0xFF00; // 11-8 are wave selectors

	int received;

	initspi(); 				// initialize the SPI port
	initTimers();
	initSquare();			// initialize the waves
	initSawtooth();	
	initTriangle();
	

    TMR2 = 0;
    TMR3 = 0;
    TMR4 = 0;

    unsigned short count1 = 0, count2 = 0, count3 = 0;
    unsigned short notes = 0;
    unsigned char send1, send2, send3;
    unsigned int sendtot;
	
	while(1){
		 
        octave_read();
        // PORTB is note[12], octave[2], rando[2]
        notes = PORTB>>4;

        getPeriods(notes);
        // PORTD is leds[8], wave[4], rando[4]
        getWave((PORTD>>8)%16); // modding keeps everything below what you're modding by
    	
        if(periods[0] == 0) {
            send1 = 0; // no note being played
            countNotes = 0;
			count1 = 0;
        } else if(TMR2*4 >= periods[0]/512) { // TMR2*4 = 18 bits 
            send1 = currWave[count1++]; // get the sample of the wave
            TMR2 = 0; // reset timer
            countNotes = 1;
        } else {
            send1 = currWave[count1];
            countNotes = 1;
        }
	    

        if(periods[1] == 0) { // repeat for second note, if it ecists
            send2 = 0;
			count2= 0;
        } else if(TMR3*4 >= periods[1]/512) {
            send2 = currWave[count1++];
            TMR3 = 0;
            countNotes = 2; // else has 2 notes
        } else {
            send2 = currWave[count1];
            countNotes = 2;
        }
        
        if(periods[2] == 0) { // repeat for third note, if it exists
            send3 = 0; // only has 2 notes
			count3=0;
        } else if(TMR4*4 >= periods[2]/512) {
            send3 = currWave[count1++];
            TMR4 = 0;
            countNotes = 3; // else playing all 3 notes
        } else {
            send3 = currWave[count1];
            countNotes = 3;
        }

		//PORTD=send1;
		//reset counters
		count1 = count1%511;
		count2 = count2%511;
		count3 = count3%511;


        sendtot = send1 + send2<<8 + send3<<16 + countNotes<<24;  // send all three of the waves

		spi_send_receive(sendtot);

	}
	 
}

/******************************************************************************
 SPI Interfacing
******************************************************************************/
void initspi(void) {
	char junk;

	SPI2CONbits.ON = 0; // disable SPI to reset any previous state
	junk = SPI2BUF; // read SPI buffer to clear the receive buffer
	SPI2BRG = 7; //set BAUD rate to 1.25MHz, with Pclk at 20MHz 
	SPI2CONbits.MSTEN = 1; // enable master mode
	SPI2CONbits.CKE = 1; // set clock-to-data timing (data centered on rising SCK edge) 
	SPI2CONbits.ON = 1; // turn SPI on
	SPI2CONbits.MODE32 = 1; // put SPI in 32 bit mode
}

int spi_send_receive(int send) {
	SPI2BUF = send; // send data to slave
	while (!SPI2STATbits.SPIBUSY); // wait until received buffer fills, indicating data received 
	return SPI2BUF; // return received data and clear the read buffer full
}

/******************************************************************************
 Wave Generation
******************************************************************************/
void initTimers(void){
    //	Use Timer2 for frequency generation	
	//	T2CON
	//	bit 15: ON=1: enable timer
	//	bit 14: FRZ=0: keep running in exception mode
	//	bit 13: SIDL = 0: keep running in idle mode
	//	bit 12-8: unused
	//	bit 7: 	TGATE=0: disable gated accumulation
	//	bit 6-4: TCKPS=010: 1:4 prescaler
	//	bit	3:	T32=0: 16-bit timer
	//	bit 2:	unused
	//	bit 1:	TCS=0: use internal peripheral clock
	//	bit 0:	unused
	T2CON = 0b1000000001000000;
    T3CON = 0b1000000001000000;
    T4CON = 0b1000000001000000;
}

void initSquare(void){
	int i = 0;
	while(i < 256){
		square[i]=255;
		square[511-i] = 0;
		i++;
	}
}

void initSawtooth(void){
	int i = 0;
	for(;i < 512; i++){
		sawtooth[i] = i/2;
	}
}

void initTriangle(void){
	int i = 0;
	for(; i < 256; i++){
		square[i]=i;
		square[511-i] = i;
	}
}


/******************************************************************************
 Period and Octave
******************************************************************************/

void getPeriods(unsigned short notes) {
    int count = 0;
    int i = 0;
	periods[0] = 0;
	periods[1] = 0;
	periods[2] =0;
    while(i < 12) {
        notearray[i] = notes%2; // take the last bit
        if(notes%2 && (count < 3)) { //if the last bit is 1
            periods[count++] = octave_adjust(periodarray[i]); //get init period, adjust by octave, put in periods
        }
        notes = notes/2;
		i++;
    }
}

unsigned int octave_adjust(unsigned int period) {
	// read the octave and adjusts the frequencies so that they are in the correct octave
	// frequency gets larger as octave increases. 
	// A0 = 27.5Hz, A4 = 440Hz, A8 = 7040Hz
	unsigned int prd = period;
	if (octave > 4){ // shift period up to the higher octave
		prd = period*(2*(octave - 4)); 
	}
	else if (octave < 4){ // shift period down to the lower octave
		prd = period/(2*(octave)); 
	}
	return prd;
}

void octave_read(void){
	// read in the value of the octave
	if(PORTBbits.RB3) {
		octave += canUpdate;
		canUpdate = 0;
	} 
	else if(PORTBbits.RB2) {
		octave -= canUpdate;;
		canUpdate = 0;
	} 
	else {
		canUpdate = 1;
	}
		
}
/*
void getWave(unsigned int wave) {
	// determines the wave to use
	int i = 0;
    switch(wave) {
        case 0x0008 : 
			while(i<512) {
				currWave[i] = square[i];
				i++;
			}
 			break;
        case 0x0004 : 
			while(i<512) {
				currWave[i] = sawtooth[i];
				i++;
			}
 			break;
        case 0x0002 :
			while(i<512) {
				currWave[i] = triangle[i];
				i++;
			}
 			break;
        default     : 
			while(i<512) {
				currWave[i] = sawtooth[i];
				i++;
			}
 			break;
    }
}*/
void getWave(unsigned int wave) {
	// determines the wave to use
    switch(wave) {
        case 0x0008 : currWave = square; break;
        case 0x0004 : currWave = sawtooth; break;
        case 0x0002 : currWave = triangle; break;
        case 0x0001 : currWave = sine; break;
        default     : currWave = sine;
    }
}
