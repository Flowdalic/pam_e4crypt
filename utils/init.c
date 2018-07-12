/*
 * Minimal and specialized init for running tests directly in a VM.
 *
 * Rather than running `/etc/rc` and running forever, it runs `/etc/test` and
 * causes the system to halt as soon as that process exits.
 *
 * Based on an init by by rich felker, downloaded from
 * https://gist.githubusercontent.com/rofl0r/6168719/raw/183525e0f0007169a49392b21ceee5b507e3aee8/init.c
 */
#include <signal.h>
#include <unistd.h>
#include <stdio.h>

#include <linux/reboot.h>
#include <sys/reboot.h>
#include <sys/wait.h>


int main() {
    sigset_t set;
    sigfillset(&set);

    sigprocmask(SIG_BLOCK, &set, 0);

    pid_t testpid = fork();
    if (testpid) {
        // We are in the parent process. Wait for the test to exit, getting rid
        // of zombies in the meantime.
        int status;
        while (wait(&status) != testpid);

        // Do something a sane init would never ever do: print the exit status
        if (WIFEXITED(status))
            fprintf(stderr, "Test exitted with exit code %d.\n", (int) WEXITSTATUS(status));
        else
            fprintf(stderr, "Test exitted abnormally.\n");

        // The test exitted. Time to shut down
        return reboot(LINUX_REBOOT_CMD_POWER_OFF);
    }

    sigprocmask(SIG_UNBLOCK, &set, 0);

    // We are in the child process. Run the test.
    setsid();
    setpgid(0, 0);
    return execv("/etc/test", (char *[]){ "test", 0 });
}
