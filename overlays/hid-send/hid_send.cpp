#include <linux/hidraw.h>
#include <sys/ioctl.h>
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
    char *hex_token;
    char *rest = strdup(hex_data_str);
    char *hex_str_copy = rest;

    while ((hex_token = strtok_r(rest, ":", &rest)) != NULL && buf_len < sizeof(buf)) {
        buf[buf_len++] = (unsigned char)strtol(hex_token, NULL, 16);
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
    } else {
        printf("Success! Sent %d bytes to %s\n", buf_len, device_path);
    }

    close(fd);
    return 0;
}
