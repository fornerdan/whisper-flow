#include "whisper_bridge.h"

#ifdef __has_include
#if __has_include("whisper.h")
#include "whisper.h"

const char * whisper_bridge_system_info(void) {
    return whisper_print_system_info();
}

struct whisper_full_params whisper_bridge_default_params(void) {
    return whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
}

#else

// Stub implementations when whisper.h is not available (e.g., during initial setup)
const char * whisper_bridge_system_info(void) {
    return "whisper.cpp not linked - xcframework not found";
}

#endif
#endif
