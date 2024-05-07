#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"


#define NUM_PROCESSES 10
#define IO_BOUND_PROCESSES 5

int main() {
    int process_index, pid;
    int wait_time, run_time;
    int total_wait_time = 0, total_run_time = 0;

    // Spawn child processes
    for (process_index = 0; process_index < NUM_PROCESSES; process_index++) {
        pid = fork();
        if (pid < 0)
            break;
        if (pid == 0) {
#ifndef FCFS
            if (process_index < IO_BOUND_PROCESSES) {
                // IO-bound processes
                sleep(200);
            } else {
#endif
                // CPU-bound process
                for (volatile int i = 0; i < 1000000000; i++) {}
#ifndef FCFS
            }
#endif
            printf("\nProcess %d has finished", process_index);
            exit(0);
        } else {
#ifdef PBS
            // Adjust priority for PBS
            set_priority(60 - IO_BOUND_PROCESSES + process_index, pid);
#endif
        }
    }

    // Wait for child processes to finish
    for (; process_index > 0; process_index--) {
        if (waitx(0, &wait_time, &run_time) >= 0) {
            // Update total waiting and running time
            total_run_time += run_time;
            total_wait_time += wait_time;
        }
    }

    // Calculate and print average running and waiting time
    printf("\nAverage running time: %d, average waiting time: %d\n", total_run_time / NUM_PROCESSES, total_wait_time / NUM_PROCESSES);

    exit(0);
}
