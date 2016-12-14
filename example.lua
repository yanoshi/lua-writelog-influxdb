--[[
    There is sample for sending log using the non-blocking.

    Dependencies: sentry (https://github.com/mah0x211/lua-sentry)
--]]


-- assign to local
local writelog = require('writelog');
local sentry = require('sentry');
-- constants
local ONE_SHOT = false;
local EDGE_TRIGGER = false;
-- object
local sentryobj = assert( sentry.default() );
local readable, writable, logger, nevt, err, ev, etype, ishup;

-- function for debug
function debugfunc( ... )
    logger:debug( ... );
end

-- initialize logger object
logger, err = writelog.new( 
    writelog.DEBUG,
    'influxdb://128.199.183.111:8086', 
    {
        nonblock = true,
        dbname = 'writelog'
    }
);
if err then
    print( err );
    exit(0);
end

-- set up readable event
readable = assert( sentryobj:newevent() );
err = readable:asreadable( logger:getfd(), ONE_SHOT, EDGE_TRIGGER );
if err then
    print( 'error at asreadable' );
    exit(0);
end

-- set up writable event
writable = assert( sentryobj:newevent() );
err = writable:aswritable( logger:getfd(), ONE_SHOT, EDGE_TRIGGER );
if err then
    print( 'error at aswritable' );
    exit(0);
end

-- send log
debugfunc( { foo = 256, bar = 'abc' } );
logger:notice( 'this', 'is', 'log' );

-- loop for event
repeat
    nevt, err = sentryobj:wait(1);

    if nevt > 0 then
        ev, etype, ishup = sentryobj:getevent();
        while ev do
            if ev == readable then
                logger:reduce( ishup );
            elseif ev == writable then
                logger:flush();
            end
            ev, etype, ishup = sentryobj:getevent();
        end
    end    
until #sentryobj == 0;

logger:close();
