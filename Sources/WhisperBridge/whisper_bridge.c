#include "whisper_bridge.h"

const char * whisper_bridge_system_info(void) {
    return whisper_print_system_info();
}

struct whisper_full_params whisper_bridge_default_params(void) {
    return whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
}
