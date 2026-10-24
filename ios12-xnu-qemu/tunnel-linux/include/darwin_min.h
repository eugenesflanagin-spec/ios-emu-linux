/* Minimal Darwin/iOS (arm64) libc declarations, hand-written from the public
 * Darwin ABI so the Aleph tcp-tunnel can be cross-built on Linux with clang +
 * ld64.lld WITHOUT an Apple SDK. Only what tcp-tunnel needs. */
#ifndef DARWIN_MIN_H
#define DARWIN_MIN_H
#include <stdint.h>
#include <stddef.h>
#include <stdarg.h>
typedef long ssize_t;
typedef int pid_t;
typedef uint32_t socklen_t;
typedef uint8_t sa_family_t;
typedef uint16_t in_port_t;
typedef uint32_t in_addr_t;
typedef long time_t;
typedef struct __sFILE FILE;
extern FILE *__stdinp, *__stdoutp, *__stderrp;
#define stdin __stdinp
#define stdout __stdoutp
#define stderr __stderrp
int printf(const char *, ...);
int fprintf(FILE *, const char *, ...);
void exit(int) __attribute__((noreturn));
unsigned long strtoul(const char *, char **, int);
void *memset(void *, int, size_t);
void *memcpy(void *, const void *, size_t);
size_t strlen(const char *);
int strncmp(const char *, const char *, size_t);
char *strncpy(char *, const char *, size_t);
char *strtok(char *, const char *);
extern int *__error(void);
#define errno (*__error())
#define EINVAL 22
#define ENOMEM 12
#define EAGAIN 35
#define EWOULDBLOCK EAGAIN
#define ENOTSOCK 38
#define EBADF 9
/* unistd */
#define STDIN_FILENO 0
int close(int);
pid_t fork(void);
int usleep(unsigned int);
/* fcntl */
#define F_GETFL 3
#define F_SETFL 4
#define O_NONBLOCK 0x0004
int fcntl(int, int, ...);
/* signal */
#define SIGINT 2
#define SIGTERM 15
typedef uint32_t sigset_t;
struct sigaction {
    union { void (*__sa_handler)(int); void (*__sa_sigaction)(int, void *, void *); } __sigaction_u;
    sigset_t sa_mask;
    int sa_flags;
};
#define sa_handler __sigaction_u.__sa_handler
int sigaction(int, const struct sigaction *, struct sigaction *);
/* sockets (BSD layout: sa_len + 8-bit family) */
#define AF_INET 2
#define SOCK_STREAM 1
struct sockaddr { uint8_t sa_len; sa_family_t sa_family; char sa_data[14]; };
struct in_addr { in_addr_t s_addr; };
struct sockaddr_in { uint8_t sin_len; sa_family_t sin_family; in_port_t sin_port; struct in_addr sin_addr; char sin_zero[8]; };
#define INADDR_ANY ((in_addr_t)0)
#define htons(x) __builtin_bswap16((uint16_t)(x))
#define ntohs(x) __builtin_bswap16((uint16_t)(x))
int socket(int, int, int);
int accept(int, struct sockaddr *, socklen_t *);
int bind(int, const struct sockaddr *, socklen_t);
int connect(int, const struct sockaddr *, socklen_t);
int listen(int, int);
ssize_t recv(int, void *, size_t, int);
ssize_t send(int, const void *, size_t, int);
int inet_pton(int, const char *, void *);
#endif
