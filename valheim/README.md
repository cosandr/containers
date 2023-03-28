# Valheim

Data dirs must exist before attempting to start container, i.e.

```sh
mkdir -p data/{config,valheim}
```

For port-forwading see [wiki page](https://valheim.fandom.com/wiki/Valheim_Dedicated_Server#Step_3:_Port_Forwarding_/_Remote_Access).

## Config

Save files

Windows: `%USERPROFILE%\AppData\LocalLow\IronGate\Valheim\`
Linux `$XDG_CONFIG_HOME/unity3d/IronGate/Valheim/`

Copy to `./data/config/worlds_local`, only `.{db,fwl}`.

Configure admins/bans/whitelist in `./data/config/adminlist.txt`, `./data/config/permittedlist.txt`.
They are SteamID64, can be found in logs, in-game with F2 or with sites [like this](https://www.steamidfinder.com/).
