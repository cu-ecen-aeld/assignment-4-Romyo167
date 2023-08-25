#include <syslog.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char *argv[])
{   
    openlog(NULL, 0, LOG_USER);

    if(argc != 3)
    {
        syslog(LOG_ERR, "Invalid Number of arguments: %d", argc);
        return 1;
    }
    FILE* msgfile = fopen(argv[1], "w");
    if(msgfile == NULL)
    {
       syslog(LOG_ERR, "couldn't open file for writing: %s", argv[1]);
       return 1; 
    }
    syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]); 
    fputs(argv[2], msgfile);
    return 0;
}