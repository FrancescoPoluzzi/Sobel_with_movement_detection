#include <stdio.h>
#include <ov7670.h>
#include <swap.h>
#include <vga.h>

// define profiling flags : decomment one to enable a specific profiling
// #define FULL_PROFILING                    // total cycles per frame
// #define MOVEMENT_DETECTION_PROFILING      // cycles for moving additional data required for movement detection
// #define SOBEL_PROFILING                   // cycles for moving  sobel input data and performing sobel
// #define CI_MEMORY_TO_OUTPUT_PROFILING     // cycles for moving the output values back to the output vector
//  #define INITIALIZATION_PROFILING     // cycles for reading the image and iniytializing for the first tile

// constants for the dma transfers
const uint32_t writeBusStartAddress = 0x00000600;
const uint32_t writeMemoryStartAddress = 0x00000A00;
const uint32_t writeControlRegister = 0x00001600;
const uint32_t readStatusRegister = 0x00001400;
const uint32_t writeBlockSize = 0x00000E00;
const uint32_t writeBurstSize = 0x00001200;
const uint32_t writeSingleWord = 0x00000200;
const uint32_t writeSobelTreshold = 0x00001A00;
//constants for image tiling
const uint32_t block_size = 17*14;
const uint32_t burst_size = 16;
const uint32_t block_size_output = 16*12;
const uint32_t burst_size_output = 15;
const uint32_t skip_line = 640*11+64;
//constants for double buffering
const uint32_t buff1 = 0;
const uint32_t buff2 = 238;
//sobel treshold : the lower, the more sensible (0-255)
const uint32_t sobel_treshold=127;

int main () {
  volatile uint8_t grayscale[640*480];
  volatile uint8_t sobelImage[640*480];
  volatile uint8_t movement[640*480];
  volatile uint32_t  cycles,stall,idle;
  volatile unsigned int *vga = (unsigned int *) 0X50000020;
  uint32_t result;
  uint32_t pixel1, pixel2;
  uint32_t buffer, lastrow;
  uint32_t read_addr,write_addr;
  camParameters camParams;
  vga_clear();
  printf("Initialising camera (this takes up to 3 seconds)!\n" );
  camParams = initOv7670(VGA);
  printf("Done!\n" );
  printf("NrOfPixels : %d\n", camParams.nrOfPixelsPerLine );
  result = (camParams.nrOfPixelsPerLine <= 320) ? camParams.nrOfPixelsPerLine | 0x80000000 : camParams.nrOfPixelsPerLine;
  vga[0] = swap_u32(result);
  printf("NrOfLines  : %d\n", camParams.nrOfLinesPerImage );
  result =  (camParams.nrOfLinesPerImage <= 240) ? camParams.nrOfLinesPerImage | 0x80000000 : camParams.nrOfLinesPerImage;
  vga[1] = swap_u32(result);
  printf("PCLK (kHz) : %d\n", camParams.pixelClockInkHz );
  printf("FPS        : %d\n", camParams.framesPerSecond );
  uint32_t grayPixels;
  vga[2] = swap_u32(2);
  vga[3] = swap_u32((uint32_t) &sobelImage[0]);
  // initialize all values to 127 (gray) for avoiding movement detection in the first frame
  for(int i=0; i<640*480; i++){
    sobelImage[i]=127;
  }
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeSobelTreshold),[in2]"r"(sobel_treshold));
  while(1){
        #ifdef FULL_PROFILING
          asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7)); // start profiling 
        #endif
        #ifdef INITIALIZATION_PROFILING
          asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7)); // start profiling 
        #endif
          uint32_t gray = (uint32_t ) &grayscale[0];
          uint32_t sobel = (uint32_t ) &sobelImage[641];
          takeSingleImageBlocking(gray);
          //transfer first image block to ci memory
          asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeMemoryStartAddress),[in2]"r"(buff2)); 
          asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBusStartAddress),[in2]"r"(gray)); 
          asm volatile ("l.nios_rrr r0,%[in1],%[in2],0X14"::[in1]"r"(writeBlockSize),[in2]"r"(block_size));
          asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBurstSize),[in2]"r"(burst_size));
          asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeControlRegister),[in2]"r"(1)); 
          buffer=0;
          while(1){
              asm volatile ("l.nios_rrr %[out1],%[in1],r0,0x14":[out1]"=r"(result):[in1]"r"(readStatusRegister)); // read status register
              if(result==0) break;
          }         
        #ifdef INITIALIZATION_PROFILING
                  asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7<<4)); //disable counters
        #endif
          for (int i = 1; i <= 400; i++) {
                  lastrow=(i%10);
                  //move the previous values of the sobel buffer to be compared with the ones that have to be computed
                #ifdef MOVEMENT_DETECTION_PROFILING
                   asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7)); // start profiling
                #endif
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBusStartAddress),[in2]"r"(sobel));
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0X14"::[in1]"r"(writeBlockSize),[in2]"r"(block_size_output));
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBurstSize),[in2]"r"(burst_size_output));
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeMemoryStartAddress),[in2]"r"(476));  
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeControlRegister),[in2]"r"(1));  
                  while(1){
                      asm volatile ("l.nios_rrr %[out1],%[in1],r0,0x14":[out1]"=r"(result):[in1]"r"(readStatusRegister)); // read status register
                      if(result==0) break;
                  }
                #ifdef MOVEMENT_DETECTION_PROFILING
                  asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7<<4)); //disable counters
                #endif
                #ifdef SOBEL_PROFILING
                    asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7)); // start profiling 
                #endif
                  if(i<=399){ // transfer a grayscale image block to one buffer (not for the last iteration)
                        asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeMemoryStartAddress),[in2]"r"(buffer?buff2:buff1));  
                        if(lastrow==0){    
                            gray+=skip_line; // skip 12 pixel lines for the last block of a row
                        }
                        else{
                            gray+=64; // increment bus start address
                        }
                        asm volatile ("l.nios_rrr r0,%[in1],%[in2],0X14"::[in1]"r"(writeBlockSize),[in2]"r"(block_size));
                        asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBurstSize),[in2]"r"(burst_size));
                        asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBusStartAddress),[in2]"r"(gray));
                        asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeControlRegister),[in2]"r"(1)); 
                  }
                  asm volatile ("l.nios_rrr r0,r0,r0,0x15"); //start sobel + movement detection
                  while(1){ //wait for dma transfer to finish
                      asm volatile ("l.nios_rrr %[out1],%[in1],r0,0x14":[out1]"=r"(result):[in1]"r"(readStatusRegister)); // read status register
                      if(result==0) break;
                  }
                  while(1){ //wait for sobel to finish
                      asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0x14":[out1]"=r"(result):[in1]"r"(0),[in2]"r"(0)); // read status register
                      if(result==0) break;
                  }
                  #ifdef SOBEL_PROFILING
                   asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7<<4)); //disable counters
                 #endif
                 #ifdef CI_MEMORY_TO_OUTPUT_PROFILING
                   asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7)); // start profiling
                #endif
                  // transfer computed values (sobel+movement detection outputs) from ci memory to second buffer
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeMemoryStartAddress),[in2]"r"(buffer?buff1:buff2)); 
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0X14"::[in1]"r"(writeBlockSize),[in2]"r"(block_size_output));
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBurstSize),[in2]"r"(burst_size_output));
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeBusStartAddress),[in2]"r"(sobel));
                  if(lastrow==0){
                      sobel+=skip_line;  // skip 12 pixel lines for the last block of a row
                  }
                  else{
                      sobel+=64; // increment bus start address
                  }
                  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0x14"::[in1]"r"(writeControlRegister),[in2]"r"(2));  
                  while(1){ // wait for dma transfer to finish
                      asm volatile ("l.nios_rrr %[out1],%[in1],r0,0x14":[out1]"=r"(result):[in1]"r"(readStatusRegister)); // read status register
                      if(result==0) break;
                  }
                #ifdef CI_MEMORY_TO_OUTPUT_PROFILING
                   asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7<<4)); //disable counters
                #endif
                  buffer=!buffer; //switch buffer for the next iteration
          }
        // read profiling results
      #ifdef FULL_PROFILING
        asm volatile ("l.nios_rrr %[out1],r0,%[in2],0xC":[out1]"=r"(cycles):[in2]"r"(1<<8|7<<4));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
        printf("nrOfCycles: %d %d %d\n", cycles, stall, idle);
      #endif
      #ifdef MOVEMENT_DETECTION_PROFILING
        asm volatile ("l.nios_rrr %[out1],r0,%[in2],0xC":[out1]"=r"(cycles):[in2]"r"(1<<8));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
        printf("nrOfCycles for movement detection data movement overhead: %d %d %d\n", cycles, stall, idle);
      #endif
      #ifdef SOBEL_PROFILING
        asm volatile ("l.nios_rrr %[out1],r0,%[in2],0xC":[out1]"=r"(cycles):[in2]"r"(1<<8));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
        printf("nrOfCycles for Sobel loading and filtering: %d %d %d\n", cycles, stall, idle);
      #endif
      #ifdef CI_MEMORY_TO_OUTPUT_PROFILING
        asm volatile ("l.nios_rrr %[out1],r0,%[in2],0xC":[out1]"=r"(cycles):[in2]"r"(1<<8|7<<4));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
        printf("nrOfCycles for moving data from ci memory to sobel vector: %d %d %d\n", cycles, stall, idle);
      #endif
      #ifdef INITIALIZATION_PROFILING
        asm volatile ("l.nios_rrr %[out1],r0,%[in2],0xC":[out1]"=r"(cycles):[in2]"r"(1<<8|7<<4));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
        printf("nrOfCycles for initializing the frame: %d %d %d\n", cycles, stall, idle);
      #endif

  }
}
