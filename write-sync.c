#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void main(int argc, char* argv[])
{
	char path[255] = "/home/vault19/no_JBD/hello.txt";
	char data[255] = "hello_world\n";

	if (argc >= 1 && argv[1])
		strcpy(path, argv[1]);
	if (argc >= 2 && argv[2])
		strcpy(data, argv[2]);

	/* printf("%s: path\n", path); */
	/* printf("%s: Data", data); */
	FILE *f = fopen(path,"w");

	if (f) {
		fprintf(f, "%s", data);
		fclose(f);
		sync();
	}
}

