local ServerStuffs = {};
ServerStuffs.__index = ServerStuffs;

local Client = require("serverstuffs/client");
local Server = require("serverstuffs/server");

enet = require("enet");

function ServerStuffs.createClient(connectAddress)
    return Client.new(connectAddress);
end
function ServerStuffs.createServer(bindAddress)
    return Server.new(bindAddress);
end

return ServerStuffs;