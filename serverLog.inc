#if defined __serverLog_included
    #endinput
#endif
#define __serverLog_included


serverLogRegister(const info[], const module[] = "undefined"){
    if(funcidx("sL_Register"))
        CallRemoteFunction("sL_Register", "ss", info, module);
    else printf("sL_Register not found");
}
