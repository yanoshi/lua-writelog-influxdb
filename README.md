# lua-writelog-influxdb
Logger module of writelog using InfluxDB.

## Dependencies

- writelog: https://github.com/mah0x211/lua-writelog
- net: https://github.com/mah0x211/lua-net
- process: https://github.com/mah0x211/lua-process

## Installation

```
luarocks install writelog-influxdb --from=http://yanoshi.github.io/rocks/
```

## Creating an instance of logger

If you run this code, you can get logger instance.

```
logger, err = writelog.new( [loglevel], pathname, opts )
```

### Parameters

- `loglevel:number`: log level constants (default: `WARNING`)
- `pathname:string`: pathname that scheme must be `influxdb://`
- `opts:table`: optional arguments
  - `dbname:string`: database name in influxdb
  - `nonblock:boolean`: enable a non-blocking socket

### Returns

1. `logger:table`: instance of writelog logger
2. `err:string`: error message

## Usage

Please watch [example.lua](example.lua)
