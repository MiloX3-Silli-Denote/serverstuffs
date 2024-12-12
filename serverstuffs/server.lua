local Server = {};
Server.__index = Server;

function Server.new(bindAddress)
    local instance = setmetatable({}, Server);

    instance.host = enet.host_create(bindAddress, 64, 3);

    instance.connections = {};

    instance.globalFuncs = {
        ['calllfunc'] = function(...)
            print(...);
        end
    };
    instance.defaultRecieve = nil;

    instance.ssFuncs = {
        [string.char(0)] = instance.addNewElement;
        [string.char(1)] = instance.getElement;
        [string.char(2)] = instance.callFunction;
    };

    return instance;
end

function Server:addNewElement(peer, name)
    local openName = self:getOpenName(peer);

    if not openName then
        return;
    end

    self.connections[peer].receiveKey[name] = openName;
    print("creating name");
    print(name);
    peer:send(string.char(0) .. openName .. name, 0);
end
function Server:getElement(peer, name)
    local elem = self.connections[peer].data[name];

    peer:send(string.char(1) .. string.char(string.len(name)) .. name .. elem, 0);
end
function Server:callFunction(peer, data)
    local nameLen = string.byte(data, 1,1);
    local name = string.sub(data, 2, nameLen + 1);

    local curData = string.sub(data, nameLen + 2, -1);
    local args = {};

    while curData ~= "" do
        local len = string.byte(curData, 1,1);
        table.insert(args, string.sub(curData, 2,len + 1));

        curData = string.sub(curData, len + 2, -1);
    end

    print(name);
    if self.globalFuncs[name] then
        self.globalFuncs[name](peer, unpack(args))
    end
end

function Server:getOpenName(peer)
    for i = 0, 255 do
        for j = 0, 255 do
            if not self.connections[peer].receiveKey[string.char(i,j)] then
                return string.char(i,j);
            end
        end
    end
end

function Server:update(dt)
    local event = self.host:service();

    while event do
        if event.type == "receive" then
            if event.channel == 0 then -- serverstuffs messaging
                print(event.data);
                self.ssFuncs[string.sub(event.data,1,1)](self, event.peer, string.sub(event.data, 2,-1));
            elseif event.channel == 1 then -- named event messaging
                local nameKey = string.sub(event.data, 1,2);
                local setVar = string.sub(event.data, 3,-1);

                self.connections[event.peer].data[self.connections[event.peer].receiveKey[nameKey]] = setVar;
            elseif event.channel == 2 then -- unnamed event messaging
                local nameLen = string.byte(event.data, 1,1);
                local name = string.sub(event.data, 2, nameLen + 1);
                local setVar = string.sub(event.data, nameLen + 2, -1);

                self.connections[event.peer].data[name] = setVar;
            elseif event.channel == 3 then -- non element messaging
                if self.defaultRecieve then
                    self.defaultRecieve(event.data);
                end
            end
        elseif event.type == "connect" then
            self.connections[event.peer] = {
                receiveKey = {};
                sendKey = {};
                data = {};
            };
        elseif event.type == "disconnect" then
            self.connections[event.peer] = nil;
        end

        event = self.host:service();
    end
end

return Server;