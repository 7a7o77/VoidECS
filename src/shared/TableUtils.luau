--!strict
local export = {}
type HashMap<K,V> = {[K]:V}

function export.MixTables<A,B,C,D>(TableA:HashMap<A,B>,TableB:HashMap<C,D>)
    local Result = table.clone(TableA)::{}
    for i,v in TableB do Result[i] = v end

    return Result :: typeof(TableA)&typeof(TableB)
end

function export.AndTables<A,B,D,C>(TableA:HashMap<A,B>,TableB:HashMap<D,C>)
    local Result = table.clone(TableA) :: any
    for i,v in TableA do 
        if not (TableB::any)[i] then Result[i] = nil end
    end
    return Result :: typeof(TableA)&typeof(TableB)
end

function export.All<A,B>(Input:{[A]:B},predicate:(Key:A,Value:B)->boolean) : boolean
for K,V in Input do
    if not predicate(K, V) then return false end
end
return true
end

function export.Filter<K,V>(Input:{[K]:V},predicate:(Key:K,Value:V)-> boolean)
    local Result : {[K]:V} = {}
    for Key,Value in Input do
        if predicate(Key, Value) then Result[Key] = Value end
    end
    return Result
end

function export.GetGaps<V>(Input:{[number]:V})
    local Index = 0
    local Result : HashMap<number,true> = {}
    while true do
        local NewIndex = next(Input,Index)
        if (NewIndex == nil) then break end
        if (NewIndex > Index + 1) then Result[NewIndex+1] = true end 
        Index = NewIndex
    end
    return Result;
end

function export.GetFirstGap<V>(Input:{[number]:V})
    local Index = 0
    while true do
        local NewIndex = next(Input,Index)
        if (NewIndex == nil) then break end
        if (NewIndex > Index + 1) then return NewIndex+1 end 
        Index = NewIndex
    end
    return -1;
end

function export.HasGap<V>(Input:{[number]:V})
    local Index = 0

    while true do
        local NewIndex = next(Input,Index)
        if (NewIndex == nil) then return true end
        if (NewIndex > Index + 1) then return false end 
    end
end

function export.IsEmpty<K,V>(Input:{[K]:V})
    return next(Input) == nil
end

return export