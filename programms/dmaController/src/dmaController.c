#include <stdio.h>
#include <ov7670.h>
#include <swap.h>
#include <vga.h>

int main () {
  vga_clear();
  uint32_t valueA, valueB, result;
  printf("Program starting\n");

  printf("Writing 51 on address ab\n");
  valueA=0x00000207; // write 51 on address 7
  valueB=51;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB)); 
  valueA=0x00000007; // read 51 from address ab
  printf("Reading from address ab\n");
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB)); 
  printf("Value read: %d\n", result);

  printf("Writing 89 on busstartaddress\n");
  valueA=0x00000600; // write 89 on busstartaddress
  valueB=89;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Reading from busstartaddress\n");
  valueA=0x00000400; // read 89 from busstartaddress
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);

  printf("Writing 5 on memory start address\n");
  valueA=0x00000A00; // write 5 on memory start address
  valueB=5;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Reading from memory start address\n");
  valueA=0x00000800; // read 5 from memory start address
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);

  printf("Writing 67 on block size\n");
  valueA=0x00000E00; // write 67 on block size
  valueB=67;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Reading from block size\n");
  valueA=0x00000C00; // read 67 from block size
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);

  printf("Writing 7 on burst size\n");
  valueA=0x00001200; // write 7 on burst size
  valueB=7;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Reading from burst size\n");
  valueA=0x00001000; // read 7 from burst size
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);

  printf("Reading status register\n");
  valueA=0x000001400; // read status register
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Status register: %d\n", result);

  volatile uint32_t vector[67];
  for (uint32_t i = 0; i <= 66; i++) {
    vector[i] = i;
  }
  //valueB = swap_u32((uint32_t)vector); // save vector address
  valueB =(uint32_t)vector; // save vector address
  printf("Writing vector address on bus start address\n");
  valueA=0x00000600; // write vector address on bus start address
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Reading from busstartaddress\n");
  valueA=0x00000400; // read 89 from busstartaddress
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);
  printf("writing following vector on memory:\n");
  for (uint32_t i = 0; i <= 66; i++) {
    printf("%d ", vector[i]);
  }
  printf("\n");
  printf("Starting DMA vector write (writing 1 on control register)\n");
  valueA=0x00001600; // write 1 on control register
  valueB=1;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));

  // // for(uint32_t i = 0; i <= 66; i++) {
  // //     valueA = (0x00000200 | (i+5)); // write vector element i on memory location i+5
  // //     valueB=vector[i];
  // //     asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  // //   }
  
  valueA=0x000001400; // read status register (wait for the dma transfer to end)
  result=1;
  printf("Status register: ");
  while(result==1){
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
    printf("%d ", result);
  }
  printf("\n");



  // printf("Reading all written values:\n");
  // for (uint32_t i = 0; i <= 66; i++) {
  //   valueA = (0x00000000 | (i+5)); // read vector element i from memory location i+5
  //   asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  //   printf("Value at memory location %d: %d\n", i+5, result);
  // }

  // set all vector elements to 0
  for (uint32_t i = 0; i <= 66; i++) {
    vector[i] = (uint32_t)0;
  }

  // check autoincrement
  printf("Reading from memory start address\n");
  valueA=0x00000800; // read 5 from memory start address
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);
  printf("Reading from busstartaddress\n");
  valueA=0x00000400; // read 89 from busstartaddress
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);

  //prepare for the DMA block read
  printf("Writing 5 on memory start address\n");
  valueA=0x00000A00; // write 5 on memory start address
  valueB=5;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Reading from memory start address\n");
  valueA=0x00000800; // read 5 from memory start address
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);
  //valueB = swap_u32((uint32_t)vector); // save vector address
  volatile uint32_t readvector[100] ;

  valueB =(uint32_t)readvector; // save vector address
  printf("Writing vector address on bus start address\n");
  valueA=0x00000600; // write vector address on bus start address
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Reading from busstartaddress\n");
  valueA=0x00000400; // read 89 from busstartaddress
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
  printf("Value read: %d\n", result);

  printf("Starting DMA vector read (writing 2 on control register) \n");
  valueA=0x00001600; // write 2 on control register
  valueB=(uint32_t)2;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xFE"::[in1]"r"(valueA),[in2]"r"(valueB));  
  printf("Reading  vector from memory\n");
  
  valueA=0x000001400; // read status register (wait for the dma transfer to end)
  result=1;
  printf("Status register: ");
  while(result==1){
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xFE":[out1]"=r"(result):[in1]"r"(valueA),[in2]"r"(valueB));
    printf("%d ", result);
  }
  printf("\n");

  printf("Vector read from memory:\n");
  for (uint32_t i = 0; i <= 66; i++) {
    printf("%d ", readvector[i]);
  }
  printf("\n");
  return 0;
}

