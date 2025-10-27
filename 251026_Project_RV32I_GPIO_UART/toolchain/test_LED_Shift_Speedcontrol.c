#include <stdint.h>

#define APB_BASE_ADDR   0x10000000
#define GPO_OFFSET      0x1000
#define GPI_OFFSET      0x2000
#define GPIO_OFFSET     0x3000

#define GPO_BASE_ADDR   (APB_BASE_ADDR + GPO_OFFSET)
#define GPI_BASE_ADDR   (APB_BASE_ADDR + GPI_OFFSET)
#define GPIO_BASE_ADDR  (APB_BASE_ADDR + GPIO_OFFSET)

#define GPO_CR          (*(uint32_t *)(GPO_BASE_ADDR + 0x00))
#define GPO_ODR         (*(uint32_t *)(GPO_BASE_ADDR + 0x04))
#define GPI_CR          (*(uint32_t *)(GPI_BASE_ADDR + 0x00))
#define GPI_IDR         (*(uint32_t *)(GPI_BASE_ADDR + 0x04))
#define GPIO_CR         (*(uint32_t *)(GPIO_BASE_ADDR + 0x00))
#define GPIO_ODR        (*(uint32_t *)(GPIO_BASE_ADDR + 0x04))
#define GPIO_IDR        (*(uint32_t *)(GPIO_BASE_ADDR + 0x08))

#define DELAY_MIN  50
#define DELAY_MAX  1000

void System_init();
void delay(uint32_t t);
void LED_write(uint32_t data);
void LED_leftShift(uint32_t *pData);
void LED_rightShift(uint32_t *pData);

enum {LEFT, RIGHT};

int main()
{
    int ledData = 0x01;
    int ledState = LEFT;
    int delayTime = 800;

    System_init();

    while(1)
    {
        if (!(GPIO_IDR & (1<<7))) ledState = LEFT;
        else ledState = RIGHT;

        if (!(GPIO_IDR & (0<<5))) { // Btn_U (Speed Up)
            if (delayTime > DELAY_MIN)
                delayTime -= 50;
            delay(50);
        }
        if (!(GPIO_IDR & (1<<6))) { // Btn_D (Speed Down)
            if (delayTime < DELAY_MAX)
                delayTime += 50;
            delay(50);
        }

        LED_write(ledData);
        delay(delayTime);

        switch (ledState)
        {
            case LEFT:
                LED_leftShift(&ledData);
            break;
            case RIGHT:
                LED_rightShift(&ledData);
            break;
        }
        GPIO_ODR = (GPIO_IDR >> 4);
    }
    return 0;
}

void System_init()
{
    GPO_CR = 0xff;
    GPI_CR = 0xff;
    GPIO_CR = 0x0f;
}

void delay(uint32_t t)
{
    uint32_t temp = 0;

    for(int i=0; i<t; i++){
        for(int j=0; j<1000; j++) {
            temp++;
        }
    }
}

void LED_write(uint32_t data)
{
    GPO_ODR = data;
}

void LED_leftShift(uint32_t *pData)
{
    *pData = (*pData << 1 | *pData >> 7);
}

void LED_rightShift(uint32_t *pData)
{
    *pData = (*pData >> 1 | *pData << 7);
}