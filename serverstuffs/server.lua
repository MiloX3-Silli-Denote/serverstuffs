local Server = {};
Server.__index = Server;

function Server.new(bindAddress)
    local instance = setmetatable({}, Server);

    instance.host = enet.host_create(bindAddress, 64, 3);

    instance.connections = {};

    instance.ssFuncs = {
        [string.char(0)] = instance.addNewElement;
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
        print("event");
        if event.type == "receive" then
            if event.channel == 0 then -- serverstuffs messaging
                self.ssFuncs[string.sub(event.data,1,1)](self, event.peer, string.sub(event.data, 2,-1));
            elseif event.channel == 1 then -- named event messaging
                print(event.data, 1);
            elseif event.channel == 2 then -- unamed event messaging
                print(event.data, 2);
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