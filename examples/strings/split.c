#include <stdio.h>
#include <string.h>


struct flying_object {
	char type[16];
	float x;
	float y;
	float heading;
	float speed;
};

void parse_input(char *input, struct flying_object *fo) {
	// airplane:100,200;300;400 (correct format assumed)

	// parse airplane type and copy (via snprintf) into .type field
	char *itype = strtok(input, ":");
	snprintf(fo->type, sizeof fo->type, "%s", itype);

	// parse x
	char *ival = strtok(NULL, ",");
	fo->x = atof(ival);

	// parse y
	ival = strtok(NULL, ";");
	fo->y = atof(ival);

	// parse heading
	ival = strtok(NULL, ";");
	fo->heading = atof(ival);

	// parse speed (last token)
	ival = strtok(NULL, "\0");
	fo->speed = atof(ival);
}


int main() {
	struct flying_object fo1;

	parse_input("duck:50,75;180;314", &fo1);

	printf("I see a '%s' at (%f, %f), heading %f degrees at %f furlongs per fortnight!\n", fo1.type, fo1.x, fo1.y, fo1.heading, fo1.speed);

	return 0;
}
