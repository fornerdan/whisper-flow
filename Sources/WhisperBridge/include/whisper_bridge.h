#ifndef WHISPER_BRIDGE_H
#define WHISPER_BRIDGE_H

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

// Include whisper.cpp public API directly
#include "whisper.h"

// Helper: Get system info string (thin wrapper for verification)
const char * whisper_bridge_system_info(void);

// Helper: Create default full params for greedy strategy
struct whisper_full_params whisper_bridge_default_params(void);

#endif // WHISPER_BRIDGE_H
