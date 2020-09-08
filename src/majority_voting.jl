using Distributed
using SharedArrays

export majority_element, distributed_majority_element, parallel_majority_element


@everywhere function BoyerMoore(A::AbstractArray{T, 1}, k::Int=2)::Dict{T, Int} where T
    candidates = Dict{T, Int}()
    for a in A
        if length(candidates) < k - 1 || haskey(candidates, a)
            candidates[a] = get!(candidates, a, 0) + 1
        else
            to_del = Vector{T}()
            for key in keys(candidates)
                candidates[key] -= 1
                candidates[key] <= 0 && append!(to_del, key)
            end
            for key in to_del
                pop!(candidates, key)
            end
        end
    end
    return candidates
end


function majority_element(A::Vector{T}, k::Int=2)::Vector{T} where T
    @assert k >= 2 "k must be an integer no less than 2"

    candidates = BoyerMoore(A, k)
    for key in keys(candidates)
        candidates[key] = 0
    end
    for a in A
        haskey(candidates, a) && (candidates[a] += 1)
    end

    bar = div(length(A), k) + 1
    return [key for (key, v) in candidates if v >= bar]
end


@everywhere function merge_candidates!(X::Dict{T, Int}, Y::Dict{T, Int}, k::Int=2) where T
    for (key, v) in Y
        if length(X) < k - 1 || haskey(X, key)
            X[key] = get!(X, key, 0) + v
        else
            min_v = min(minimum(values(X)), v)
            to_del = Vector{T}()
            for a in keys(X)
                X[a] -= min_v
                X[a] <= 0 && append!(to_del, a)
            end
            for a in to_del
                pop!(X, a)
            end
            v > min_v && (X[key] = v - min_v)
        end
    end
    return X
end


function distributed_majority_element(A::Vector{T}, p::Int, k::Int=2)::Vector{T} where T
    @assert k >= 2 "k must be an integer no less than 2"

    n = length(A)
    step = n ÷ p

    A = SharedVector(A)
    candidates = @distributed merge_candidates! for i = 1:p
        left = (i - 1) * step + 1
        right = i == p ? n : i * step
        BoyerMoore(view(A, left:right), k)
    end

    global_counter = @distributed mergewith(+) for i = 1:p
        counter = Dict(key => 0 for (key, v) in candidates)
        left = (i - 1) * step + 1
        right = i == p ? n : i * step
        for a in view(A, left:right)
            haskey(counter, a) && (counter[a] += 1)
        end
        counter
    end

    bar = n ÷ k + 1
    return [key for (key, v) in global_counter if v >= bar]
end

function parallel_majority_element(A::Vector{T}, p::Int, k::Int=2)::Vector{T} where T
    @assert k >= 2 "k must be an integer no less than 2"

    n = length(A)
    step = n ÷ p

    pool = Vector{Dict{T, Int}}(undef, p)
    Threads.@threads for i = 1:p
        left = (i - 1) * step + 1
        right = i == p ? n : i * step
        pool[i] = BoyerMoore(view(A, left:right), k)
    end

    candidates = reduce(merge_candidates!, pool)

    Threads.@threads for i = 1:p
        pool[i] = Dict(key => 0 for (key, v) in candidates)
        left = (i - 1) * step + 1
        right = i == p ? n : i * step
        for a in view(A, left:right)
            haskey(pool[i], a) && (pool[i][a] += 1)
        end
    end
    counter = reduce(mergewith(+), pool)
    bar = n ÷ k + 1
    return [key for (key, v) in counter if v >= bar]
end
