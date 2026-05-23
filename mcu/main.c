#include "ti_msp_dl_config.h"
#include "bsp/msp_sys.h"
#include "bsp/oled.h"
#include "bsp/keyboard.h"
#include "bsp/uart.h"
#include <string.h>


int main()
{
    SYSCFG_DL_init();
    init_sys();
    init_oled();
    init_keyboard();
    init_uart();

    char test_str[] = "Hello, World!";

    while (1)
    {
        uart_send_byte(0b10101011, true);
        delay_cycles(TIME_MS(1000));
    }

    return 0;
}
