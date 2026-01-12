local export = {}

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

return export