"""Prepare a command-bar script for an already-open local Studio place."""
from pathlib import Path

root = Path(__file__).resolve().parent.parent
server = (root / "tests/studio/server-probe.luau").read_text(encoding="utf-8")
client = (root / "tests/studio/client-probe.luau").read_text(encoding="utf-8")
delimiter = "===="
assert f"]{delimiter}]" not in server + client
runner = f'''task.spawn(function()
local service=game:GetService("StudioTestService")
assert(service.EditModeActive,"Stop the current playtest first")
game.ServerScriptService.Main.Enabled=false
for _,container in {{game.ReplicatedStorage,game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts}} do
    for _,child in container:GetChildren() do if child.Name=="NativeTestBus" or child.Name=="NativeScenarioProbe" then child:Destroy() end end
end
local bus=Instance.new("RemoteEvent"); bus.Name="NativeTestBus"; bus.Parent=game.ReplicatedStorage
local client=Instance.new("LocalScript"); client.Name="NativeScenarioProbe"; client.Source=[{delimiter}[{client}]{delimiter}]; client.Parent=game.StarterPlayer.StarterPlayerScripts
local server=Instance.new("Script"); server.Name="NativeScenarioProbe"; server.Source=[{delimiter}[{server}]{delimiter}]; server.Parent=game.ServerScriptService
local ok,result=pcall(function() return service:ExecuteMultiplayerTestAsync(4,{{clients=4}}) end)
print("GTB_MULTIPLAYER_RUNNER "..game.HttpService:JSONEncode({{ok=ok,result=result}}))
game.ServerScriptService.Main.Enabled=true
bus:Destroy(); client:Destroy(); server:Destroy()
end)'''
(root / "build/native-command.luau").write_text(runner, encoding="utf-8")
print("Prepared build/native-command.luau for the existing Studio command bar")
