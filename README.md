# serverLog

This library aims to provide a easy way to setup a logging system for your server, using both local server root logfiles (through FileManager) and a Discord webhook (using pawn-requests), in order to register logs of relevant information regarding your open.mp gamemode.\
It takes advantage of PawnPlus, pawn-requests, and FileManager plugins to do so.\
This library can be either embedded into your gamemode (as a module) or ran as a side script in your open.mp server.

### Requirements
[PawnPlus v.1.5.1](https://github.com/IS4Code/PawnPlus/releases/tag/v1.5.1)\
[pawn-requests v0.10.0](https://github.com/Southclaws/pawn-requests/releases/tag/0.10.0)
[SA-MP-FileManager v 1.5 - Final Release](https://github.com/JaTochNietDan/SA-MP-FileManager/releases/tag/1.5.1)


### Installation: As a side script

1. Remember to make sure you got both [PawnPlus v.1.5.1](https://github.com/IS4Code/PawnPlus/releases/tag/v1.5.1) and [pawn-requests v0.10.0](https://github.com/Southclaws/pawn-requests/releases/tag/0.10.0) includes and plugins in respective folders.

2. Retrieve `serverLog.inc`, `filterscripts` folder from the current repository.
3. Drop `serverLog.inc` inside your includes folder (the one your gamemode compiles from!).
4. Add `#include <serverLog>` at your gamemode main script. This will enable the function needed to call the side script functions from the main script.\
From here on you can actually write or modify your code and use the function to log your info.
5. Compile the filterscript `serverLog.p` as retrieved.
6. At your server's `config.json`, add `filterscripts/serverLog` as a `side_script`.
7. Inside `scriptfiles` folder, create a new file `webhook.ini`
8. Paste your Discord Webhook link inside `webhook.ini` (if you don't know how to create one, look [this guide](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)). Save the file.
9. Run your server. It should instantly kick up and send some startup message into your discord channel.

### Installation: As a main script module

1. Remember to make sure you got both [PawnPlus v.1.5.1](https://github.com/IS4Code/PawnPlus/releases/tag/v1.5.1) and [pawn-requests v0.10.0](https://github.com/Southclaws/pawn-requests/releases/tag/0.10.0) includes and plugins in respective folders.
2. Copy the `modules/` inside your main script folder. This will put the module folder inside your main script folder.
3. Edit your main script, add `#include "modules/serverLog/serverLog.p"`. From here on you can use the library functions to log your info.
4. Make sure to call `sLM_Init()` and `sLM_Exit()`, in your main `OnGameModeInit()` and `OnGameModeExit()` script.\
Example:
```c
public OnGameModeInit(){
    sLM_Init();
    //Keep loading your thing from now on.
}

public OnGameModeExit(){
    //Unload your thing here, not after stopping serverLog!
    sLM_Exit();
}
```
5. Inside `scriptfiles` folder, create a new file: `webhook.ini`
6. Paste your Discord Webhook link inside `webhook.ini` (if you don't know how to create one, look [this guide](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)). Save the file.
7. Compile and run your server. It should instantly kick up and send some startup message into your discord channel.


## Important
Currently you cannot actually use both filterscript and module versions, so you need to only choose between one of them, as both are pretty much identical implementations of the same code.\
Ergo, do not include `<serverlog>` in your main script and then include the module, or viceversa. This will produce a compiler error.  
Although, if side script is loaded when using a gamemode that has embedded the serverLog module inside of it will cause the side script to be killed as soon as module identifies it.

## Usage

> `serverLogRegister` will register your log line in the buffer. It will be sent as soon as the buffer fills up to its maximum (1900 characters, or 20 lines.)\
```c
serverLogRegister(const info[], const module[] = "serverLog")
```


#### Example:
```c
public OnPlayerConnect(playerid){
    new name[25];
    new logline[128];
    GetPlayerName(playerid, name, sizeof(name));
    format(logline, sizeof(logline), "%s joined the server.", name);
    serverLogRegister(logline, "player"); // "player" being the optional "module" name. Suitable for modular gamemodes.
    return 1;
}
```
#

> `serverLogPush` will immediately \"push\" the current buffer to send and clear its content after doing it.

```c
public serverLogPush()
```

#### Example:
```c
public OnGameModeInit(){
    discordInit(); //Try to connect to the discord webhook.
    delay(1000);
    serverLogInit();
    //Load your thing here




    SetTimer("serverLogPush", 300000, true); //Set a timer so the log forcefully sends a discord webhook message, after 5 minutes, regardless of line count or characters inserted.
    return 1;
}
```

#


> `serverLogSend` will add a new logline AND push the log buffer after adding it. It is useful for urgent messages that needs to be received as soon as possible.  
> It is not recomended to use it often as it keeps pushing the buffer without necessarily completing it, which can also mess up with the rate limit of Discord webhook messages.
```c
stock serverLogSend(const info[], const module[] = "serverLog")
```

#### Example:
```c
public OnRconLoginAttempt(ip[], password[], success)
{
    if (!success)
        serverLogSend("Someone tried to log into RCON, and failed!!", "RCON");
    return 1;
}
```

### Disable module message

The library's default behavior will append a specified module name (or default, "serverLog"). This was made like this so modules or pieces of logs are more easily recognizable between the global log lines.  
However, this option can be disabled, by defining `serverlog_NO_MODULES` before including the module (or, if compiling it as a side script, defining it in the own filterscript code).

Enabled: `[DD/MM/YYYY HH/MM/SS] - [module-name-here] - Log info here`  
Disabled: `[DD/MM/YYYY HH/MM/SS] - Log info here`