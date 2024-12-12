local Client = {};
Client.__index = Client;

local NEW_ELEM = string.char(0);

--* channel 0 : serverstuffs messaging
--* channel 1 : named element messaging
--* channel 2 : unnamed element messaging

function Client.new(connectAddress)
    local instance = setmetatable({}, Client);

    instance.host = enet.host_create();
    instance.receiveKey = {}; -- dictionary of what the info bytes mean
    instance.sendKey = {}; -- dictionary of what sending prefixes are sent as

    instance.ssFuncs = {
        [string.char(0)] = Client.setElementKey;
    };

    if connectAddress then
        instance:connect(connectAddress);
    end

    return instance;
end

function Client:setElementKey(data)
    print("setting element key", data);
    local key = string.sub(data, 1,2);
    local name = string.sub(data, 3,-1);

    self.receiveKey[key] = name;
    print(name);
    self.sendKey[name] = key;
end

function Client:connect(connectAddress)
    self.server = self.host:connect(connectAddress, 3);
    self.receiveKey = {};
    self.sendKey = {};
end

function Client:addElement(name)
    if not self.server then
        return;
    end

    self.server:send(NEW_ELEM .. name, 0);
end

function Client:sendElement(name, data)
    if not self.server then
        return;
    end

    if not self.sendKey[name] then
        self.server:send(string.char(string.len(name)) .. name .. data, 2);
        return;
    end

    self.server:send(self.sendKey[name] .. data, 1);
end

function Client:update(dt)
    local event = self.host:service();

    while event do
        if event.type == "receive" then
            if event.channel == 0 then -- serverstuffs messaging
                self.ssFuncs[string.sub(event.data, 1,1)](self, string.sub(event.data, 2,-1));
            elseif event.channel == 1 then -- named element messaging
            elseif event.channel == 2 then -- unnamed element messaging
            end
        elseif event.type == "connect" then
        elseif event.type == "disconnect" then
        end

        event = self.host:service();
    end
end

return Client;