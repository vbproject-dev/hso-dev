# HSO VBPixel Server Project

## Requirements

* Linux
* Git

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

Create the configuration file:

```text
assets/res/config.json
```

Add:

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

Replace `YOUR_DATABASE_PASSWORD` with your MariaDB/MySQL password.

### Database Configuration

| Option     | Description       | Default     |
| ---------- | ----------------- | ----------- |
| `host`     | Database host     | `localhost` |
| `user`     | Database username | `root`      |
| `password` | Database password | -           |
| `name`     | Database name     | `hso_lua`   |
| `port`     | Database port     | `3306`      |

### Server Configuration

| Option | Description     | Default |
| ------ | --------------- | ------- |
| `port` | HSO server port | `19129` |

### Web Configuration

| Option | Description     | Default |
| ------ | --------------- | ------- |
| `port` | Web server port | `80`    |

## Start Server

Start the server in the background:

```bash
nohup ./SV > server.log 2>&1 &
```

The server will continue running after the terminal is closed.


## Update

Pull the latest changes:

```bash
git pull
```

Make sure the server is executable:

```bash
chmod +x SV
```

Start the server:

```bash
nohup ./SV > server.log 2>&1 &
```

## License

VBPixel's private project
