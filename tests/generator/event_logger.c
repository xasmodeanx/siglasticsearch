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

	// If modem becomes Unconfigured, clear the serial
	//if(g_state[group][modem] == 0) { g_serial[group][modem] = 0; }

	// If modem becomes offline, fabricate a serial if it doesn't have one
	if(g_state[group][modem] == 1) {
		if(g_serial[group][modem] == 0) {
			//Fabricate a random serial
			while(g_serial[group][modem] <= 0) { g_serial[group][modem] = rand(); }
		}
	}
}

static void add_modem_info(cJSON *root, int group, int modem)
{
	char *status_str = NULL;
	switch(g_state[group][modem]) {
		case 0: status_str = "unconfigured"; break;
		case 1: status_str = "offline"; break;
		case 2: status_str = "ranging"; break;
		case 3: status_str = "online"; break;
		//default: status_str = "unknown";
	}

	char temp[64];
	snprintf(temp, sizeof(temp), "%d/%d", group, modem);
	cJSON_AddStringToObject(root, "UID", temp);
	snprintf(temp, sizeof(temp), "%d", group);
	cJSON_AddStringToObject(root, "groupNumber", temp);
	snprintf(temp, sizeof(temp), "%d", modem);
	cJSON_AddStringToObject(root, "modemNumber", temp);

	if(status_str) {
		cJSON_AddStringToObject(root, "operatingMode", status_str);
	}

	int serial = g_serial[group][modem];
	if(serial > 0) {
		snprintf(temp, sizeof(temp), "%d", serial);
		cJSON_AddStringToObject(root, "serialNumber", temp);
	}
}

static void add_network_info(cJSON *root)
{
	char *network = getenv("NETWORK");
	if(network) {
		cJSON_AddStringToObject(root, "networkName", network);
	}
}

/*
date --date='Jan 1 00:00:00 MST 2023' "+%s" = 672556400
date --date='Feb 1 00:00:00 MST 2023' "+%s" = 1675234800
date --date='Mar 1 00:00:00 MST 2023' "+%s" = 1677654000
*/
struct timespec g_ts = {0,0};
static void add_time(cJSON *root)
{
	char timestamp[64];
	//clock_gettime(CLOCK_REALTIME, &ts);
	g_ts.tv_sec += (rand() % 300);
	sprintf(timestamp, "%ld.%09ld", g_ts.tv_sec, g_ts.tv_nsec);
	cJSON_AddStringToObject(root, "modeUpdateTime", timestamp);
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

	if(argc != 3) {
		fprintf(stderr, "%s: <startTime> <endTime>\n", argv[0]);
		exit(1);
	}

	initialize();

	//useconds_t delay;
	//long numevents = 1000;
	//if(argc == 2) { numevents = atol(argv[1]); }
	//while(numevents-- > 0) {

	g_ts.tv_sec = atol(argv[1]);
	while(g_ts.tv_sec < atol(argv[2])) {
		//Fabricate a random group and modem
		group = RANDGRP; modem = RANDMID;
		update_state(group, modem);
		log_event(group, modem);
		//delay = (rand() % 1000);
		//usleep(delay);
	}

	return 0;
}
