#include <stdint.h>
#include <stdbool.h>

void movementDetection(bool firstFrame,
                        uint8_t *sobelResult,
                        uint8_t *movementResult,
                       int32_t width,
                       int32_t height) {
    uint8_t last_sobel;
        for (int i = 0; i < width * height; i++) {
            last_sobel=movementResult[i];
            if (sobelResult[i]  == 255) {
                if (last_sobel!=127) {
                    movementResult[i] = 0;
                } else {
                    movementResult[i] = 255;
                }
            } else {
                movementResult[i] = 127;
            }
        }
    
}
