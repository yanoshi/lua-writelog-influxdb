package = "writelog-influxdb"
version = "0.1.1-1"
source = {
    url = "git://github.com/yanoshi/lua-writelog-influxdb.git",
    tag = "0.1.1"
}
description = {
    summary = "logger module of writelog using InfluxDB",
    homepage = "https://github.com/yanoshi/lua-writelog-influxdb",
    license = "MIT/X11",
    maintainer = "Masahito Yano"
}
dependencies = {
    "lua >= 5.1",
    "net >= 0.3.0",
    "process >= 1.6.0",
    "writelog >= 0.5.0",
}
build = {
    type = "builtin",
    modules = {
        ["writelog.influxdb"] = "influxdb.lua",
    }
}
