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
unsigned char initSquare(void);
unsigned char initSawtooth(void);
unsigned char initTriangle(void);
unsigned char initSine(void);

void period_determiner(int);
void octave_adjust();
void octave_read();

/*****************************************************************************
 Macros and Global Variables
*****************************************************************************/
int wave;
unsigned int period = 0;
unsigned char octave = 4; // default on middle C
unsigned int note1;
unsigned int note2;
unsigned int note3;
unsigned int period1;
unsigned int period2;
unsigned int period3;
unsigned int secondtonano = 10^9; //convert seconds to picoseconds
unsigned char square[512];
unsigned char sawtooth[512];
unsigned char triangle[512];
unsigned char sine[512];

/*****************************************************************************
 Main
*****************************************************************************/
void main(void) { 

	TRISB = 0xFFFF// input from keys

	int received;
	
	initspi(); 				// initialize the SPI port
	initTimers();
	initSquare();			// initialize the waves
	initSawtooth();
	initTriangle();
	initSine();

	while(1){

		//TODO: FINISH WHILE LOOP

		spi_send_receive(wave);
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
	// Assumes peripheral clock at 10MHz
	//        Use Timer1 for note duration
	// T1CON
	// bit 15:	ON=1: enable timer
	// bit 14:	FRZ=0: keep running in exception mode
	// bit 13:	SIDL = 0: keep running in idle mode
	// bit 12:	TWDIS=1: ignore writes until current write completes
	// bit 11: 	TWIP=0: don't care in synchronous mode
	// bit 10-8: unused
	// bit 7: 	TGATE=0: disable gated accumulation
	// bit 6:   unused
	// bit 5-4: TCKPS=11: 1:256 prescaler, 0.1us*256=25.6us
	// bit 3:	unused
	// bit 2:	don't care in internal clock mode
	// bit 1:	TCS=0: use internal peripheral clock
	// bit 0:	unused
	T1CON = 0b1001000000110000;
}

unsigned char initSquare(void){
	for(int i = 0; i < 256; i++){
		square[i]=255;
		square[512-i] = 0;
	}
}

unsigned char initSawtooth(void){
	for(int i = 0;i < 512; i++){
		sawtooth[i] = i/2;
	}
}

unsigned char initTriangle(void){
	for(int i = 0; i < 256; i++){
		square[i]=i;
		square[512-i] = i;
	}
}

unsigned char initSine(void){
sine = [128, 130, 131, 133, 134, 136, 137, 139, 141, 142, 144, 145, 147, 148, 150, 151, 153, 155, 156, 158, 159, 161, 162, 164, 165, 167, 168, 170, 171, 173, 174, 176, 177, 178, 180, 181, 183, 184, 186, 187, 188, 190, 191, 192, 194, 195, 196, 198, 199, 200, 202, 203, 204, 206, 207, 208, 209, 210, 212, 213, 214, 215, 216, 217, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 234, 235, 236, 237, 238, 239, 239, 240, 241, 242, 242, 243, 244, 244, 245, 246, 246, 247, 247, 248, 249, 249, 250, 250, 250, 251, 251, 252, 252, 253, 253, 253, 254, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 254, 253, 253, 253, 252, 252, 251, 251, 250, 250, 250, 249, 249, 248, 247, 247, 246, 246, 245, 244, 244, 243, 242, 242, 241, 240, 239, 239, 238, 237, 236, 235, 234, 234, 233, 232, 231, 230, 229, 228, 227, 226, 225, 224, 223, 222, 221, 220, 219, 217, 216, 215, 214, 213, 212, 210, 209, 208, 207, 206, 204, 203, 202, 200, 199, 198, 196, 195, 194, 192, 191, 190, 188, 187, 186, 184, 183, 181, 180, 178, 177, 176, 174, 173, 171, 170, 168, 167, 165, 164, 162, 161, 159, 158, 156, 155, 153, 151, 150, 148, 147, 145, 144, 142, 141, 139, 137, 136, 134, 133, 131, 130, 128, 126, 125, 123, 122, 120, 119, 117, 115, 114, 112, 111, 109, 108, 106, 105, 103, 101, 100, 98, 97, 95, 94, 92, 91, 89, 88, 86, 85, 83, 82, 80, 79, 78, 76, 75, 73, 72, 70, 69, 68, 66, 65, 64, 62, 61, 60, 58, 57, 56, 54, 53, 52, 50, 49, 48, 47, 46, 44, 43, 42, 41, 40, 39, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 22, 21, 20, 19, 18, 17, 17, 16, 15, 14, 14, 13, 12, 12, 11, 10, 10, 9, 9, 8, 7, 7, 6, 6, 6, 5, 5, 4, 4, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 6, 6, 6, 7, 7, 8, 9, 9, 10, 10, 11, 12, 12, 13, 14, 14, 15, 16, 17, 17, 18, 19, 20, 21, 22, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 39, 40, 41, 42, 43, 44, 46, 47, 48, 49, 50, 52, 53, 54, 56, 57, 58, 60, 61, 62, 64, 65, 66, 68, 69, 70, 72, 73, 75, 76, 78, 79, 80, 82, 83, 85, 86, 88, 89, 91, 92, 94, 95, 97, 98, 100, 101, 103, 105, 106, 108, 109, 111, 112, 114, 115, 117, 119, 120, 122, 123, 125, 126];
}

/******************************************************************************
 Period and Octave
******************************************************************************/

unsigned int period_determiner(int note){
	// determine the period of the note played

	// one hot envoded note signal
	switch (note)
		case 0x0000; period = 0;
		case 0x0001; period = secondtonano/256.6; //middle c
		case 0x0002; period = secondtonano/277.2; //c sharp
		case 0x0004; period = secondtonano/293.7; //d
		case 0x0008; period = secondtonano/311.1; //d sharp
		case 0x0010; period = secondtonano/329.6; //e
		case 0x0020; period = secondtonano/349.2; //f
		case 0x0040; period = secondtonano/370.0; //f sharp
		case 0x0080; period = secondtonano/392.0; //g
		case 0x0100; period = secondtonano/415.3; //g sharp
		case 0x0200; period = secondtonano/440;   //a
		case 0x0400; period = secondtonano/466.2; //a sharp
		case 0x0800; period = secondtonano/493.9; //b

	return period;
		
}

unsigned int octave_adjust(unsigned int period) {
	// read the octave and adjusts the frequencies so that they are in the correct octave
	// frequency gets larger as octave increases. 
	// A0 = 27.5Hz, A4 = 440Hz, A8 = 7040Hz

	if (octave > 4){ // shift period up to the higher octave
		period = period*(2*(octave - 4)); 
	}
	else if (new_octave < 4){ // shift period down to the lower octave
		period = period/(2*(octave)); 
	}
	return period;
}

void octave_read(unsigned int button){
	if(button = 0b10)
		octave++;
	else if(button = 0b01)
		octave--;
}
}
