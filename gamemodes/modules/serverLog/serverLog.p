
#if !defined _PawnPlus_included
    #include <PawnPlus>
#endif
#if !defined _requests_included
    #include <requests>
#endif

#if defined __serverLog_as_a_module
    #endinput
#endif
#define __serverLog_as_a_module

#if defined __serverLog_included
    #error "Do not include <serverLog>, as it collapses with serverLog module definitions!"
#endif


native Node:JsonString_s(ConstAmxString:value) = JsonString; //PawnPlus implementation of pawn-requests native, supporting PP strings.

forward discordInit();
forward discordExit();
forward serverLogInit();
forward serverLogExit();
forward sL_discordSendMessage(ConstStringTag:message);
forward sL_discordOnSendMessage(Requests:id, E_HTTP_STATUS:status, Node:node);
forward sL_Register(const info[], const module[]);
#define DISCORD_RETRY_MS    300000 //The time in miliseconds the plugin waits before trying to reconnect to the webhook.

stock serverLogRegister(const info[], const module[] = "undefined") return sL_Register(info, module);


new
    String:sL_Buffer,
    sL_BufferLines,
    RequestsClient:sL_client,
    webhook_url[256],
    bool:isRClientOnline = true,
    RetryTimer
;


webhookLinux(url[]){
    //forcefully fix CRLF on webhook.ini file (for Linux servers)
    while (strlen(url) > 0)
    {
        new last = url[strlen(url) - 1];
        if (last == '\r' || last == '\n' || last == ' ')
            url[strlen(url) - 1] = '\0';
        else
            break;
    }
    return 1;
}


discordTimeOut(){
    if(IsValidTimer(RetryTimer)) return 1;
    else SetTimer("discordInit", DISCORD_RETRY_MS, false);
    return 1;    
}

public discordInit(){
    new File:filehandle = fopen("webhook.ini", io_read);
    if(filehandle){
        fread(filehandle, webhook_url);
        fclose(filehandle);
    }
    else{
        printf("\"webhook.ini\" not found on scriptfiles folder!");
        print("Could not connect to Discord webhook. Will retry in 5 minutes.");
        isRClientOnline = false;
        discordTimeOut();
        return 1;
    }
    webhookLinux(webhook_url);
    sL_client = RequestsClient(webhook_url);
    new
        hour, minute, second,
        day, month, year
    ;
    getdate(year, month, day);
    gettime(hour, minute, second);
    if(!IsValidRequestsClient(sL_client)){
        print("Could not connect to Discord webhook. Will retry in 5 minutes.");
        isRClientOnline = false;
        discordTimeOut();
    }
    else{
        isRClientOnline = true;
        sL_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - Connected to Discord webhook.", day, month, year, hour, minute, second));
        sL_Buffer = str_new("");
        str_acquire(sL_Buffer);
    }
    return 1;
}

public discordExit(){
    new
        hour, minute, second,
        day, month, year
    ;
    getdate(year, month, day);
    gettime(hour, minute, second);
    sL_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - Shutting down server...", day, month, year, hour, minute, second));
    return 1;
}

stock sL_discordSendMessage(ConstStringTag:message){
    if(!isRClientOnline) return 1;
    if(IsValidRequestsClient(sL_client))
    RequestJSON(sL_client,
        "",
        HTTP_METHOD_POST,
        "sL_discordOnSendMessage",
        JsonObject("content", JsonString_s(message))
    );
    return 1;
}

public sL_discordOnSendMessage(Requests:id, E_HTTP_STATUS:status, Node:node){
    if(status == HTTP_STATUS_NO_CONTENT)
        return 1;
    else{
        isRClientOnline = false;
        sL_Register("Could not send the message to the Discord webhook. Retrying connection in 5 minutes.", "sL-Discord");
        discordTimeOut();
    }
    return 1;
}


public serverLogInit(){
    new
        hour, minute, second,
        day, month, year
    ;
    getdate(year, month, day);
    gettime(hour, minute, second);
    sL_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - ***stley/serverLog*** started!", day, month, year, hour, minute, second));
    print("stley/serverLog started.");
    return 1;
}
public serverLogExit(){
    if(str_valid(sL_Buffer)){
        if(str_len(sL_Buffer) && isRClientOnline){
            sL_discordSendMessage(sL_Buffer);
        }
        str_release(sL_Buffer);
    }
    delay(500);
    if(isRClientOnline){
        new
        hour, minute, second,
        day, month, year
        ;
        getdate(year, month, day);
        gettime(hour, minute, second);
        sL_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - ***stley/serverLog*** stopping...", day, month, year, hour, minute, second));
    }
    print("stley/serverLog stopping.");
    return 1;
}


sL_Register(const info[], const module[])
{
    if(!isRClientOnline) return printf("[%s] - %s", module, info);
    if(!str_valid(sL_Buffer)){
        sL_Buffer = str_new("");
        str_acquire(sL_Buffer);
    }
    const MAX_LINES = 20;

    new hour, minute, second;
    new day, month, year;
    getdate(year, month, day);
    gettime(hour, minute, second);
    

    new String:logline = str_cat(
        str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - [***%s***] ", day, month, year, hour, minute, second, module),
        str_new(info)
    );
    if (sL_BufferLines >= MAX_LINES || (str_len(sL_Buffer)+str_len(logline)) > 1900)
    {
        sL_discordSendMessage(sL_Buffer);
        str_clear(sL_Buffer);
        sL_BufferLines = 0;
    }
    if (sL_BufferLines > 0) str_append_format(sL_Buffer, "\n");
    str_append(sL_Buffer, str_convert(logline, "ansi", "utf8"));
    sL_BufferLines++;
    printf("[%s] - %s", module, info);
    return 1;
}

