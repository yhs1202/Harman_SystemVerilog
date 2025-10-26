#include <stdint.h>

#define RAM_BASE_ADDR   0x10000000
#define GPO_BASE_ADDR   0x10001000
#define GPO_MODER       (*(uint32_t *)(GPO_BASE_ADDR + 0x00))
#define GPO_ODR         (*(uint32_t *)(GPO_BASE_ADDR + 0x04))

void delay(uint32_t t);

int main()
{
    uint32_t a;

    *(uint32_t *)(RAM_BASE_ADDR) = 0x01;    // Write to RAM
    a = *(uint32_t *)(RAM_BASE_ADDR);       // Read from RAM

    GPO_MODER = 0xf;

    while(1)
    {
        GPO_ODR = 0xf;  // Set all GPO pins high
        delay(300);
        GPO_ODR = 0x0;  // Set all GPO pins low
        delay(300);
    }

    return 0;
}

void delay(uint32_t t)
{
    uint32_t temp = 0;

    for (int i = 0; i < t; i++){
        for (int j = 0; j < 1000; j++){
            temp++;
        }
    }
}
