# Accelerating Sobel and Movement Detection
This project is developed by Francesco Poluzzi and Francesco Murande Escobar for the final project of the CS470-Embedded Systems Design course. It focuses on accelerating sobel and movement detection algorithms through both software and hardware implementations.

## Table of Contents
- [Software Implementation](#software-implementation)
- [Accelerated Hardware Version](#accelerated-hardware-version)

## Software Implementation
The software version of the Sobel and movement detection is implemented in C. The relevant files and instructions to run this implementation are provided below.

### Source Code
- Main program: `programms/sobel/src/edgedetection.c`
- Supportive headers:
  - Movement detection functions: `programms/sobel/support/include/movement.h`
  - Sobel filter functions: `programms/sobel/support/include/sobel.h`

### Running the Program
To run the software version of the Sobel and movement detection:
1. Navigate to the configuration file at `systems/singleCore/config/project.files`.
2. Modify line 25 to point to the camera module Verilog implementation: replace with `../../../modules/camera/verilog/camera_colors.v`
3. Rebuild and load the hardware to incorporate this change and then execute the program.

## Accelerated Hardware Version
The hardware-accelerated version of the project involves modifications to Verilog files and a C program that interacts with these modifications.

### Modifications
- **Camera Module Changes:**
- File: `modules/camera/verilog/camera.v`
- Changes include modifications to the camera module to automatically calculate the grayscale values of 4 pixels at a time.

- **DMA and Memory Access:**
- File: `modules/ramDmaCi/verilog/ramDmaCi_sobel_movement_detection.v`
- This file includes a single module that includes the modifications performed on the DMA and memory access and integrates the Sobel and movement detection functionalities.

### Source Code
- Main program for the accelerated version: `programms/sobel_mov_detection/src/sobel_mov_detection.c`

### Running the Accelerated Version
Follow the normal build and run process. Line 25 of `systems/singleCore/config/project.files` should be `../../../modules/camera/verilog/camera.v`


