PROJECT := blink
LIBDIR	:= ../Libraries/STM32F10x_StdPeriph_Lib_V3.5.0/Libraries
CROSS_COMPILE := c:\arm\bin\arm-none-eabi-
startup-object := sys/startup_stm32f10x_md.o

drv-objects := $(patsubst %.c,%.o,$(wildcard drv/*.c))
sys-objects := $(patsubst %.c,%.o,$(wildcard sys/*.c))
src-objects := $(patsubst %.c,%.o,$(wildcard src/*.c))
stdperiph-objects := $(patsubst %.c,%.o,$(wildcard $(LIBDIR)/STM32F10x_StdPeriph_Driver/src/*.c))


AS := $(CROSS_COMPILE)as
CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
OBJDUMP := $(CROSS_COMPILE)objdump
OBJCOPY := $(CROSS_COMPILE)objcopy
SIZE := $(CROSS_COMPILE)size

CFLAGS := -ffreestanding -mcpu=cortex-m3 -mthumb -mfloat-abi=soft -DUSE_STDPERIPH_DRIVER -DSTM32F10X_MD -O2 -flto
CFLAGS += -Isrc -Idrv -Isys 

# usb device
CFLAGS += -I $(LIBDIR)/STM32_USB-FS-Device_Driver/inc

# CMSIS - coresupport for core_cm3.c and .h;
#         stm32f10X dir for stm32f10x.h, system_stm32f10x.c & .h
CFLAGS += -I$(LIBDIR)/CMSIS/CM3/CoreSupport
CFLAGS += -I$(LIBDIR)/CMSIS/CM3/DeviceSupport/ST/STM32F10x


# std peripheral library
CFLAGS += -I$(LIBDIR)/STM32F10x_StdPeriph_Driver/inc
CCLDFLAGS := -Wl,-T -Wl,stm32.ld -flto -ffreestanding -nostdlib -Wl,--print-memory-usage

.PHONY: flash clean
.DEFAULT: all

all: $(PROJECT).hex 

# Available plats: BLUEPILL, STLINK_V2_CLONE_DONGLE
PLAT ?= BLUEPILL
CFLAGS += -D$(PLAT)

$(PROJECT).axf: $(startup-object) $(drv-objects) $(sys-objects) $(usb-objects) $(src-objects) $(stdperiph-objects) $(fsusb-objects)
	$(CC) $(CCLDFLAGS) $^ -o $@
	$(SIZE) $(PROJECT).axf

%.hex: %.axf
	$(OBJCOPY) -O ihex $< $@

%.bin: %.axf
	$(OBJCOPY) -O binary $< $@

%.lst: %.axf
	$(OBJDUMP) -x -S $< > $@

	
flash: $(PROJECT).hex
	st-link_cli -c ID=0 SWD UR LPM -P $(PROJECT).hex


clean:
	-del /s *.o
	-del /s $(PROJECT).axf $(PROJECT).hex $(PROJECT).bin $(PROJECT).lst

clean-lib:
	-del $(subst /,\, $(LIBDIR)/STM32F10x_StdPeriph_Driver/src/)*.o

clean-all:
	-del /s *.o
	-del /s $(PROJECT).axf $(PROJECT).hex $(PROJECT).bin $(PROJECT).lst
	-del $(subst /,\, $(LIBDIR)/STM32F10x_StdPeriph_Driver/src/)*.o
	-del $(subst /,\, $(LIBDIR)/STM32_USB-FS-Device_Driver/src/)*.o
	
segments:
	$(OBJDUMP) -h $(PROJECT).axf