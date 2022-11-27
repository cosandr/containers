# Syncthing container

https://github.com/f100024/syncthing_exporter

Get API key for exporter after syncthing ran at least once

```sh
grep -i api data/config/config.xml
```

Put it in a `.env` file

```sh
SYNCTHING_TOKEN="API_KEY"
```

`SYNCTHING_FOLDERSID` is required for `db_status` metrics.
