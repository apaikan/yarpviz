#include <iostream>
#include <string>
#include <yarp/os/Network.h>
#include <yarp/os/BufferedPort.h>
#include <yarp/os/Bottle.h>


using namespace std;
using namespace yarp::os;

int main(int argc, char *argv[]) {
    Network yarp;

	struct sched_param sch_param;
	sch_param.__sched_priority = sched_get_priority_max(SCHED_FIFO) / 4;
	if( sched_setscheduler(0, SCHED_FIFO, &sch_param) != 0 ) {
		cout<<"sched_setscheduler failed."<<endl;
		return 0;
	}

    cout<<"Current sched policy: '"<<sched_getscheduler(0)<<"' and priority: '"<<sch_param.__sched_priority<<"'\n";

    BufferedPort<Bottle> inPort;
    if(!inPort.open("/receiver"))
        return 0;
    
    if(!NetworkBase::connect("/coman/left_arm/state:o", 
                            inPort.getName(), "udp")) {
        cout<<"Cannot connect!"<<endl;
        return 0;
    }                            

    cout<<"Running...."<<endl;
    while (true) {
        Bottle* msg = inPort.read();
    }
    return 0;
}

