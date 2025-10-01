
#if defined __serverLog_included
    #endinput
#endif
#define __serverLog_included


#if defined __serverLog_as_a_module
    #error "Do not include <serverLog>, as it collapses with serverLog module definitions!"
#endif

serverLogRegister(const info[], const module[] = "serverLog"){
    if(funcidx("sL_Register"))
        CallRemoteFunction("sL_Register", "ss", info, module);
    else printf("sL_Register not found");
}
