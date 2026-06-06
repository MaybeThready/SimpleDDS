#include "events.h"
#include "bsp/uart.h"

extern UICheckbox simple_output_checkbox;
extern UIInputBoxDouble simple_output_freq_input;
extern UIChooseBox simple_output_waveform_choose;
extern UICheckbox analog_modulation_checkbox;
extern UIChooseBox analog_modulation_type_choose;
extern UIInputBoxDouble analog_modulation_freq_input;
extern UIInputBoxDouble analog_modulation_carry_freq_input;
extern UIInputBoxDouble analog_modulation_depth_input;
extern UIInputBoxDouble analog_modulation_offset_input;
extern UICheckbox digital_modulation_checkbox;
extern UIChooseBox digital_modulation_type_choose;
extern UIInputBoxDouble digital_modulation_carry_freq_input;
extern UIInputBoxDouble digital_modulation_bitrate_input;
extern UIInputBoxBin digital_modulation_data_input;

void send_data(uint8_t ctw, uint32_t freq1, uint32_t freq2, uint32_t param)
{
    uart_send_byte(ctw, true);
    uart_send_byte(freq1 & 0xFF, true);
    uart_send_byte((freq1 >> 8) & 0xFF, true);
    uart_send_byte((freq1 >> 16) & 0xFF, true);
    uart_send_byte(freq2 & 0xFF, true);
    uart_send_byte((freq2 >> 8) & 0xFF, true);
    uart_send_byte((freq2 >> 16) & 0xFF, true);
    uart_send_byte(param & 0xFF, true);
    uart_send_byte((param >> 8) & 0xFF, true);
    uart_send_byte((param >> 16) & 0xFF, true);
}

void method0_send_data()
{
    send_data(0b10000000 | (simple_output_checkbox.checked & 0x01), (uint32_t)(simple_output_freq_input.value), 0, simple_output_waveform_choose.selected_index);
}

void method1_send_data()
{
    uint8_t ctw = 0b10100000 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4);
    uint32_t freq1 = (uint32_t)(analog_modulation_carry_freq_input.value);
    uint32_t freq2 = (uint32_t)(analog_modulation_freq_input.value);
    uint32_t param;
    if (analog_modulation_type_choose.selected_index == 0) // AM
    {
        param = (uint32_t)(analog_modulation_depth_input.value);
    }
    else // FM
    {
        param = (uint32_t)(analog_modulation_offset_input.value);
    }
    send_data(ctw, freq1, freq2, param);
}

void method2_send_data()
{
    uint8_t ctw = 0b11000000 | (digital_modulation_checkbox.checked & 0x01) | (digital_modulation_type_choose.selected_index << 4);
    uint32_t freq1 = (uint32_t)(digital_modulation_carry_freq_input.value);
    uint32_t freq2 = (uint32_t)(digital_modulation_bitrate_input.value);
    uint32_t param = (uint32_t)(digital_modulation_data_input.value);
    send_data(ctw, freq1, freq2, param);
}

// Simple Output回调
void on_enter_simple_output_menu(UIMenu* menu)
{
    method0_send_data();
}
void on_exit_simple_output_menu(UIMenu* menu)
{
}
void on_change_simple_output_enabled(UICheckbox* checkbox)
{
    method0_send_data();
}
void on_change_simple_output_waveform_type(UIChooseBox* choose_box)
{
    method0_send_data();
}
void on_change_simple_output_freq(UIInputBoxDouble* input_box)
{
    method0_send_data();
}

// Analog Modulation回调
void on_enter_analog_modulation_menu(UIMenu* menu)
{
    method1_send_data();
}
void on_exit_analog_modulation_menu(UIMenu* menu)
{
}
void on_change_analog_modulation_enabled(UICheckbox* checkbox)
{
    method1_send_data();
}
void on_change_analog_modulation_type(UIChooseBox* choose_box)
{
    method1_send_data();
}
void on_change_analog_modulation_carry_freq(UIInputBoxDouble* input_box)
{
    method1_send_data();
}
void on_change_analog_modulation_signal_freq(UIInputBoxDouble* input_box)
{
    method1_send_data();
}
void on_change_analog_modulation_depth(UIInputBoxDouble* input_box)
{
    method1_send_data();
}
void on_change_analog_modulation_offset(UIInputBoxDouble* input_box)
{
    method1_send_data();
}

// Digital Modulation回调
void on_enter_digital_modulation_menu(UIMenu* menu)
{
    method2_send_data();
}
void on_exit_digital_modulation_menu(UIMenu* menu)
{
}
void on_change_digital_modulation_enabled(UICheckbox* checkbox)
{
    method2_send_data();
}
void on_change_digital_modulation_type(UIChooseBox* choose_box)
{
    method2_send_data();
}
void on_change_digital_modulation_carry_freq(UIInputBoxDouble* input_box)
{
    method2_send_data();
}
void on_change_digital_modulation_bitrate(UIInputBoxDouble* input_box)
{
    method2_send_data();
}
void on_change_digital_modulation_data(UIInputBoxBin* input_box)
{
    method2_send_data();
}