#include "stm32f10x.h"

//#define USE_HAL 1

#ifdef USE_HAL
	#include "stm32f10x_conf.h"
#endif

volatile uint32_t msTicks;                       /* timeTicks counter */

void SysTick_Handler(void) {
	msTicks++;                                     /* increment timeTicks counter */
}

__INLINE static void delayms(uint32_t dlyTicks) {
	uint32_t curTicks = msTicks;
	while ((msTicks - curTicks) < dlyTicks);
}

#ifndef USE_HAL
//------------------------------ standard library ---------------------------------
int main(void) {
	// setup
	SysTick_Config(SystemCoreClock / 1000);								// to get ms tick
	RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;									// enable port C clock
	GPIOC->CRH &= ~( GPIO_CRH_CNF13_1 | GPIO_CRH_CNF13_0);				// config pin 13 output push-pull, zero at bits
	GPIOC->CRH |= (GPIO_CRH_MODE13_0 | GPIO_CRH_MODE13_1);				// output mode max speed 50MHz
	
	// loop
	while(1) {
		GPIOC->BSRR = GPIO_BSRR_BR13;
		delayms(200);
		GPIOC->BSRR = GPIO_BSRR_BS13;
		delayms(200);
	}
}

#else

//------------------------------- using HAL ---------------------------------------------
int main(void) {
	GPIO_InitTypeDef GPIO_InitStructure;
	GPIO_TypeDef GPIO_Structure;

	if (SysTick_Config (SystemCoreClock / 1000)) { /* Setup SysTick for 1 msec interrupts */
		;                                            /* Handle Error */
		while (1);
	}
 
	/* GPIOC Periph clock enable */
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);

	/* Configure PC13 in output pushpull mode */
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
	GPIO_Init(GPIOC, &GPIO_InitStructure);
  
	/* To achieve GPIO toggling maximum frequency, the following  sequence is mandatory. 
	 You can monitor PD0 or PD2 on the scope to measure the output signal. 
	 If you need to fine tune this frequency, you can add more GPIO set/reset 
	 cycles to minimize more the infinite loop timing.
	 This code needs to be compiled with high speed optimization option.  */
	while (1) {
		GPIO_SetBits(GPIOC, GPIO_Pin_13);
		delayms(300);		// delay 1s
		GPIO_ResetBits(GPIOC, GPIO_Pin_13);
		delayms(300);		// delay 1s
	}
}

#endif