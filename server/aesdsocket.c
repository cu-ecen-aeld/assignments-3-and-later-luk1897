#include <stdio.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <syslog.h>
#include <fcntl.h>
#include <unistd.h>
#include <arpa/inet.h> 
#include <stdlib.h>

#define IP "127.0.0.1"
#define PORT 9000
#define BUFFERSIZE 2500000

int serverfd, clientfd, fd;
char *file = "/var/tmp/aesdsocketdata";

void sa_function(int sig){

    if(sig == SIGTERM || sig == SIGINT){
        close(fd);
        remove(file);
        syslog(LOG_USER, "Caught signal, exiting");
        closelog();
        close(clientfd);
        close(serverfd);
        exit(0);
    }
}

int main(int argc, char *argv[]){

    
    int bytes;
    pid_t pid=-12;
    struct sockaddr_in server_addr, client_addr;
    struct sigaction sa;

    memset(&sa,0,sizeof(sa));
    sa.sa_handler=&sa_function;
    sigaction(SIGTERM,&sa,NULL);
    sigaction(SIGINT,&sa,NULL);

    openlog("aesdsocket", LOG_PID | LOG_CONS, LOG_USER);


    serverfd = socket(PF_INET, SOCK_STREAM, 0);
    if(serverfd == -1){
        fprintf(stderr, "Error with socket func: %s\n", strerror(errno));
        exit(1);
    }

    int optval = 1;
    if (setsockopt(serverfd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) == -1) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }

    bzero((char*)&server_addr, sizeof(server_addr));
    
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = inet_addr(IP);


    if(bind(serverfd, (struct sockaddr*) &server_addr, sizeof(server_addr)) == -1){
        fprintf(stderr, "Error with bind func: %s\n", strerror(errno));
        exit(1);
    }

    
    
    if(argc >= 2 && argv[1] != NULL) {
        if (strcmp(argv[1], "-d") == 0) {
        pid = fork();

        if(pid == -1){
            fprintf(stderr, "Error with fork: %s\n", strerror(errno));
            exit(1);
        }
        if(pid > 0) exit(0);
        else if(pid == 0){

            if (setsid() < 0) {
                perror("setsid");
                exit(1);
            }

            chdir("/");
            freopen("/dev/null", "r", stdin);
            freopen("/dev/null", "w", stdout);
            freopen("/dev/null", "w", stderr);
        }
    }
}
    if(listen(serverfd, 5) == -1){
        fprintf(stderr, "Error with listen func: %s\n", strerror(errno));
        exit(1);
    }

    fd = open(file, O_CREAT | O_APPEND | O_RDWR, 0766);
        if (fd == -1){
            fprintf(stderr, "Error with file: %s\n", strerror(errno));
            close(clientfd);
            close(serverfd);
            exit(1);
        }
        else printf("file created\n");

    while(1){

        char *buffer;
        char *n;


        int client_size = sizeof(client_addr);

        clientfd = accept(serverfd, (struct sockaddr*) &client_addr, (socklen_t*) &client_size);

        if(clientfd == -1){
            fprintf(stderr, "Error with accept func: %s\n", strerror(errno));
            close(clientfd);
            close(serverfd);
            exit(1);
        }

        char client_ip[16];
        inet_ntop(AF_INET, &(client_addr.sin_addr), client_ip, 16);

        syslog(LOG_INFO, "Accepted connection from %s\n", client_ip);
        printf("Accepted connection from %s\n", client_ip);

        //memset(buffer, 0, sizeof(buffer));

        buffer = (char *) malloc(sizeof(char)*BUFFERSIZE);
        
        bytes = read(clientfd, buffer, sizeof(char)*BUFFERSIZE);
        
        if(bytes==-1){
            fprintf(stderr, "Error with recv: %s\n", strerror(errno));
            close(clientfd);
            close(serverfd);
            exit(1);
        }


        for(int i = 0; i < bytes; i++){
            if(write(fd, &buffer[i], 1) == -1){
                fprintf(stderr, "Error with write: %s\n", strerror(errno));
                close(clientfd);
                close(serverfd);
                exit(1);
            }
            if(buffer[i] == '\n') break;
        }

        //memset(buffer, 0, sizeof(buffer));
        lseek(fd, 0, SEEK_SET);

        n = (char *) malloc(sizeof(char)*BUFFERSIZE);

        bytes = read(fd, n, sizeof(char)*BUFFERSIZE);
        
        if(bytes == -1){
            fprintf(stderr, "Error with read: %s\n", strerror(errno));
            close(clientfd);
            close(serverfd);
            exit(1);
        }
        
        for(int i = 0; i < bytes; i++){
        if(write(clientfd, &n[i], 1) == -1){
            fprintf(stderr, "Error with send: %s\n", strerror(errno));
            close(clientfd);
            close(serverfd);
            exit(1);
        }
    }

        //write(fd, n, bytes);

        printf("ok");
    
        syslog(LOG_INFO, "Closed connection from %s\n", client_ip);
        printf("Closed connection from %s\n", client_ip);

        free(buffer);
        free(n);
        
        close(clientfd);
        
        
        
    }
    
    close(fd);

    close(serverfd);

    closelog();

    

return 0;

}
