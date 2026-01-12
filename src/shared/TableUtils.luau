--!strict
local export = {}
type HashMap<K,V> = {[K]:V}

function export.MixTables<A,B>(TableA:{[A]:B},TableB:{[A]:B})
    local Result = table.clone(TableA) :: {[A]:B}
    for i,v in TableB do Result[i] = v end

    return Result
end

function export.AndTables<A,B>(TableA:{[A]:B},TableB:{[A]:B})
    local Result = table.clone(TableA) 
    for i,v in TableA do 
        if not TableB[i] then Result[i] = nil end
    end
    return Result
end

function export.All<A,B>(Target:{[A]:B},predicate:(Key:A,Value:B)->boolean) : boolean
for K,V in Target do
    if not predicate(K, V) then return false end
end
return true
end

function export.Filter<K,V>(Target:{[K]:V},predicate:(Key:K,Value:V)-> boolean)
    local Result : {[K]:V} = {}
    for Key,Value in Target do
        if predicate(Key, Value) then Result[Key] = Value end
    end
    return Result
end

function export.GetGaps<V>(Target:{[number]:V})
    local Index = 0
    local Result : HashMap<number,true> = {}
    while true do
        local NewIndex = next(Target,Index)
        if (NewIndex == nil) then break end
        if (NewIndex > Index + 1) then Result[NewIndex+1] = true end 
        Index = NewIndex
    end
    return Result;
end

function export.GetFirstGap<V>(Target:{[number]:V})
    local Index = 0
    while true do
        local NewIndex = next(Target,Index)
        if (NewIndex == nil) then break end
        if (NewIndex > Index + 1) then return NewIndex+1 end 
        Index = NewIndex
    end
    return -1;
end

function export.HasGap<V>(Target:{[number]:V})
    local Index = 0

    while true do
        local NewIndex = next(Target,Index)
        if (NewIndex == nil) then return true end
        if (NewIndex > Index + 1) then return false end 
    end
end

function export.IsEmpty<K,V>(Target:{[K]:V})
    return next(Target) == nil
end

return export