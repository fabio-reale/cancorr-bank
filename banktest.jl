#=
reads the ; separeted file named bank.csv and stores the information in
bank{Any,2}. Strings should be stored as strings and nums as reasonable num type.
For that to work, Substrings must be converted to Strings. It's easier like this.
=#
data = readdlm("bank.csv", ';')
data = map(data) do x
    if typeof(x) <: SubString
        convert(String, x)
    else x
    end
end

#=
Returns an array where each index holds a distinct level in the col-th column of data.
If the number of levels is unkown, getlevels checks all indices in the column.
If the number of levels is provided, getlevels returns after the first instance of each level is found
=#
function getlevels(data::Matrix{<:Any}, col::Int, levels_final_length::Int)
    data_lines = size(data,1)
    #=
    Next atribution is important. eltype(levels) will be the same type
    eltype(data[2,col]). No type convertion happens here
    =#
    levels = [data[2,col]]
    i = 2
    while i < size(data,1) && length(levels) < levels_final_length
        i+= 1
        if all(x-> (x != data[i,col]), levels)
            push!(levels, data[i,col])
        end
    end
    #=
    Making sure "unkown" is the last level when exists. This is the best level
    to be removed in dummify function for the interpretation
    =#
    movelast!(levels,"unknown")
    return levels
end
getlevels(data::Matrix{<:Any}, col::Int) = getlevels(data,col,size(data,1))

#=
Returns a matrix of dummy variables from the cathegories of levels, except
for the last one. This is because the last level is uniquely defined from the
others and dependency is bad for stability.
=#
function dummify(data::Matrix{<:Any}, col::Int, levels::Vector{<:Any})
    l = size(data,1)-1
    c = size(levels,1)-1
    #=  To sacrifice time for space
    dum = Matrix{Float64}(l, c), but x-> x == levels[i] has to become
    x-> Int(x == levels[i]) and return value is just dummy
    =#
    dummy = Matrix{Bool}(l, c)
    for i in 1:c
        dummy[:,i] = map(x-> x == levels[i], data[2:end,col])
    end
    return float(dummy)
end
function dummify(data::Matrix{<:Any}, col::Int, levels::Vector{<:Real})
    l = size(data,1)-1
    dummy = Vector{Float64}(l)
    for i in 1:l
        dummy[i] = float(data[i+1,col])
    end
    return dummy
end
dummify(data::Matrix{<:Any}, col::Int) = dummify(data,col,getlevels(data,col))

function buildmultivar(data::Matrix{<:Any}, cols::Vector{Int})
    mapfoldl(x-> dummify(data,x), hcat, cols)
end

#=
If val is element of vec, alters vec so that vec[end] == val
=#
function movelast!(vec::Vector{<:Any}, val)
    ind = findfirst(x-> x == val, vec);
    if ind != 0
        vec[] = vec[end];
        vec[end] = val;
    end
end


println("included banktest.jl")
println("usar função cov()")
