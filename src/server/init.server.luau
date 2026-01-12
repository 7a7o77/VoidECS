--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")
local ECS = require(ReplicatedStorage.Shared.ECS)
local random = Random.new(tick())

type PlayerData =                     {Instance:Player,JoinTime:number}
local PlayerData = ECS.Component()  ::ECS.Component<PlayerData>
local Intruder = ECS.Component()    ::ECS.TagComponent


function IntruderSystem()
    for PlayerEntity:ECS.Entity,ThisPlayerData:PlayerData in ECS.Query(PlayerData,Intruder) do
        print(PlayerEntity,ThisPlayerData,PlayerData,Intruder)
        if not ECS.Get(PlayerEntity, Intruder) or random:NextNumber() < 0.5 then continue end
        print(ThisPlayerData.Instance.Name, "Intruder Found.")
        ThisPlayerData.Instance:Kick()
        ECS.Remove(PlayerEntity,Intruder);
        print(ThisPlayerData.Instance.Name, "Intruder Eliminated.")
    end
end



Players.PlayerAdded:Connect(function(plr: Player)
    local PlayerEntity = ECS.Entity()
    ECS.SetComponent(PlayerEntity, PlayerData, {
        Instance=plr,
        JoinTime=tick(),
    })

    
    ECS.Add(PlayerEntity, Intruder)
    IntruderSystem();
end)




