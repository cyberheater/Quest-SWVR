// sys_log.h - shim for the vendored cpu_m6809 core (AAE), which logs through
// AAE's LOG_INFO.  Here every message goes to one function the board supplies:
// the core only logs faults (an illegal store-immediate, an unhandled access),
// and the oracle counts any message as a failed run.
#pragma once

#ifdef __cplusplus
extern "C" {
#endif
void sw_cpu_log(const char* fmt, ...);
#ifdef __cplusplus
}
#endif

#define LOG_DEBUG(fmt, ...) sw_cpu_log(fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...)  sw_cpu_log(fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) sw_cpu_log(fmt, ##__VA_ARGS__)
