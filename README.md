# HSO VBPixel Server Project

HSO game server developed by VBPixel. The server is written in C++ and integrates **Lua 5.4** for game scripting and server-side logic.

## Requirements

* Ubuntu 22.04 or newer
* Git
* MariaDB/MySQL

## Installation

Clone the repository:

```bash
git clone https://github.com/vbproject-dev/hso-dev.git
cd hso-dev
```

Make the server executable:

```bash
chmod +x SV
```

## Configuration

Create:

```text
assets/res/config.json
```

```json
{
    "database": {
        "host": "localhost",
        "user": "root",
        "password": "YOUR_DATABASE_PASSWORD",
        "name": "hso_lua",
        "port": 3306
    },
    "server": {
        "port": 19129
    },
    "web": {
        "port": 80
    }
}
```

Replace `YOUR_DATABASE_PASSWORD` with your database password.

## Start Server

```bash
nohup ./SV > server.log 2>&1 &
```

View logs:

```bash
tail -f server.log
```

## Update

```bash
cd hso-dev
git pull

```

## License

VBPixel private project.
