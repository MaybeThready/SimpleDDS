#pragma once

#include "ui/ui.h"

// Simple Output回调
void on_enter_simple_output_menu(UIMenu* menu);
void on_exit_simple_output_menu(UIMenu* menu);
void on_change_simple_output_enabled(UICheckbox* checkbox);
void on_change_simple_output_waveform_type(UIChooseBox* choose_box);
void on_change_simple_output_freq(UIInputBoxDouble* input_box);

// Analog Modulation回调
void on_enter_analog_modulation_menu(UIMenu* menu);
void on_exit_analog_modulation_menu(UIMenu* menu);
void on_change_analog_modulation_enabled(UICheckbox* checkbox);
void on_change_analog_modulation_type(UIChooseBox* choose_box);
void on_change_analog_modulation_carry_freq(UIInputBoxDouble* input_box);
void on_change_analog_modulation_signal_freq(UIInputBoxDouble* input_box);
void on_change_analog_modulation_depth(UIInputBoxDouble* input_box);
void on_change_analog_modulation_offset(UIInputBoxDouble* input_box);

// Digital Modulation回调
void on_enter_digital_modulation_menu(UIMenu* menu);
void on_exit_digital_modulation_menu(UIMenu* menu);
void on_change_digital_modulation_enabled(UICheckbox* checkbox);
void on_change_digital_modulation_type(UIChooseBox* choose_box);
void on_change_digital_modulation_carry_freq(UIInputBoxDouble* input_box);
void on_change_digital_modulation_bitrate(UIInputBoxDouble* input_box);
void on_change_digital_modulation_data(UIInputBoxBin* input_box);
