#include "../kernel/types.h"
#include "../kernel/syscall.h"
#include "user.h"

int main(int argc, char **argv) {
    // Ensure correct usage: setpriority priority pid
    if (argc != 3) {
        printf("Usage : setpriority priority pid\n");
        exit(1);
    }

    // Extract arguments: priority and pid
    int new_priority = atoi(argv[1]);
    int pid = atoi(argv[2]);
    
    // Call set_priority syscall
    set_priority(new_priority, pid);
    
    // Terminate successfully
    exit(0);
}