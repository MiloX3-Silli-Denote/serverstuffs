# serverstuffs
server/client interaction with lua, intended for love2d

## Basic Usage
download the serverstuffs fil and place it into your project and add ```Serverstuffs = require("serverstuffs/serverstuffs");``` into your main file
### creating a server
create a server by calling
```lua
server = Serverstuffs.createServer(serverAddress);
```
with 'serverAddress' being something like the following:
"<IP>:<port>" ex: 127.0.0.1:8888
"<hostname>:<port>" ex: localhost:8888
"*:<port>" ex: *:8888

### creating a client
create a client by calling
```lua
client = Serverstuffs.createClient([serverAddress]);
```
with 'serverAddres' being an optional argument that makes the client immediately connect to a server with that address

### interactions
connect a client to a server by calling:
```lua
client:connect(serverAddress);
```
this will dump all of its current server-client data and sever its connection with a current server (if one is connected)

send a variable to the server by calling:
```lua
client:sendElement(elementName, data);
```
both elementName and data are strings, to send multiple variables in one call (like a vector or a table) then you must have a way of converting strings into and out of the wanted data type.

if a variable will be sent a lot then you can shrink the size of the data being sent by calling:
```lua
client:addElement(elementName);
```
this will tell the server to remember a shorter name for the variable wanted instead of sending the name ever time, this is best used when you want to send the variable MANY times, ie: position of player every frame, continously changing time variable .etc
