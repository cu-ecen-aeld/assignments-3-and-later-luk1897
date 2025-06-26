#include <stdio.h>
#include <syslog.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char *argv[]){
    
    openlog(NULL, 0, LOG_USER);

    if(argc != 3){
        fprintf(stderr, "Invalid number of arguments %d\n", argc - 1);
        syslog(LOG_ERR, "Invalid number of arguments %d\n", argc - 1);
        closelog();
        exit(1);
    }

    FILE* f;

    f = fopen(argv[1], "w");
    if(f == NULL){
       fprintf(stderr, "Open file error: %s", strerror(errno));
       syslog(LOG_ERR, "Open file error\n");
       closelog();
       exit(1);
    }
    
    size_t res = fwrite(argv[2], sizeof(char), strlen(argv[2]), f);
    if(res != strlen(argv[2])){
        fprintf(stderr, "Writing file error: %s", strerror(errno));
        syslog(LOG_ERR, "Writing file error\n");
        closelog();
        fclose(f);
        exit(1);
    }
    else{
        printf("Writing %s to %s\n", argv[2], argv[1]);
        syslog(LOG_DEBUG, "Writing %s to %s\n", argv[2], argv[1]);
    }
    
    fclose(f);

    syslog(LOG_DEBUG, "Process terminated with success");

    closelog();

    return 0;

}