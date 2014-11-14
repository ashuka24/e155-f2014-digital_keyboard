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
void octave_reader(int);

/*****************************************************************************
 Macros and Global Variables
*****************************************************************************/
int wave;
int period = 0;
int octave = 4; // default on middle C
int note1;
int note2;
int note3;
int period1;
int period2;
int period3;
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
	sine = [
	256, 
	259, 
	262, 
	265, 
	269, 
	272, 
	275, 
	278, 
	281, 
	284, 
	287, 
	290, 
	294, 
	297, 
	300, 
	303, 
	306, 
	309, 
	312, 
	315, 
	318, 
	321, 
	324, 
	327, 
	330, 
	333, 
	336, 
	339, 
	342, 
	345, 
	348, 
	351, 
	354, 
	357, 
	360, 
	363, 
	365, 
	368, 
	371, 
	374, 
	377, 
	379, 
	382, 
	385, 
	388, 
	390, 
	393, 
	396, 
	398, 
	401, 
	403, 
	406, 
	408, 
	411, 
	413, 
	416, 
	418, 
	421, 
	423, 
	426, 
	428, 
	430, 
	433, 
	435, 
	437, 
	439, 
	441, 
	444, 
	446, 
	448, 
	450, 
	452, 
	454, 
	456, 
	458, 
	460, 
	462, 
	463, 
	465, 
	467, 
	469, 
	471, 
	472, 
	474, 
	476, 
	477, 
	479, 
	480, 
	482, 
	483, 
	485, 
	486, 
	487, 
	489, 
	490, 
	491, 
	493, 
	494, 
	495, 
	496, 
	497, 
	498, 
	499, 
	500, 
	501, 
	502, 
	503, 
	504, 
	504, 
	505, 
	506, 
	506, 
	507, 
	508, 
	508, 
	509, 
	509, 
	510, 
	510, 
	510, 
	511, 
	511, 
	511, 
	512, 
	512, 
	512, 
	512, 
	512, 
	512, 
	512, 
	512, 
	512, 
	512, 
	512, 
	511, 
	511, 
	511, 
	510, 
	510, 
	510, 
	509, 
	509, 
	508, 
	508, 
	507, 
	506, 
	506, 
	505, 
	504, 
	504, 
	503, 
	502, 
	501, 
	500, 
	499, 
	498, 
	497, 
	496, 
	495, 
	494, 
	493, 
	491, 
	490, 
	489, 
	487, 
	486, 
	485, 
	483, 
	482, 
	480, 
	479, 
	477, 
	476, 
	474, 
	472, 
	471, 
	469, 
	467, 
	465, 
	463, 
	462, 
	460, 
	458, 
	456, 
	454, 
	452, 
	450, 
	448, 
	446, 
	444, 
	441, 
	439, 
	437, 
	435, 
	433, 
	430, 
	428, 
	426, 
	423, 
	421, 
	418, 
	416, 
	413, 
	411, 
	408, 
	406, 
	403, 
	401, 
	398, 
	396, 
	393, 
	390, 
	388, 
	385, 
	382, 
	379, 
	377, 
	374, 
	371, 
	368, 
	365, 
	363, 
	360, 
	357, 
	354, 
	351, 
	348, 
	345, 
	342, 
	339, 
	336, 
	333, 
	330, 
	327, 
	324, 
	321, 
	318, 
	315, 
	312, 
	309, 
	306, 
	303, 
	300, 
	297, 
	294, 
	290, 
	287, 
	284, 
	281, 
	278, 
	275, 
	272, 
	269, 
	265, 
	262, 
	259, 
	256, 
	253, 
	250, 
	247, 
	243, 
	240, 
	237, 
	234, 
	231, 
	228, 
	225, 
	222, 
	218, 
	215, 
	212, 
	209, 
	206, 
	203, 
	200, 
	197, 
	194, 
	191, 
	188, 
	185, 
	182, 
	179, 
	176, 
	173, 
	170, 
	167, 
	164, 
	161, 
	158, 
	155, 
	152, 
	149, 
	147, 
	144, 
	141, 
	138, 
	135, 
	133, 
	130, 
	127, 
	124, 
	122, 
	119, 
	116, 
	114, 
	111, 
	109, 
	106, 
	104, 
	101, 
	99, 
	96, 
	94, 
	91, 
	89, 
	86, 
	84, 
	82, 
	79, 
	77, 
	75, 
	73, 
	71, 
	68, 
	66, 
	64, 
	62, 
	60, 
	58, 
	56, 
	54, 
	52, 
	50, 
	49, 
	47, 
	45, 
	43, 
	41, 
	40, 
	38, 
	36, 
	35, 
	33, 
	32, 
	30, 
	29, 
	27, 
	26, 
	25, 
	23, 
	22, 
	21, 
	19, 
	18, 
	17, 
	16, 
	15, 
	14, 
	13, 
	12, 
	11, 
	10, 
	9, 
	8, 
	8, 
	7, 
	6, 
	6, 
	5, 
	4, 
	4, 
	3, 
	3, 
	2, 
	2, 
	2, 
	1, 
	1, 
	1, 
	0, 
	0, 
	0, 
	0, 
	0, 
	0, 
	0, 
	0, 
	0, 
	0, 
	0, 
	1, 
	1, 
	1, 
	2, 
	2, 
	2, 
	3, 
	3, 
	4, 
	4, 
	5, 
	6, 
	6, 
	7, 
	8, 
	8, 
	9, 
	10, 
	11, 
	12, 
	13, 
	14, 
	15, 
	16, 
	17, 
	18, 
	19, 
	21, 
	22, 
	23, 
	25, 
	26, 
	27, 
	29, 
	30, 
	32, 
	33, 
	35, 
	36, 
	38, 
	40, 
	41, 
	43, 
	45, 
	47, 
	49, 
	50, 
	52, 
	54, 
	56, 
	58, 
	60, 
	62, 
	64, 
	66, 
	68, 
	71, 
	73, 
	75, 
	77, 
	79, 
	82, 
	84, 
	86, 
	89, 
	91, 
	94, 
	96, 
	99, 
	101, 
	104, 
	106, 
	109, 
	111, 
	114, 
	116, 
	119, 
	122, 
	124, 
	127, 
	130, 
	133, 
	135, 
	138, 
	141, 
	144, 
	147, 
	149, 
	152, 
	155, 
	158, 
	161, 
	164, 
	167, 
	170, 
	173, 
	176, 
	179, 
	182, 
	185, 
	188, 
	191, 
	194, 
	197, 
	200, 
	203, 
	206, 
	209, 
	212, 
	215, 
	218, 
	222, 
	225, 
	228, 
	231, 
	234, 
	237, 
	240, 
	243, 
	247, 
	250, 
	253, 
	];
}

/******************************************************************************
 Period and Octave
******************************************************************************/

void period_determiner(int note){
	// determine the period of the note played

	// TODO: CREATE CASE STATEMENT FOR THE DIFFERENT NOTES
	switch (note)
		case 0x0000 
		case 0x0009; period = 1/440 //440Hz
}

void octave_reader(int octave) {
	// read the octave and adjusts the frequencies so that they are in the correct octave
	// frequency gets larger as octave increases. 
	// A0 = 27.5Hz, A4 = 440Hz, A8 = 7040Hz

	if (new_octave > 4){ // shift period up to the higher octave
		period = period*(2*(new_octave - 4)); 
	}
	else if (new_octave < 4){ // shift period down to the lower octave
		period = period/(2*(octave - 4)); 
	}
	octave = new_octave;
}
