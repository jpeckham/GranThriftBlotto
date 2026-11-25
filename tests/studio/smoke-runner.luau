-- Run with Studio --task RunScript against the packaged place.
-- The injected probe is test-only and never included in the Rojo project.
local service = game:GetService("StudioTestService")
task.wait(3)
game:GetService("ServerScriptService").Main.Enabled = false
local signal = Instance.new("RemoteEvent")
signal.Name = "NativeClientProbe"
signal.Parent = game:GetService("ReplicatedStorage")
local client = Instance.new("LocalScript")
client.Name = "NativeClientProbe"
client.Source = [==[
local player=game:GetService("Players").LocalPlayer
local signal=game:GetService("ReplicatedStorage"):WaitForChild("NativeClientProbe")
local hud=player:WaitForChild("PlayerGui"):WaitForChild("GranThriftHUD",30)
signal:FireServer({hud=hud~=nil})
]==]
client.Parent = game:GetService("StarterPlayer").StarterPlayerScripts
local probe = Instance.new("Script")
probe.Name = "NativeSmokeProbe"
probe.Source = [==[
local service=game:GetService("StudioTestService")
local errors={}
local log=game:GetService("LogService").MessageOut:Connect(function(message,kind)
    if kind==Enum.MessageType.MessageError then table.insert(errors,message) end
end)
local ok,result=xpcall(function()
    local Players=game:GetService("Players")
    local Map=require(game.ServerScriptService.Core.Map)
    local Economy=require(game.ServerScriptService.Core.Economy)
    local Game=require(game.ServerScriptService.Core.Game)
    local old=workspace:FindFirstChild("ThriftyAcres"); if old then old:Destroy() end
    local reports={}
    game.ReplicatedStorage.NativeClientProbe.OnServerEvent:Connect(function(player,data) reports[player.UserId]=data end)
    local runtime=Game.start(Map.build(workspace),Economy.new())
    local expires=os.clock()+45
    repeat task.wait(0.2) until #Players:GetPlayers()>=1 or os.clock()>expires
    assert(#Players:GetPlayers()>=1,"No play client joined")
    local player=Players:GetPlayers()[1]
    local char=player.Character or player.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart",15)
    task.wait(3)
    assert(runtime.economy:snapshot(player).ready,"Studio wallet not ready")
    runtime:beginRound()
    task.wait(8)
    assert(runtime.phase=="Heist","Round did not reach Heist: "..runtime.phase)
    assert(runtime:state(player).role=="Gran","Solo practice assigned wrong role")
    assert(char:FindFirstChild("ThriftProps"),"Character costume missing")
    assert(reports[player.UserId] and reports[player.UserId].hud,"Client HUD did not initialize")
    assert(#errors==0,table.concat(errors,"\n"))
    return {passed=true,phase=runtime.phase,players=#Players:GetPlayers(),errors=errors}
end,debug.traceback)
log:Disconnect()
if not ok then result={passed=false,error=result,errors=errors} end
print("GTB_NATIVE_RESULT "..game:GetService("HttpService"):JSONEncode(result))
service:EndTest(result)
]==]
probe.Parent = game:GetService("ServerScriptService")
local ok, result = pcall(function()
	return service:ExecutePlayModeAsync({ suite = "native-smoke" })
end)
print("GTB_RUNNER_RESULT " .. game:GetService("HttpService"):JSONEncode({ ok = ok, result = result }))
