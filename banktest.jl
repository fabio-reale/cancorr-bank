"""
    getlevels(data, col[, max_num_of_levels]) -> Vector

Creates a Vector with the levels found in col-th column of data matrix, wich
must all be of the same type. The output Vector will be of that type.
If the number of distinct levels is provided, the function returns after
encountering the first instance of the last level.
This has been coded to make sure levels named "unknown" or "no" are put last,
as this makes analysis easier for interpretation.
"""
function getlevels(data::Matrix{<:Any}, col::Int, max_num_of_levels::Int)
    data_lines = size(data,1)
    #=
    Next atribution is important. eltype(levels) will be the same type
    eltype(data[2,col]). No type convertion happens here
    =#
    levels = [data[2,col]]
    i = 2
    while i < size(data,1) && length(levels) < max_num_of_levels
        i+= 1
        if all(x-> (x != data[i,col]), levels)
            push!(levels, data[i,col])
        end
    end
    #=
    Making sure "unkown" is the last level when exists.
    Making sure "no" maps to 0.0 on binary categories
    =#
    movelast!(levels,"unknown")
    movelast!(levels,"no")
    return levels
end
getlevels(data::Matrix{<:Any}, col::Int) = getlevels(data,col,size(data,1))



"""
    getlevelnames(data, col, levels) -> Vector{String}

For the purpose of creating visualizations.
Produces a Vector{String} with the names of the levels used in cancorr as well
as the name of the variable itself.
"""
function getlevelnames(data::Matrix{<:Any}, col::Int, levels::Vector{<:Any})
    pop!(levels)
    return map(x-> data[1,col]*":"*x, levels)
end
getlevelnames(data::Matrix{<:Any}, col::Int, levels::Vector{<:Real}) = data[1,col]
getlevelnames(data::Matrix{<:Any}, col::Int) = getlevelnames(data,col,getlevels(data,col))



"""
    dummify(data, col[, levels]) -> Matrix{Float64}

Returns a matrix of dummy indicator variables, one for each of the categories
contained in the col-th column of matrix data, except for the last level.
This exception is a consequence of the last level being uniquely defined from
the others. Including the last level would make the output matrix a singular one.
The list of levels can be provided for efficiency.
If levels are Real valued, outputs a Vector.
"""
function dummify(data::Matrix{<:Any}, col::Int, levels::Vector{<:Any})
    l = size(data,1)-1
    c = size(levels,1)-1
    dummy = Matrix{Bool}(l, c)
    for i in 1:c
        dummy[:,i] = map(x-> x == levels[i], data[2:end,col])
    end
    return float(dummy)
end
dummify(data::Matrix{<:Any}, col::Int, levels::Vector{<:Real}) = map(x->float(x),data[2:end,col])
dummify(data::Matrix{<:Any}, col::Int) = dummify(data,col,getlevels(data,col))


"""
    categorize!(data, col, p::Function)

Alters matrix data acording to transformation defined by Function p. Ideally, p is of the form x-> x == k ? x = string(A) : x = string(B).
It is adviseable to make a copy of data prior to calling this function
"""
# "With great powers..." Use this wisely!
function categorize!(data::Matrix{<:Any}, col::Int, p::Function)
    for i in 2:size(data,1)
        data[i,col] = p(data[i,col])
    end
end

"""
    buildmultivar(data, cols::Vector{Int}) -> Matrix{Float64}

Creates a matrix from the columns of matrix data specified in cols, making sure
cathegorical variables are included as indicator (dummy) variables
"""
function buildmultivar(data::Matrix{<:Any}, cols::Vector{Int})
    mapfoldl(x-> dummify(data,x), hcat, cols)
end



"""
    cancorr(data, xs, ys) -> U, S, V

Performs cannonical correlation calculations where the X multivariable is
extracted from the indices specified in Vector xs and the Y variable is
extracted from the indices specified in Vector ys. Columns of U are the
cannonical loadings for X, columns of V are cannonical ladings for Y.
U,S,V is the output of a call to function svd.
"""
function cancorr(data::Matrix{<:Any}, xs::Vector{Int}, ys::Vector{Int})
    X = buildmultivar(data,xs)
    Y = buildmultivar(data,ys)
    Sx = cov(X,1,false)
    Sy = cov(Y,1,false)
    Sxy = cov(X,Y,1,false)
    M = (Sx^(-0.5))*Sxy*(Sy^(-0.5))
    return svd(M)
end



# Just a quick coded function to visualize results of cancorr
function quickvis(data::Matrix{<:Any}, xs::Vector{Int}, ys::Vector{Int})
    U,d,V = cancorr(data,xs,ys)
    D = diagm(d)
    xnames = mapfoldl(x-> getlevelnames(data,x), vcat, xs)
    ynames = mapfoldl(x-> getlevelnames(data,x), vcat, ys)
    dispx = [xnames U*D]
    dispy = [ynames V*D]
    println(d)
    display(dispx)
    display(dispy)
end



"""
    movelast!(vec, val)

If val is element of vec, alters vec so that vec[end] == val
"""
function movelast!(vec::Vector{<:Any}, val)
    ind = findfirst(x-> x == val, vec);
    if ind != 0
        vec[ind] = vec[end];
        vec[end] = val;
    end
end



#=
reads the ; separeted file named bank.csv and stores the information in
data{Any,2}. Strings should be stored as strings and nums as expected num type.
For that to work, Substrings must be converted to Strings. It's easier that way.
=#
data = readdlm("bank-full.csv", ';')
data = map(data) do x
    if typeof(x) <: SubString
        convert(String, x)
    else x
    end
end

