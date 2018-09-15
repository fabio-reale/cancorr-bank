using DelimitedFiles, Statistics, LinearAlgebra

"""
    getlevels(data, col[, max_num_of_levels]) -> Vector

Creates a Vector with the levels found in col-th column of data matrix, wich
must all be of the same type. The output Vector will be of that type.
If the number of distinct levels is provided, the function returns after
encountering the first instance of the last level.
This has been coded to make sure levels named "unknown" or "no" are put last,
as this makes analysis easier for interpretation.
"""
function getlevels(data::Matrix, col::Int, max_num_of_levels::Int)
    data_lines = size(data,1)
    # Next atribution ensures levels will preserve type type, without conversion
    levels = [ data[1, col] ]
    i = 1
    while i < size(data,1) && length(levels) < max_num_of_levels
        i+= 1
        if !(data[i,col] in levels) # all(x-> (x != data[i,col]), levels)
            push!(levels, data[i,col])
        end
    end
    # Making sure "unkown" is the last level when exists.
    # Making sure "no" maps to 0.0 on binary categories.
    movelast!(levels,"unknown")
    movelast!(levels,"no")
    return levels
end
getlevels(data::Matrix, col::Int) = getlevels(data,col,size(data,1))


"""
    getlevelnames(data, col, levels) -> Vector{String}

For the purpose of creating visualizations.
Produces a Vector{String} with the names of the levels used in cancorr as well
as the name of the variable itself.
"""
function getlevelnames(header, col::Int, levels::Vector)
    pop!(levels)
    return map(x-> header[col]*":"*x, levels)
end
getlevelnames(header, col::Int, levels::Vector{<:Real}) = header[col]
getlevelnames(data::Matrix, header, col::Int) = getlevelnames(header, col, getlevels(data, col))


"""
    preprocess(data, col[, levels]) -> Matrix{Float64}

Preprocesses col-th column of data. If the list of levels is provided preprocess is more efficient.
When the levels of the selected column are nominal, preprocess returns a matrix of dummy indicator variables, one for each of the categories
contained in the given column of matrix data, with except for the last level. This exception is a consequence of the last level being uniquely defined from
the others. Including the last level would make the output matrix a singular one.
When the levels of the selected column are numerical, preprocess returns a vector of those values converted to Float64.
"""
function preprocess(data::Matrix, col::Int, levels::Vector)
    l = size(data,1)
    c = size(levels,1)-1
    temp = Matrix{Bool}(undef, l, c)
    for i in 1:c
        temp[:,i] = map(x-> x == levels[i], data[:,col])
    end
    return float(temp)
end
preprocess(data::Matrix, col::Int, levels::Vector{<:Real}) = map(float, data[:,col])
preprocess(data::Matrix, col::Int) = preprocess(data, col, getlevels(data,col))


"""
    categorize!(data, col, p::Function)

Alters matrix data acording to transformation defined by Function p. Ideally, p is of the form x-> x == k ? x = string(A) : x = string(B).
It is adviseable to make a copy of data prior to calling this function
"""# "With great powers..." Use this wisely!
function categorize!(data::Matrix, col::Int, p::Function)
    for i in 2:size(data,1)
        data[i,col] = p(data[i,col])
    end
end


"""
    buildmultivar(data, cols::Vector{Int}) -> Matrix{Float64}

Creates a matrix from the columns of matrix data specified in cols, making sure
nominal variables are included as indicator (dummy) variables
"""
function buildmultivar(data::Matrix, cols::Vector{Int})
    mapfoldl(x-> preprocess(data,x), hcat, cols)
end

function buildmultivar2(data::Matrix, cols::Vector{Int})
    transf_data = preprocess(data,cols[1])
    for c in cols[2:end]
        transf_data = [transf_data preprocess(data, c)]
    end
    return transf_data
end


"""
    cancorr(data, xs, ys) -> U, S, V

Performs cannonical correlation calculations where the X multivariable is
extracted from the indices specified in Vector xs and the Y variable is
extracted from the indices specified in Vector ys. Columns of U are the
cannonical loadings for X, columns of V are cannonical ladings for Y.
U,S,V is the output of a call to function svd.
"""
function cancorr(data::Matrix, xs::Vector{Int}, ys::Vector{Int})
    X = buildmultivar(data,xs)
    Y = buildmultivar(data,ys)
    Sx = cov(X,corrected=false)
    Sy = cov(Y,corrected=false)
    Sxy = cov(X,Y,corrected=false)
    M = (Sx^(-0.5))*Sxy*(Sy^(-0.5))
    return svd(M)
end


# Just a quick coded function to visualize results of cancorr
function quickvis(data::Matrix, header, xs::Vector{Int}, ys::Vector{Int})
    U,d,V = cancorr(data,xs,ys)
    D = diagm(0 => d) # == Matrix(Diagonal(d))
    xnames = mapfoldl(x-> getlevelnames(data,header,x), vcat, xs)
    ynames = mapfoldl(x-> getlevelnames(data,header,x), vcat, ys)
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
function movelast!(vec::Vector, val)
    ind = findfirst(x-> x == val, vec);
    if ind != nothing
        vec[ind] = vec[end];
        vec[end] = val;
    end
end


#=
reads the ; separeted file named bank.csv and stores the information in
data{Any,2}. Strings should be stored as strings and nums as expected num type.
For that to work, Substrings must be converted to Strings. It's easier that way.
=#
data, data_names = readdlm("bank-full.csv", ';', header=true)
data = map(data) do x
    if typeof(x) <: SubString
        convert(String, x)
    else
        x
    end
end
data_names = map(data_names) do x
    if typeof(x) <: SubString
        convert(String, x)
    else
        x
    end
end

#=
    Sufficient test:
quickvis(data, data_names, [1,3], [17])
1: Int, 3:nominal, 17:boolean
=#
