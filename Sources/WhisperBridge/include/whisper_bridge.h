#ifndef WHISPER_BRIDGE_H
#define WHISPER_BRIDGE_H

// whisper.cpp public API
// The actual whisper.h comes from the xcframework.
// This bridge header provides Swift-friendly wrappers if needed.

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

// Forward declarations matching whisper.h types
typedef struct whisper_context whisper_context;
typedef struct whisper_state whisper_state;

// Re-export key whisper.h types for Swift consumption.
// When the xcframework is present, whisper.h is included via Header Search Paths.
// This header serves as the module's umbrella header.

#ifdef __has_include
#if __has_include("whisper.h")
#include "whisper.h"
#endif
#endif

// Helper: Get system info string (thin wrapper for verification)
const char * whisper_bridge_system_info(void);

// Helper: Create default full params for greedy strategy
struct whisper_full_params whisper_bridge_default_params(void);

#endif // WHISPER_BRIDGE_H
