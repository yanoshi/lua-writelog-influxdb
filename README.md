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

Simple logger usage (blocking mode)

```lua
local unpack = unpack or table.unpack;
local writelog = require('writelog');
local logger = writelog.new( 
    writelog.DEBUG,
    'influxdb://127.0.0.1:8086',
    {
        nonblock = false,
        dbname = 'writelog'
    }
);
local args = {
    'hello',
    0,
    1,
    -1,
    1.2,
    'world',
    {
        foo = 'bar',
        baz = {
            x = {
                y = 'z'
            }
        }
    },
    true,
    function()end,
    coroutine.create(function()end)
};

logger:warn( unpack( args ) )
logger:notice( unpack( args ) )
logger:verbose( unpack( args ) )
logger:debug( unpack( args ) )
logger:close();
```

Non-blocking example, please see [example.lua](example.lua)

## Contributing

1. Fork it ( https://github.com/yanoshi/lua-writelog-influxdb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Licence

[MIT](LICENSE)

## Author

[yanoshi]( https://github.com/yanoshi )
