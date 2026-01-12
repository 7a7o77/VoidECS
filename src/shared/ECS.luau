--!strict
local TableUtils = require(script.Parent.TableUtils)
type HashMap<K,V> = {[K]:V}

export type ECSID<T=any> = {__T:T}&number
export type Entity<T=nil> = {__T:T}&number
export type Component<T=any> = {__T:T}&number

export type TagComponent = Component<true>

type ComponentData<T> = HashMap<Entity,T>
type World<T=any> = HashMap< Component<T>, ComponentData<T> >

local ComponentMask = bit32.lshift(1, 20)
local FreeIds: HashMap<ECSID,true> = {}

local EntityCount = 0
local ComponentCount = 0
local ComponentNextId = ComponentMask
local EntityNextId = 0


local World : World = {}
local export = {}

do --Assertion logic.
    function export.IsComponent<T>(object:ECSID<T>)
        return bit32.band(object,ComponentMask) == ComponentMask
    end

    function export.AssertComponent<T>(object:ECSID<T>)
        assert(export.IsComponent(object),"Type Error! Expected component got entity.")
    end

    function export.AssertEntity<T>(object:ECSID<T>)
        assert(not export.IsComponent(object),"Type Error! Expected entity got component.")
    end

    function export.AssertEntityComponent<T1,T2>(Entity:ECSID<T1>,Component:ECSID<T2>)
        export.AssertEntity(Entity);export.AssertComponent(Component);
    end
end

do --Creation logic.
    function export.Component()
        local FreeComponentsIds = TableUtils.Filter(FreeIds, function(Key: ECSID, Value: boolean):boolean
             return export.IsComponent(Key)
        end)

        local ID = -1

        if TableUtils.IsEmpty(FreeComponentsIds) then
            ID = ComponentNextId
            ComponentNextId += 1
            ComponentCount += 1
        else
            ID = next(FreeComponentsIds)::Component
        end

        World[ID::Component] = {};
        return ID;
    end


    function export.Entity() : Entity
                local FreeEntitesIds = TableUtils.Filter(FreeIds, function(Key: ECSID, Value: boolean):boolean
             return not export.IsComponent(Key)
        end)

        local ID = -1

        if TableUtils.IsEmpty(FreeEntitesIds) then
            ID = EntityNextId
            EntityNextId += 1
            EntityCount += 1
        else
            ID = next(FreeEntitesIds)::Entity
        end

        return ID::Entity;
    end
end

do --Freeing logic.
    function export.FreeComponent<T>(Component:Component<T>)
        export.AssertComponent(Component)

        for Entity in World[Component] do
            World[Component][Entity] = nil
        end
        World[Component] = nil;
        
        ComponentCount -= 1
        FreeIds[Component] = true;
    end

    function export.FreeEntity(Entity:Entity)
        export.AssertEntity(Entity)
        for ComponentId,ComponentData in World do
            ComponentData[Entity] = nil
        end
        EntityCount -= 1;
        FreeIds[Entity] = true;
    end
end

do -- Setting Logic
    function export.Add(Entity:Entity,Component:TagComponent)
        export.AssertEntityComponent(Entity, Component)
        World[Component][Entity] = true;
    end

    function export.Get<V>(Entity:Entity,Component:Component<V>) : V
        export.AssertEntityComponent(Entity, Component)
        return World[Component][Entity] :: V
    end

    function export.Set<T>(Entity:Entity,Component:Component<T>,Value:T)
        export.AssertEntityComponent(Entity, Component)
        World[Component][Entity] = Value;
    end

    function export.Remove(Entity:Entity,Component:TagComponent)
        export.AssertEntityComponent(Entity, Component)
        World[Component][Entity] = nil
    end
end

function export.ReadComponentId<T>(Component:Component<T>)
    return bit32.bxor(Component,ComponentMask)
end


do --Logic logic ? (starting to lose its meaning)
    function export.Has(Entity:Entity,...:Component)
        export.AssertEntity(Entity)
        local Args = {...}
        local Passed = TableUtils.All(Args, function(Index: number, ComponentId: Component): boolean 
            export.AssertComponent(ComponentId)
            return World[ComponentId] ~= nil
        end)

        return Passed;
    end
end

do --Iteration logic.
    -- no <...T>    ):<
    function export.Query<T...>(...:Component)
        local Args = {...} :: {Component}
        local PassedEntites:HashMap<Entity,true> = {}
        

        for _,ComponentID in Args do
            PassedEntites = TableUtils.MixTables(PassedEntites, World[ComponentID])
        end
        for _,ComponentID in Args do
            PassedEntites = TableUtils.AndTables(PassedEntites, World[ComponentID])
        end


        local EntityID : Entity = next(PassedEntites)::Entity;
        local function iter()
            if EntityID == nil then return nil end

            local ReturnBuffer : {} = {EntityID}
            
            for _,ComponentId in Args do
                ReturnBuffer[#ReturnBuffer+1] = World[ComponentId][EntityID]
            end
            
            EntityID = next(PassedEntites,EntityID)::Entity;
            return unpack(ReturnBuffer);

        end


        return setmetatable(table.clone(PassedEntites), {__iter = function()
                return iter
        end})
    end
end

return export