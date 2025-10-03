#include <open.mp>


//#include <serverLog>
#include "modules/serverLog/serverLog.p"

forward sL_PushLog();
public sL_PushLog(){
    serverLogPush();
}

forward logtest();
public logtest(){
    serverLogRegister("Hello, from main!");
    serverLogRegister("Hello again, from main!", "main");
    if(random(5) == random(5)) serverLogSend("Hello from main, but this is urgent, so I force pushed the buffer!", "urgent");
}


public OnGameModeInit(){
    sLM_Init();
    return 1;
}

public OnGameModeExit(){
    sLM_Exit();
    return 1;
}

main(){
    SetTimer("logtest", 1000, true);
    
    SetTimer("sL_PushLog", 5000, true);
}

#pragma option -d3