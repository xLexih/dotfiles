#include <linux/hidraw.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <cstdlib>

#ifndef HIDIOCSFEATURE
#define HIDIOCSFEATURE(len) _IOC(_IOC_WRITE|_IOC_READ, 'H', 0x06, len)
#endif

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <device_path> <hex_data>\n", argv[0]);
        fprintf(stderr, "%s /dev/hidraw2 00:01:ff:ff:ff:ff:00:00:00:00:00:00:00:00:00:00:00\n", argv[0]);
        fprintf(stderr, "%s /dev/hidraw2 00:01:ff:ff:ff:ff\n", argv[0]);
        fprintf(stderr, "%s /dev/hidraw2 01:ff:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00\n", argv[0]);
        fprintf(stderr, "%s /dev/hidraw2 01:ff\n", argv[0]);
        return 1;
    }

    const char *device_path = argv[1];
    const char *hex_data_str = argv[2];

    int fd = open(device_path, O_RDWR);
    if (fd < 0) {
        perror("Unable to open device");
        return 1;
    }

    unsigned char buf[256];
    int buf_len = 0;
    char *hex_str_copy = strdup(hex_data_str);
    if (hex_str_copy == NULL) {
        perror("strdup");
        close(fd);
        return 1;
    }

    char *saveptr = NULL;
    for (char *hex_token = strtok_r(hex_str_copy, ":", &saveptr);
         hex_token != NULL;
         hex_token = strtok_r(NULL, ":", &saveptr)) {
        if (buf_len >= (int)sizeof(buf)) {
            fprintf(stderr, "Error: hex data is too long, max is %zu bytes.\n", sizeof(buf));
            free(hex_str_copy);
            close(fd);
            return 1;
        }

        char *end = NULL;
        errno = 0;
        long value = strtol(hex_token, &end, 16);
        if (errno != 0 || end == hex_token || *end != '\0' || value < 0 || value > 0xff) {
            fprintf(stderr, "Error: invalid byte '%s'. Expected hex value from 00 to ff.\n", hex_token);
            free(hex_str_copy);
            close(fd);
            return 1;
        }

        buf[buf_len++] = (unsigned char)value;
    }
    free(hex_str_copy);

    if (buf_len == 0) {
        fprintf(stderr, "Error: No data parsed from hex string.\n");
        close(fd);
        return 1;
    }

    int res = ioctl(fd, HIDIOCSFEATURE(buf_len), buf);
    if (res < 0) {
        perror("ioctl HIDIOCSFEATURE");
        close(fd);
        return 1;
    } else {
        printf("Success! Sent %d bytes to %s\n", buf_len, device_path);
    }

    close(fd);
    return 0;
}
