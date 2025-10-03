/*
serverLog by stley (https://github.com/stley)

Filterscript wrapper include
ONLY USE WHEN USING FILTERSCRIPT VERSION OF THE LIBRARY!
*/
#if defined __serverLog_included
    #endinput
#endif
#define __serverLog_included


#if defined __serverLog_as_a_module
    #error "Do not include <serverLog>, as it collapses with serverLog module definitions!"
#endif


stock serverLogRegister(const info[], const module[] = "serverLog"){
    if(!CallRemoteFunction("sLFS_Register", "ss", info, module))
        printf("[serverLog internal] sLFS_Register not found - is serverLog side script loaded?");
    return 1;
}

stock serverLogPush(){
    if(!CallRemoteFunction("sLFS_Push"))
        printf("[serverLog internal] sLFS_Push not found - is serverLog side script loaded?");
    return 1;
}

stock serverLogSend(const info[], const module[] = "serverLog"){
    
    if(!CallRemoteFunction("sLFS_Send", "ss", info, module))
        printf("[serverLog internal] sLFS_Send not found - is serverLog side script loaded?");
    return 1;
}