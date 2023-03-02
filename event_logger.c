#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#include "cJSON.h"

#define MAXGRP (256)
#define MAXMID (16384)

#define RANDGRP ((rand() % 9) + 1)
#define RANDMID ((rand() % 99) + 1)

int g_state[MAXGRP][MAXMID];
int g_serial[MAXGRP][MAXMID];

static void print_object(cJSON *root)
{
	char *minjson = cJSON_Print(root);
	cJSON_Minify(minjson);
	printf("%s\n", minjson);
	free(minjson);
}

/* Valid States
0 - Unconfigured
1 - Offline
2 - Ranging
3 - Online
*/
static void update_state(int group, int modem)
{
	g_state[group][modem]++;
	if(g_state[group][modem] > 3) { g_state[group][modem] = 0; }

	// If modem goes to Unconfigured, clear the serial
	if(g_state[group][modem] == 0) { g_serial[group][modem] = 0; }

	if(g_state[group][modem] == 1) {
		if(g_serial[group][modem] == 0) {
			//Fabricate a random serial
			while(g_serial[group][modem] <= 0) { g_serial[group][modem] = rand(); }
		}
	}
}

static void add_modem_info(cJSON *root, int group, int modem)
{
	int serial;
	char uid_str[64];
	char *status_str = NULL;
	switch(g_state[group][modem]) {
		case 0: status_str = "unconfigured"; break;
		case 1: status_str = "offline"; break;
		case 2: status_str = "ranging"; break;
		case 3: status_str = "online"; break;
		//default: status_str = "unknown";
	}

	snprintf(uid_str, sizeof(uid_str), "%d/%d", group, modem);
	cJSON_AddStringToObject(root, "UID", uid_str);
	cJSON_AddNumberToObject(root, "Group", group);
	cJSON_AddNumberToObject(root, "Modem", modem);

	if(status_str) {
		cJSON_AddStringToObject(root, "Status", status_str);
	}

	serial = g_serial[group][modem];
	if(serial > 0) {
		cJSON_AddNumberToObject(root, "Serial", serial);
	}
}

static void add_network_info(cJSON *root)
{
	char *network = getenv("NETWORK");
	if(network) {
		cJSON_AddStringToObject(root, "Network", network);
	}
}

static void add_time(cJSON *root)
{
	struct timespec ts;
	char timestamp[64];
	clock_gettime(CLOCK_REALTIME, &ts);
	sprintf(timestamp, "%ld.%09ld", ts.tv_sec, ts.tv_nsec);
	cJSON_AddStringToObject(root, "Time", timestamp);
}

static void log_event(int group, int modem)
{
	cJSON *root = cJSON_CreateObject();

	add_time(root);
	add_network_info(root);
	add_modem_info(root, group, modem);

	print_object(root);
	cJSON_Delete(root);
}

static void initialize(void)
{
	srand(time(NULL));
	memset(g_state, 0, sizeof(g_state));
	memset(g_serial, 0, sizeof(g_serial));

/*
	int g,m;
	for(g=0; g<RANDGRP; g++) {
		for(m=0; m<MAXMID; m++) {
			// Init half of modems to online
			if(rand() % 2) { g_state[g][m] = 3; }
		}
	}
*/
}

int main(int argc, char *argv[])
{
	int group, modem;
	useconds_t delay;

	initialize();

	long numevents = 1000;
	if(argc == 2) { numevents = atol(argv[1]); }

	while(numevents-- > 0) {
		//Fabricate a random group and modem
		group = RANDGRP; modem = RANDMID;
		update_state(group, modem);
		log_event(group, modem);
		delay = (rand() % 1000);
		usleep(delay);
	}

	return 0;
}
