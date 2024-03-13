fx_version "cerulean"
game "gta5"
author "CENSOR_1337"
description "in game time and weather sync, using networked time"
lua54 "absolutely, yes"

shared_scripts {
    "config.shared.lua",
}

server_scripts {
    "core/server.lua",
}

client_scripts {
    "core/client.lua",
}
