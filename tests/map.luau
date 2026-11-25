local rb=require("@lune/roblox")
local Map=require("../src/ServerScriptService/Core/Map")
return {
    ["Store builds four zones and unique interactable loot"] = function()
        local workspace=rb.Instance.new("Folder")
        local w=Map.build(workspace)
        for _,name in {"Parking","ThriftFloor","FittingRooms","Security"} do assert(w.root:FindFirstChild(name)) end
        local count=0
        for id,item in w.loot do assert(item.part and item.prompt and item.data.value>0 and id==item.part:GetAttribute("LootId")); count+=1 end
        assert(count>=35)
        assert(#w.cameras==4 and #w.scanners==2)
        assert(w.prompts.Cooler and w.prompts.Rescue and w.prompts.Shortcut)
    end,
    ["Each Buick has complete extraction interactions"] = function()
        local w=Map.build(rb.Instance.new("Folder"))
        assert(#w.cars==3)
        for _,car in w.cars do
            assert(car.prompts.Bank and car.prompts.Seat and car.prompts.Hitch and car.prompts.Depart)
            assert(car.home.Position.Y>0 and car.model.PrimaryPart)
        end
    end,
}
