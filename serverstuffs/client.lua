local Client = {};
Client.__index = Client;

local NEW_ELEM = string.char(0);
local REQ_ELEM = string.char(1);
local CALL_SER = string.char(2);

--* channel 0 : serverstuffs messaging
--* channel 1 : named element messaging
--* channel 2 : unnamed element messaging
--* channel 3 : non element messaging

function Client.new(connectAddress)
    local instance = setmetatable({}, Client);

    instance.host = enet.host_create();
    instance.receiveKey = {}; -- dictionary of what the info bytes mean
    instance.sendKey = {}; -- dictionary of what sending prefixes are sent as

    instance.requests = {};

    instance.globalFuncs = {};
    instance.defaultRecieve = nil

    instance.ssFuncs = {
        [string.char(0)] = Client.setElementKey;
        [string.char(1)] = Client.receiveElement;
        [string.char(2)] = Client.callFunction;
    };

    if connectAddress then
        instance:connect(connectAddress);
    end

    return instance;
end
function Client:connect(connectAddress)
    self.server = self.host:connect(connectAddress, 4);
    self.receiveKey = {};
    self.sendKey = {};
end

function Client:setElementKey(data)
    print("setting element key", data);
    local key = string.sub(data, 1,2);
    local name = string.sub(data, 3,-1);

    self.receiveKey[key] = name;
    print(name);
    self.sendKey[name] = key;
end
function Client:receiveElement(data)
    local nameLen = string.byte(data, 1,1);

    local name = string.sub(data, 2, nameLen + 1);
    local elem = string.sub(data, nameLen + 2, -1);

    for i, v in ipairs(self.requests) do
        if v.name == name then
            v.callback(elem);

            table.remove(self.requests, i);
            return;
        end
    end
end
function Client:callFunction(data)
    local nameLen = string.byte(data, 1,1);
    local name = string.sub(data, 2, nameLen + 1);

    local curData = string.sub(data, nameLen + 2, -1);
    local args = {};

    while curData ~= "" do
        local len = string.byte(curData, 1,1);
        table.insert(args, string.sub(curData, 2,len + 1));

        curData = string.sub(curData, len + 2, -1);
    end

    if self.globalFuncs[name] then
        self.globalFuncs[name](unpack(args))
    end
end

function Client:getElement(name, callback)
    table.insert(self.requests, {name = name, callback = callback});
    self.server:send(REQ_ELEM .. name, 0);
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

function Client:sendToServer(data)
    self.server:send(data, 4);
end

function Client:callOnServer(name, ...)
    local args = {...};

    local data = string.char(string.len(name)) .. name;

    for i, v in ipairs(args) do
        data = data .. string.char(string.len(v)) .. v;
    end

    self.server:send(CALL_SER .. data, 0);
end

function Client:addCallback(name, callback)
    self.globalFuncs[name] = callback;
end

function Client:update(dt)
    local event = self.host:service();

    while event do
        if event.type == "receive" then
            if event.channel == 0 then -- serverstuffs messaging
                self.ssFuncs[string.sub(event.data, 1,1)](self, string.sub(event.data, 2,-1));
            elseif event.channel == 1 then -- named element messaging
            elseif event.channel == 2 then -- unnamed element messaging
            elseif event.channel == 3 then -- non element messaging
                if self.defaultRecieve then
                    self.defaultRecieve(event.data);
                end
            end
        elseif event.type == "connect" then
        elseif event.type == "disconnect" then
        end

        event = self.host:service();
    end
end

return Client;