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

// Simple Output回调
void on_enter_simple_output_menu(UIMenu* menu)
{
    uart_send_byte(0b10000010 | (simple_output_checkbox.checked & 0x01), true);

    uint32_t freq_value = (uint32_t)(simple_output_freq_input.value);
    
    uart_send_byte(freq_value & 0xFF, true);
    uart_send_byte((freq_value >> 8) & 0xFF, true);
    uart_send_byte((freq_value >> 16) & 0xFF, true);

    uart_send_byte(simple_output_waveform_choose.selected_index, true);
}
void on_exit_simple_output_menu(UIMenu* menu)
{
}
void on_change_simple_output_enabled(UICheckbox* checkbox)
{
    uart_send_byte(0b10000000 | (simple_output_checkbox.checked & 0x01), true);
}
void on_change_simple_output_waveform_type(UIChooseBox* choose_box)
{
    uart_send_byte(0b10000100 | (simple_output_checkbox.checked & 0x01), true);
    uart_send_byte(choose_box->selected_index, true);
}
void on_change_simple_output_freq(UIInputBoxDouble* input_box)
{
    uart_send_byte(0b10000110 | (simple_output_checkbox.checked & 0x01), true);
    uint32_t freq_value = (uint32_t)(input_box->value);
    uart_send_byte(freq_value & 0xFF, true);
    uart_send_byte((freq_value >> 8) & 0xFF, true);
    uart_send_byte((freq_value >> 16) & 0xFF, true);
}

// Analog Modulation回调
void on_enter_analog_modulation_menu(UIMenu* menu)
{
    uart_send_byte(0b10100010 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4), true);
    uint32_t carry_freq_value = (uint32_t)(analog_modulation_carry_freq_input.value);
    uart_send_byte(carry_freq_value & 0xFF, true);
    uart_send_byte((carry_freq_value >> 8) & 0xFF, true);
    uart_send_byte((carry_freq_value >> 16) & 0xFF, true);

    uint32_t signal_freq_value = (uint32_t)(analog_modulation_freq_input.value);
    uart_send_byte(signal_freq_value & 0xFF, true);
    uart_send_byte((signal_freq_value >> 8) & 0xFF, true);
    uart_send_byte((signal_freq_value >> 16) & 0xFF, true);

    if (analog_modulation_type_choose.selected_index == 0) // AM
    {
        uint8_t depth_value = (uint8_t)(analog_modulation_depth_input.value);
        uart_send_byte(depth_value, true);
    }
    else if (analog_modulation_type_choose.selected_index == 1) // FM
    {
        uint32_t offset_value = (uint32_t)(analog_modulation_offset_input.value);
        uart_send_byte(offset_value & 0xFF, true);
        uart_send_byte((offset_value >> 8) & 0xFF, true);
        uart_send_byte((offset_value >> 16) & 0xFF, true);
    }
}
void on_exit_analog_modulation_menu(UIMenu* menu)
{
}
void on_change_analog_modulation_enabled(UICheckbox* checkbox)
{
    uart_send_byte(0b10100000 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4), true);
}
void on_change_analog_modulation_type(UIChooseBox* choose_box)
{
    uart_send_byte(0b10100000 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4), true);
}
void on_change_analog_modulation_carry_freq(UIInputBoxDouble* input_box)
{
    uart_send_byte(0b10100110 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4), true);

    uint32_t carry_freq_value = (uint32_t)(input_box->value);
    uart_send_byte(carry_freq_value & 0xFF, true);
    uart_send_byte((carry_freq_value >> 8) & 0xFF, true);
    uart_send_byte((carry_freq_value >> 16) & 0xFF, true);
}
void on_change_analog_modulation_signal_freq(UIInputBoxDouble* input_box)
{
    uart_send_byte(0b10101000 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4), true);

    uint32_t signal_freq_value = (uint32_t)(input_box->value);
    uart_send_byte(signal_freq_value & 0xFF, true);
    uart_send_byte((signal_freq_value >> 8) & 0xFF, true);
    uart_send_byte((signal_freq_value >> 16) & 0xFF, true);
}
void on_change_analog_modulation_depth(UIInputBoxDouble* input_box)
{
    uart_send_byte(0b10101010 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4), true);

    uint8_t depth_value = (uint8_t)(input_box->value);
    uart_send_byte(depth_value, true);
}
void on_change_analog_modulation_offset(UIInputBoxDouble* input_box)
{
    uart_send_byte(0b10101100 | (analog_modulation_checkbox.checked & 0x01) | (analog_modulation_type_choose.selected_index << 4), true);

    uint32_t offset_value = (uint32_t)(input_box->value);
    uart_send_byte(offset_value & 0xFF, true);
    uart_send_byte((offset_value >> 8) & 0xFF, true);
    uart_send_byte((offset_value >> 16) & 0xFF, true);
}

// Digital Modulation回调
void on_enter_digital_modulation_menu(UIMenu* menu)
{
    uart_send_byte(0b11000010 | (digital_modulation_checkbox.checked & 0x01) | (digital_modulation_type_choose.selected_index << 4), true);

    uint32_t carry_freq_value = (uint32_t)(digital_modulation_carry_freq_input.value);
    uart_send_byte(carry_freq_value & 0xFF, true);
    uart_send_byte((carry_freq_value >> 8) & 0xFF, true);
    uart_send_byte((carry_freq_value >> 16) & 0xFF, true);

    uint32_t bitrate_value = (uint32_t)(digital_modulation_bitrate_input.value);
    uart_send_byte(bitrate_value & 0xFF, true);
    uart_send_byte((bitrate_value >> 8) & 0xFF, true);

    uint8_t data_value = (uint8_t)(digital_modulation_data_input.value);
    uart_send_byte(data_value, true);
}
void on_exit_digital_modulation_menu(UIMenu* menu)
{
}
void on_change_digital_modulation_enabled(UICheckbox* checkbox)
{
    uart_send_byte(0b11000000 | (digital_modulation_checkbox.checked & 0x01) | (digital_modulation_type_choose.selected_index << 4), true);
}
void on_change_digital_modulation_type(UIChooseBox* choose_box)
{
    uart_send_byte(0b11000000 | (digital_modulation_checkbox.checked & 0x01) | (digital_modulation_type_choose.selected_index << 4), true);
}
void on_change_digital_modulation_carry_freq(UIInputBoxDouble* input_box)
{
    uart_send_byte(0b11000110 | (digital_modulation_checkbox.checked & 0x01) | (digital_modulation_type_choose.selected_index << 4), true);

    uint32_t carry_freq_value = (uint32_t)(input_box->value);
    uart_send_byte(carry_freq_value & 0xFF, true);
    uart_send_byte((carry_freq_value >> 8) & 0xFF, true);
    uart_send_byte((carry_freq_value >> 16) & 0xFF, true);
}
void on_change_digital_modulation_bitrate(UIInputBoxDouble* input_box)
{
    uart_send_byte(0b11001100 | (digital_modulation_checkbox.checked & 0x01) | (digital_modulation_type_choose.selected_index << 4), true);

    uint32_t bitrate_value = (uint32_t)(input_box->value);
    uart_send_byte(bitrate_value & 0xFF, true);
    uart_send_byte((bitrate_value >> 8) & 0xFF, true);
}
void on_change_digital_modulation_data(UIInputBoxBin* input_box)
{
    uart_send_byte(0b11001000 | (digital_modulation_checkbox.checked & 0x01) | (digital_modulation_type_choose.selected_index << 4), true);

    uint8_t data_value = (uint8_t)(input_box->value);
    uart_send_byte(data_value, true);
}