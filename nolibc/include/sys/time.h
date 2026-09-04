#ifndef _SYS_TIME_H
#define _SYS_TIME_H

typedef long time_t;
#ifndef _NOLIBC_CLOCK_T
#define _NOLIBC_CLOCK_T
typedef long clock_t; /* keep in sync with sys/times.h */
#endif
/* NOTE: CLOCKS_PER_SEC (microseconds, glibc convention) and CLK_TCK in
 * <sys/times.h> (nanoseconds) intentionally differ: clock() is currently a
 * stub returning 0 so its scale is dead, while the live HAS_TIMES path in
 * the OCaml runtime divides times() ticks by CLK_TCK. A future real clock()
 * implementation must pick its scale deliberately. */
#define CLOCKS_PER_SEC 1000000L
typedef long suseconds_t;
struct timeval {
    time_t tv_sec;
    suseconds_t tv_usec;
};
struct timezone {
    int tz_minuteswest;
    int tz_dsttime;
};
int gettimeofday(struct timeval *tv, struct timezone *tz);
clock_t clock(void);
time_t time(time_t *);
struct timespec {
    time_t tv_sec;
    long tv_nsec;
};

#endif
