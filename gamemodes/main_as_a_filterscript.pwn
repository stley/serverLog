#include <open.mp>


#include <serverLog>


forward sL_PushLog();
public sL_PushLog(){
    serverLogPush();
}

forward logtest();
public logtest(){
    serverLogRegister("Hello, from main!", "main2");
    serverLogRegister("Hello again, from main!", "main");
    if(random(5) == random(5)) serverLogSend("Hello from main, but this is urgent, so I force pushed the buffer!", "urgent");
}


public OnGameModeInit(){

    return 1;
}

public OnGameModeExit(){

    return 1;
}

main(){
    SetTimer("logtest", 1000, true);
    
    SetTimer("sL_PushLog", 5000, true);
}

#pragma option -d3