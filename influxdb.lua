--[[

  Copyright (C) 2016 Masahito Yano

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  influxdb.lua
  lua-writelog-influxdb
  Created by Masahito Yano on 16/12/13.

--]]

-- assign to local
local writelog = require('writelog');
local InetClient = require('net.stream.inet').client;
local gettimeofday = require('process').gettimeofday;
local concat = table.concat;
local getinfo = debug.getinfo;
-- constant
local CRLF = '\r\n';
local LOG_LEVEL_NAME = {
    [writelog.ERROR]   = 'error',
    [writelog.WARNING] = 'warn',
    [writelog.NOTICE]  = 'notice',
    [writelog.VERBOSE] = 'verbose',
    [writelog.DEBUG]   = 'debug'
};
-- protocol format for HTTP
local HTTP_FORMAT = concat( {
    'POST /write?db=%s HTTP/1.1',
    'Accept: */*',
    'Content-Type: application/x-www-form-urlencoded',
    'HOST: %s:%d',
    'Content-Length: %d',
    '',
    '%s'
}, CRLF );
-- line protocol of InfluxDB
local LINE_FORMAT = '%s%s %s %d';

local function sendlog( ctx, sender, ... )
    if select( '#', ... ) > 1 then
        return sender( ctx.sock, concat( {...}, ' ' ) );
    end

    return sender( ctx.sock, ... );
end


local function send( ctx, ... )
    sendlog( ctx, ctx.sock.send, ... );
end


local function sendq( ctx, ... )
    sendlog( ctx, ctx.sock.sendq, ... );
end


local function createLineProtocolRequest( lv, tags, fields )
    local tagstr = '';
    local fieldstr = '';

    for k, v in pairs( tags ) do
        tagstr = ('%s,%s=%s'):format( tagstr, k, v );
    end

    for k, v in pairs( fields ) do
        if fieldstr ~= '' then
            fieldstr = fieldstr .. ',';
        end
        fieldstr = ('%s%s="%s"'):format( fieldstr, k, v );
    end

    return LINE_FORMAT:format(
        LOG_LEVEL_NAME[lv],
        tagstr,
        fieldstr,
        gettimeofday() * 1000000000
    );
end 


local function formatter( ctx, lv, info, ... )
    local logstr = concat( writelog.tostrv( ... ), ' ' );
    local tags, fields, linestr, locstr;

    -- opttags = extractKeyVal( logstr );
    -- if opttags ~= '' then
    --     opttags = ',' .. opttags;
    -- end
    
    -- get location of source
    if not( info.source and info.currentline ) then
        info = getinfo( 3, 'Snl' );
    else
        info.name = 'NOT_PROVIDED'
    end
    locstr = ('%s:%d%s'):format(
        info.name or 'GLOBAL', info.currentline, info.source
    );

    -- set tags
    tags = {
        location = locstr
    };

    -- set fields
    fields = {
        log = logstr
    };

    linestr = createLineProtocolRequest( lv, tags, fields );

    return HTTP_FORMAT:format(
        ctx.dbname,
        ctx.host,
        ctx.port,
        #linestr,
        linestr
    );
end


--- reduce      quash response (please call when fd is readable)
-- @param ctx   logger instance
-- @param ishup hang-up flag
local function reduce( ctx, ishup )
    if not ishup then
        local msg, err, again = ctx.sock:recv();

        while not again and msg ~= '' do
            if err then
                print( 'error...' );
            end
            msg, err, again = ctx.sock:recv();
        end
    end    
end


--- flush       flush sending que for noblocking mode (please call when fd is writable)
-- @param ctx   logger instance
local function flush( ctx )
    ctx.sock:flushq();
end


--- close       socket closer
-- @param ctx   logger instance
local function close( ctx )
    ctx.sock:close();
    return true;
end


--- getfd       get file descriptor
-- @param ctx   logger instance
-- @return fd   file descriptor
local function getfd( ctx )
    return ctx.sock:fd();
end


--- new
-- @param lv        log level (ex: writelog.NOTICE)
-- @param ctx       logger instance by writelog
-- @param opts      options
-- @return logger   logger instance
-- @return err      error message
local function new( lv, ctx, opts )
    local sendfn = send;
    local err;

    -- set database name
    if opts and opts.dbname then
        ctx.dbname = opts.dbname;
    else
        return nil, 'dbname is not set';
    end

    -- check formatter
    if opts and opts.formatter then
        return nil, 'Custom formatter is not supported';
    end

    -- set flush method if non-blocking mode
    if opts and opts.nonblock == true then
        ctx.flush = flush;
        ctx.nonblock = true;
        sendfn = sendq;
    end

    -- inet socket
    if ctx.host then
        ctx.sock, err = InetClient.new({
            host = ctx.host,
            port = ctx.port
        });
    -- unix domain socket
    else
        return nil, 'InfluxDB can not use unix domain socket'
    end

    if err then
        return nil, err;
    elseif ctx.nonblock then
        ctx.sock:nonblock( true );
    end

    ctx.getfd = getfd;
    ctx.close = close;
    ctx.reduce = reduce;

    return writelog.create(
        ctx,
        lv,
        sendfn,
        function( ... )
            return formatter( ctx, ... );
        end
    );
end


-- exports
return {
    new = new
};

