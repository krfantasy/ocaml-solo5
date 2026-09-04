#ifndef _SYS_TIMES_H
#define _SYS_TIMES_H

/*
 * times() reports elapsed time in CLK_TCK ticks per second. We use
 * nanoseconds (matching solo5_clock_monotonic()), which keeps the full
 * 64-bit precision of the Solo5 clocks. Defining CLK_TCK here also
 * bypasses the OCaml runtime's fallback of 60 in runtime/sys.c, so that
 * Sys.time converts ticks with the correct scale.
 */
#define CLK_TCK 1000000000L

#ifndef _NOLIBC_CLOCK_T
#define _NOLIBC_CLOCK_T
typedef long clock_t; /* keep in sync with sys/time.h */
#endif
struct tms {
    clock_t tms_utime;
    clock_t tms_stime;
    clock_t tms_cutime;
    clock_t tms_cstime;
};
clock_t times(struct tms *buf);

#endif
