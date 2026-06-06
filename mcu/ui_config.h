#include "ui/ui.h"
#include "bsp/keyboard.h"
#include "bsp/msp_sys.h"
#include "events.h"

static const char* freq_suffixes[] = { "Hz", "kHz", "MHz" };
static const double freq_coeffs[] = { 1.0, 1e-3, 1e-6 };
static const char* bitrate_suffixes[] = { "bps", "kbps" };
static const double bitrate_coeffs[] = { 1.0, 1e-3 };
static const char* rate_suffixes[] = { "%" };
static const double rate_coeffs[] = { 1.0 };

UIMenu main_menu;

UIMenu simple_output_menu;
UICheckbox simple_output_checkbox;
UIInputBoxDouble simple_output_freq_input;
UIChooseBox simple_output_waveform_choose;
static const char* simple_output_waveform_options[] = { "Sine", "Square", "Triangle", "Sawtooth" };
static UIWidget* simple_output_menu_items[] = {
    &simple_output_checkbox.base,
    &simple_output_freq_input.base.base,
    &simple_output_waveform_choose.base.base
};

UIMenu analog_modulation_menu;
UICheckbox analog_modulation_checkbox;
UIChooseBox analog_modulation_type_choose;
static const char* analog_modulation_type_options[] = { "AM", "FM" };
UIInputBoxDouble analog_modulation_freq_input;
UIInputBoxDouble analog_modulation_carry_freq_input;
UIInputBoxDouble analog_modulation_depth_input;
UIInputBoxDouble analog_modulation_offset_input;
static UIWidget* analog_modulation_menu_items[] = {
    &analog_modulation_checkbox.base,
    &analog_modulation_type_choose.base.base,
    &analog_modulation_freq_input.base.base,
    &analog_modulation_carry_freq_input.base.base,
    &analog_modulation_depth_input.base.base,
    &analog_modulation_offset_input.base.base
};

UIMenu digital_modulation_menu;
UICheckbox digital_modulation_checkbox;
UIChooseBox digital_modulation_type_choose;
static const char* digital_modulation_type_options[] = { "ASK", "PSK" };
UIInputBoxDouble digital_modulation_carry_freq_input;
UIInputBoxDouble digital_modulation_bitrate_input;
UIInputBoxBin digital_modulation_data_input;
static UIWidget* digital_modulation_menu_items[] = {
    &digital_modulation_checkbox.base,
    &digital_modulation_type_choose.base.base,
    &digital_modulation_carry_freq_input.base.base,
    &digital_modulation_bitrate_input.base.base,
    &digital_modulation_data_input.base.base
};

static UIWidget* main_menu_items[] = {
    &simple_output_menu.base,
    &analog_modulation_menu.base,
    &digital_modulation_menu.base
};

static void init_ui()
{
    ui_key_left = &keyboard_keys[1][0];
    ui_key_up = &keyboard_keys[0][1];
    ui_key_right = &keyboard_keys[1][2];
    ui_key_down = &keyboard_keys[2][1];
    ui_key_enter = &keyboard_keys[3][3];
    ui_key_back = &keyboard_keys[0][3];
    ui_key_incr = ui_key_right;
    ui_key_decr = ui_key_left;
    ui_key_scr_up = &keyboard_keys[1][3];
    ui_key_scr_down = &keyboard_keys[2][3];
    ui_key_0 = &keyboard_keys[3][1];
    ui_key_1 = &keyboard_keys[0][0];
    ui_key_2 = &keyboard_keys[0][1];
    ui_key_3 = &keyboard_keys[0][2];
    ui_key_4 = &keyboard_keys[1][0];
    ui_key_5 = &keyboard_keys[1][1];
    ui_key_6 = &keyboard_keys[1][2];
    ui_key_7 = &keyboard_keys[2][0];
    ui_key_8 = &keyboard_keys[2][1];
    ui_key_9 = &keyboard_keys[2][2];
    ui_key_point = &keyboard_keys[3][0];

    // ===== 初始化主菜单 =====

    // ===== 初始化Simple Output菜单 =====

    init_ui_checkbox(&simple_output_checkbox, "Enable", false);
    init_ui_input_box_double(&simple_output_freq_input, "Freq", 1000.0, freq_coeffs, freq_suffixes, sizeof(freq_suffixes) / sizeof(freq_suffixes[0]), 2, true);
    simple_output_freq_input.selected_suffix_index = 1;
    init_ui_choose_box(&simple_output_waveform_choose, "Waveform", simple_output_waveform_options, sizeof(simple_output_waveform_options) / sizeof(simple_output_waveform_options[0]), 0);

    init_ui_menu(&simple_output_menu, "Simple Output", simple_output_menu_items, sizeof(simple_output_menu_items) / sizeof(simple_output_menu_items[0]));

    // ===== 结束Simple Output菜单初始化 =====

    // ===== 初始化Analog Modulation菜单 =====

    init_ui_checkbox(&analog_modulation_checkbox, "Enable", false);
    init_ui_choose_box(&analog_modulation_type_choose, "Type", analog_modulation_type_options, sizeof(analog_modulation_type_options) / sizeof(analog_modulation_type_options[0]), 0);
    init_ui_input_box_double(&analog_modulation_freq_input, "Mod Freq", 1000.0, freq_coeffs, freq_suffixes, sizeof(freq_suffixes) / sizeof(freq_suffixes[0]), 2, true);
    analog_modulation_freq_input.selected_suffix_index = 1;
    init_ui_input_box_double(&analog_modulation_carry_freq_input, "Carr Freq", 1000000.0, freq_coeffs, freq_suffixes, sizeof(freq_suffixes) / sizeof(freq_suffixes[0]), 2, true);
    analog_modulation_carry_freq_input.selected_suffix_index = 2;
    init_ui_input_box_double(&analog_modulation_depth_input, "Depth", 100.0, rate_coeffs, rate_suffixes, sizeof(rate_suffixes) / sizeof(rate_suffixes[0]), 1, true);
    init_ui_input_box_double(&analog_modulation_offset_input, "Freq Offset", 5000.0, freq_coeffs, freq_suffixes, sizeof(freq_suffixes) / sizeof(freq_suffixes[0]), 2, true);
    analog_modulation_offset_input.selected_suffix_index = 1;

    init_ui_menu(&analog_modulation_menu, "Analog Modulation", analog_modulation_menu_items, sizeof(analog_modulation_menu_items) / sizeof(analog_modulation_menu_items[0]));

    // ===== 结束Analog Modulation菜单初始化 =====

    // ===== 初始化Digital Modulation菜单 =====

    init_ui_checkbox(&digital_modulation_checkbox, "Enable", false);
    init_ui_choose_box(&digital_modulation_type_choose, "Type", digital_modulation_type_options, sizeof(digital_modulation_type_options) / sizeof(digital_modulation_type_options[0]), 0);
    init_ui_input_box_double(&digital_modulation_carry_freq_input, "Carr Freq", 100000.0, freq_coeffs, freq_suffixes, sizeof(freq_suffixes) / sizeof(freq_suffixes[0]), 2, true);
    digital_modulation_carry_freq_input.selected_suffix_index = 1;
    init_ui_input_box_double(&digital_modulation_bitrate_input, "Bitrate", 10000.0, bitrate_coeffs, bitrate_suffixes, sizeof(bitrate_suffixes) / sizeof(bitrate_suffixes[0]), 2, true);
    digital_modulation_bitrate_input.selected_suffix_index = 1;
    init_ui_input_box_bin(&digital_modulation_data_input, "Data", 0, 8);

    init_ui_menu(&digital_modulation_menu, "Digital Modulation", digital_modulation_menu_items, sizeof(digital_modulation_menu_items) / sizeof(digital_modulation_menu_items[0]));

    // ===== 结束Digital Modulation菜单初始化 =====

    init_ui_menu(&main_menu, "Simple DDS", main_menu_items, sizeof(main_menu_items) / sizeof(main_menu_items[0]));

    // ===== 结束主菜单初始化 =====

    ui_main_menu = &main_menu;

    // 事件绑定

    // Simple Output事件绑定
    simple_output_menu.on_enter = on_enter_simple_output_menu;
    simple_output_menu.on_exit = on_exit_simple_output_menu;
    simple_output_checkbox.on_value_changed = on_change_simple_output_enabled;
    simple_output_waveform_choose.on_value_changed = on_change_simple_output_waveform_type;
    simple_output_freq_input.on_value_changed = on_change_simple_output_freq;

    // Analog Modulation事件绑定
    analog_modulation_menu.on_enter = on_enter_analog_modulation_menu;
    analog_modulation_menu.on_exit = on_exit_analog_modulation_menu;
    analog_modulation_checkbox.on_value_changed = on_change_analog_modulation_enabled;
    analog_modulation_type_choose.on_value_changed = on_change_analog_modulation_type;
    analog_modulation_freq_input.on_value_changed = on_change_analog_modulation_signal_freq;
    analog_modulation_carry_freq_input.on_value_changed = on_change_analog_modulation_carry_freq;
    analog_modulation_depth_input.on_value_changed = on_change_analog_modulation_depth;
    analog_modulation_offset_input.on_value_changed = on_change_analog_modulation_offset;

    // Digital Modulation事件绑定
    digital_modulation_menu.on_enter = on_enter_digital_modulation_menu;
    digital_modulation_menu.on_exit = on_exit_digital_modulation_menu;
    digital_modulation_checkbox.on_value_changed = on_change_digital_modulation_enabled;
    digital_modulation_type_choose.on_value_changed = on_change_digital_modulation_type;
    digital_modulation_carry_freq_input.on_value_changed = on_change_digital_modulation_carry_freq;
    digital_modulation_bitrate_input.on_value_changed = on_change_digital_modulation_bitrate;
    digital_modulation_data_input.on_value_changed = on_change_digital_modulation_data;
}
