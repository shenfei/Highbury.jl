struct DisjointSet
    p::Vector{Int}
    rank::Vector{Int}
    function DisjointSet(n::Int)
        p = [i for i in 1:n]
        rank = zeros(Int, n)
        new(p, rank)
    end
end


function find_set(i::Int, ds::DisjointSet)::Int
    while i != ds.p[i]
        i = ds.p[i]
    end
    return ds.p[i]
end


function union_set!(i::Int, j::Int, ds::DisjointSet)
    i = find_set(i, ds)
    j = find_set(j, ds)
    if ds.rank[i] > ds.rank[j]
        ds.p[j] = i
    else
        if ds.rank[i] == ds.rank[j]
            ds.rank[j] += 1
        end
        ds.p[i] = j
    end
end
