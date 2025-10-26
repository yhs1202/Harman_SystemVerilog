#include <stdint.h>

#define APB_BASE_ADDR   0x10000000
#define GPO_OFFSET      0x1000
#define GPI_OFFSET      0x2000
#define GPO_BASE_ADDR   (APB_BASE_ADDR + GPO_OFFSET)
#define GPI_BASE_ADDR   (APB_BASE_ADDR + GPI_OFFSET)

#define GPO_CR          (*(uint32_t *)(GPO_BASE_ADDR + 0x00))
#define GPO_ODR         (*(uint32_t *)(GPO_BASE_ADDR + 0x04))
#define GPI_CR          (*(uint32_t *)(GPI_BASE_ADDR + 0x00))
#define GPI_IDR         (*(uint32_t *)(GPI_BASE_ADDR + 0x04))


int main()
{
    GPO_CR = 0xff;
    GPI_CR = 0xff;
    
    while(1)
    {
        GPO_ODR = GPI_IDR;
    }
    
    return 0;
}