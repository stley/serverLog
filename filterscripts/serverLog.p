#define FILTERSCRIPT
#include <open.mp>
#include <requests>
#include <PawnPlus>



new
    String:sLFS_Buffer,
    sLFS_BufferLines,
    RequestsClient:sLFS_client,
    slFS_webhook_url[256],
    bool:slFS_isRClientOnline = true,
    RetryTimer
;
#pragma dynamic 500
#pragma option -O2

native Node:JsonString_s(ConstAmxString:value) = JsonString; //PawnPlus implementation of pawn-requests native, supporting PP strings.

forward slFS_discordInit();
forward slFS_discordExit();
forward slFS_serverLogInit();
forward slFS_serverLogExit();
forward sLFS_discordSendMessage(ConstStringTag:message);
forward sLFS_discordOnSendMessage(Requests:id, E_HTTP_STATUS:status, Node:node);
forward sLFS_Register(const info[], const module[]);
forward sLFS_Push();
forward sLFS_Send(const info[], const module[]);

#define DISCORD_RETRY_MS    300000 //The time in miliseconds the plugin waits before trying to reconnect to the webhook.

webhookLinux(url[]){
    //forcefully fix CRLF on webhook.ini file
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

forward sLFS_Ping();
public sLFS_Ping(){
    return 1;
}

sLFS_discordTimeOut(){
    if(IsValidTimer(RetryTimer)) return 1;
    else SetTimer("slFS_discordInit", DISCORD_RETRY_MS, false);
    return 1;    
}


public slFS_discordInit(){
    new File:filehandle = fopen("webhook.ini", io_read);
    if(filehandle){
        fread(filehandle, slFS_webhook_url);
        fclose(filehandle);
    }
    else{
        printf("\"webhook.ini\" not found on scriptfiles folder!");
        print("Could not connect to Discord webhook. Will retry in 5 minutes.");
        slFS_isRClientOnline = false;
        sLFS_discordTimeOut();
        return 1;
    }
    webhookLinux(slFS_webhook_url);
    sLFS_client = RequestsClient(slFS_webhook_url);
    new
        hour, minute, second,
        day, month, year
    ;
    getdate(year, month, day);
    gettime(hour, minute, second);
    if(!IsValidRequestsClient(sLFS_client)){
        print("Could not connect to Discord webhook. Will retry in 5 minutes.");
        slFS_isRClientOnline = false;
        sLFS_discordTimeOut();
    }
    else{
        slFS_isRClientOnline = true;
        sLFS_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - Connected to Discord webhook.", day, month, year, hour, minute, second));
        sLFS_Buffer = str_new("");
        str_acquire(sLFS_Buffer);
    }
    return 1;
}

public slFS_discordExit(){
    new
        hour, minute, second,
        day, month, year
    ;
    getdate(year, month, day);
    gettime(hour, minute, second);
    sLFS_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - Shutting down server...", day, month, year, hour, minute, second));
    return 1;
}

sLFS_discordSendMessage(ConstStringTag:message){
    if(!slFS_isRClientOnline) return 1;
    if(IsValidRequestsClient(sLFS_client))
    RequestJSON(sLFS_client,
        "",
        HTTP_METHOD_POST,
        "sLFS_discordOnSendMessage",
        JsonObject("content", JsonString_s(message))
    );
    return 1;
}

public sLFS_discordOnSendMessage(Requests:id, E_HTTP_STATUS:status, Node:node){
    if(status == HTTP_STATUS_NO_CONTENT)
        return 1;
    else{
        slFS_isRClientOnline = false;
        sLFS_Register("Could not send the message to the Discord webhook. Retrying connection in 5 minutes.", "sL-Discord");
        sLFS_discordTimeOut();
    }
    return 1;
}



slFS_serverLogInit(){
    new
        hour, minute, second,
        day, month, year
    ;
    getdate(year, month, day);
    gettime(hour, minute, second);
    sLFS_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - ***stley/serverLog*** side script started!", day, month, year, hour, minute, second));
    print("stley/serverLog side script started.");
    return 1;
}
slFS_serverLogExit(){
    if(str_valid(sLFS_Buffer)){
        if(str_len(sLFS_Buffer) && slFS_isRClientOnline){
            sLFS_discordSendMessage(sLFS_Buffer);
        }
        str_release(sLFS_Buffer);
    }
    delay(500);
    if(slFS_isRClientOnline){
        new
        hour, minute, second,
        day, month, year
        ;
        getdate(year, month, day);
        gettime(hour, minute, second);
        sLFS_discordSendMessage(str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - ***stley/serverLog*** side script stopping...", day, month, year, hour, minute, second));
    }
    print("stley/serverLog side script stopping.");
    return 1;
}


public sLFS_Register(const info[], const module[])
{
    if(!slFS_isRClientOnline) return printf("[%s] - %s", module, info);
    if(!str_valid(sLFS_Buffer)){
        sLFS_Buffer = str_new("");
        str_acquire(sLFS_Buffer);
    }
    const MAX_LINES = 20;

    new hour, minute, second;
    new day, month, year;
    getdate(year, month, day);
    gettime(hour, minute, second);
    
    #if defined serverLog_NO_MODULES
        new String:logline = str_cat(
            str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - ", day, month, year, hour, minute, second),
            str_new(info)
        );  
    #else  
        new String:logline = str_cat(
            str_format("**[%02d/%02d/%04d %02d:%02d:%02d]** - [***%s***] ", day, month, year, hour, minute, second, module),
            str_new(info)
        );
    #endif
    if (sLFS_BufferLines >= MAX_LINES || (str_len(sLFS_Buffer)+str_len(logline)) > 1900)
    {
        sLFS_discordSendMessage(sLFS_Buffer);
        str_clear(sLFS_Buffer);
        sLFS_BufferLines = 0;
    }
    if (sLFS_BufferLines > 0) str_append_format(sLFS_Buffer, "\n");
    str_append(sLFS_Buffer, str_convert(logline, "ansi", "utf8"));
    sLFS_BufferLines++;
    printf("[%s] - %s", module, info);
    return 1;
}

public sLFS_Push(){
    if(str_valid(sLFS_Buffer)){
        if(str_len(sLFS_Buffer) && slFS_isRClientOnline){
            sLFS_discordSendMessage(sLFS_Buffer);
            str_clear(sLFS_Buffer);
            sLFS_BufferLines = 0;
        }
    }
    return 1;
}
public sLFS_Send(const info[], const module[]){
    sLFS_Register(info, module); // If lines or character length exceed limits, it pushes the buffer automatically, then starts adding a new line.
    if(sLFS_BufferLines) sLFS_Push(); //Pushes the current buffer.
    return 1;
}


public OnFilterScriptInit(){
    slFS_discordInit(); //Try to connect to the discord webhook.
    delay(1000);
    slFS_serverLogInit();
    return 1;
}

public OnFilterScriptExit(){
    slFS_serverLogExit();
    delay(1000);
    slFS_discordExit();
    return 1;
}