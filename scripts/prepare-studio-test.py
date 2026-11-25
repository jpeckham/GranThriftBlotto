"""Prepare a command-bar script for an already-open local Studio place."""
from pathlib import Path
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--cli", action="store_true")
parser.add_argument("--output", type=Path)
parser.add_argument("--clients", type=int, default=4, choices=range(4, 9))
parser.add_argument("--suite", choices=("heist", "classes", "mobile"), default="heist")
parser.add_argument("--orientation", choices=("portrait", "landscape"), default="portrait")
args = parser.parse_args()
if args.suite == "classes" and args.clients > 6:
    parser.error("classes adds two clients; Studio permits eight total")
if args.suite == "mobile":
    args.clients = 1

root = Path(__file__).resolve().parent.parent
server = (root / "tests/studio/server-probe.luau").read_text(encoding="utf-8")
client = (root / "tests/studio/client-probe.luau").read_text(encoding="utf-8")
classes = (root / "tests/studio/class-cases.luau").read_text(encoding="utf-8")
mobile = (root / "tests/studio/mobile-cases.luau").read_text(encoding="utf-8")
delimiter = "===="
assert f"]{delimiter}]" not in server + client + classes + mobile
device_setup = ""
device_cleanup = ""
if args.suite == "mobile":
    orientation = "Portrait" if args.orientation == "portrait" else "LandscapeLeft"
    device_setup = f'''local simulator=game:GetService("StudioDeviceSimulatorService")
local previousDevice=simulator:GetDeviceAsync()
local phone
for _,id in simulator:GetDeviceListAsync() do
    if simulator:GetDeviceInfoAsync(id).DeviceForm==Enum.DeviceForm.Phone then phone=id; break end
end
assert(phone,"No built-in phone preset")
simulator:SetDeviceAsync(phone)
simulator:SetResolutionAsync(568,320)
simulator:SetOrientationAsync(Enum.ScreenOrientation.{orientation})
'''
    device_cleanup = 'simulator:SetDeviceAsync(previousDevice)'
execute = f'service:ExecutePlayModeAsync({{clients=1,suite="mobile"}})' if args.suite == "mobile" else f'service:ExecuteMultiplayerTestAsync({args.clients},{{clients={args.clients},suite="{args.suite}"}})'
runner = f'''local service=game:GetService("StudioTestService")
task.wait(3)
assert(service.EditModeActive,"Stop the current playtest first")
{device_setup}
game.ServerScriptService.Main.Enabled=false
for _,container in {{game.ReplicatedStorage,game.ServerScriptService,game.StarterPlayer.StarterPlayerScripts}} do
    for _,child in container:GetChildren() do if child.Name=="NativeTestBus" or child.Name=="NativeScenarioProbe" or child.Name=="NativeClassCases" or child.Name=="NativeMobileCases" then child:Destroy() end end
end
local bus=Instance.new("RemoteEvent"); bus.Name="NativeTestBus"; bus.Parent=game.ReplicatedStorage
local client=Instance.new("LocalScript"); client.Name="NativeScenarioProbe"; client.Source=[{delimiter}[{client}]{delimiter}]; client.Parent=game.StarterPlayer.StarterPlayerScripts
local server=Instance.new("Script"); server.Name="NativeScenarioProbe"; server.Source=[{delimiter}[{server}]{delimiter}]; server.Parent=game.ServerScriptService
local classes=Instance.new("ModuleScript"); classes.Name="NativeClassCases"; classes.Source=[{delimiter}[{classes}]{delimiter}]; classes.Parent=game.ServerScriptService
local mobile=Instance.new("ModuleScript"); mobile.Name="NativeMobileCases"; mobile.Source=[{delimiter}[{mobile}]{delimiter}]; mobile.Parent=game.ServerScriptService
local ok,result=pcall(function() return {execute} end)
print("GTB_MULTIPLAYER_RUNNER "..game.HttpService:JSONEncode({{ok=ok,result=result}}))
game.ServerScriptService.Main.Enabled=true
bus:Destroy(); client:Destroy(); server:Destroy(); classes:Destroy(); mobile:Destroy()
{device_cleanup}'''
if not args.cli:
    runner = "task.spawn(function()\n" + runner + "\nend)"
destination = args.output or root / ("build/native-cli.luau" if args.cli else "build/native-command.luau")
destination.write_text(runner, encoding="utf-8")
print(f"Prepared {destination.relative_to(root)}")
