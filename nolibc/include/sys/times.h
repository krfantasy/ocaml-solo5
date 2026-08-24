#ifndef _SYS_TIMES_H
#define _SYS_TIMES_H

#ifndef _NOLIBC_CLOCK_T
#define _NOLIBC_CLOCK_T
typedef int clock_t;
#endif
struct tms {
    clock_t tms_utime;
    clock_t tms_stime;
    clock_t tms_cutime;
    clock_t tms_cstime;
};
clock_t times(struct tms *buf);

#endif
