import Base: ∈, split
using Base: product

export AbstractHyperrectangle,
       radius_hyperrectangle,
       constraints_list,
       low, high

"""
    AbstractHyperrectangle{N<:Real} <: AbstractCentrallySymmetricPolytope{N}

Abstract type for hyperrectangular sets.

### Notes

Every concrete `AbstractHyperrectangle` must define the following functions:
- `radius_hyperrectangle(::AbstractHyperrectangle{N})::Vector{N}` -- return the
    hyperrectangle's radius, which is a full-dimensional vector
- `radius_hyperrectangle(::AbstractHyperrectangle{N}, i::Int)::N` -- return the
    hyperrectangle's radius in the `i`-th dimension

```jldoctest
julia> subtypes(AbstractHyperrectangle)
5-element Array{Any,1}:
 AbstractSingleton
 BallInf
 Hyperrectangle
 Interval
 SymmetricIntervalHull
```
"""
abstract type AbstractHyperrectangle{N<:Real} <: AbstractCentrallySymmetricPolytope{N}
end


# --- AbstractPolytope interface functions ---


"""
    vertices_list(H::AbstractHyperrectangle{N})::Vector{Vector{N}} where {N<:Real}

Return the list of vertices of a hyperrectangular set.

### Input

- `H` -- hyperrectangular set

### Output

A list of vertices.

### Notes

For high dimensions, it is preferable to develop a `vertex_iterator` approach.
"""
function vertices_list(H::AbstractHyperrectangle{N}
                      )::Vector{Vector{N}} where {N<:Real}
    # fast evaluation if H has radius 0
    if radius_hyperrectangle(H) == zeros(N, dim(H))
        return [center(H)]
    end
    return [center(H) .+ si .* radius_hyperrectangle(H)
        for si in Iterators.product([[1, -1] for i = 1:dim(H)]...)][:]
end

"""
    constraints_list(H::AbstractHyperrectangle{N})::Vector{LinearConstraint{N}}
        where {N<:Real}

Return the list of constraints of an axis-aligned hyperrectangular set.

### Input

- `H` -- hyperrectangular set

### Output

A list of linear constraints.
"""
function constraints_list(H::AbstractHyperrectangle{N})::Vector{LinearConstraint{N}} where {N<:Real}
    n = dim(H)
    constraints = Vector{LinearConstraint{N}}(undef, 2*n)
    b, c = high(H), -low(H)
    one_N = one(N)
    for i in 1:n
        ei = LazySets.Approximations.UnitVector(i, n, one_N)
        constraints[i] = HalfSpace(ei, b[i])
        constraints[i+n] = HalfSpace(-ei, c[i])
    end
    return constraints
end

# --- LazySet interface functions ---


"""
    σ(d::AbstractVector{N}, H::AbstractHyperrectangle{N}) where {N<:Real}

Return the support vector of a hyperrectangular set in a given direction.

### Input

- `d` -- direction
- `H` -- hyperrectangular set

### Output

The support vector in the given direction.
If the direction has norm zero, the vertex with biggest values is returned.
"""
function σ(d::AbstractVector{N}, H::AbstractHyperrectangle{N}) where {N<:Real}
    @assert length(d) == dim(H) "a $(length(d))-dimensional vector is " *
                                "incompatible with a $(dim(H))-dimensional set"
    return center(H) .+ sign_cadlag.(d) .* radius_hyperrectangle(H)
end

"""
    norm(H::AbstractHyperrectangle, [p]::Real=Inf)::Real

Return the norm of a hyperrectangular set.

The norm of a hyperrectangular set is defined as the norm of the enclosing ball,
of the given ``p``-norm, of minimal volume that is centered in the origin.

### Input

- `H` -- hyperrectangular set
- `p` -- (optional, default: `Inf`) norm

### Output

A real number representing the norm.

### Algorithm

Recall that the norm is defined as

```math
‖ X ‖ = \\max_{x ∈ X} ‖ x ‖_p = max_{x ∈ \\text{vertices}(X)} ‖ x ‖_p.
```
The last equality holds because the optimum of a convex function over a polytope
is attained at one of its vertices.

This implementation uses the fact that the maximum is achieved in the vertex
``c + \\text{diag}(\\text{sign}(c)) r``, for any ``p``-norm, hence it suffices to
take the ``p``-norm of this particular vertex. This statement is proved below.
Note that, in particular, there is no need to compute the ``p``-norm for *each*
vertex, which can be very expensive. 

If ``X`` is an axis-aligned hyperrectangle and the ``n``-dimensional vectors center
and radius of the hyperrectangle are denoted ``c`` and ``r`` respectively, then
reasoning on the ``2^n`` vertices we have that:

```math
\\max_{x ∈ \\text{vertices}(X)} ‖ x ‖_p = \\max_{α_1, …, α_n ∈ \\{-1, 1\\}} (|c_1 + α_1 r_1|^p + ... + |c_n + α_n r_n|^p)^{1/p}.
```

The function ``x ↦ x^p``, ``p > 0``, is monotonically increasing and thus the
maximum of each term ``|c_i + α_i r_i|^p`` is given by ``|c_i + \\text{sign}(c_i) r_i|^p``
for each ``i``. Hence, ``x^* := \\text{argmax}_{x ∈ X} ‖ x ‖_p`` is the vertex
``c + \\text{diag}(\\text{sign}(c)) r``.
"""
function norm(H::AbstractHyperrectangle, p::Real=Inf)::Real
    c, r = center(H), radius_hyperrectangle(H)
    return norm((@. c + sign_cadlag(c) * r), p)
end

"""
    radius(H::AbstractHyperrectangle, [p]::Real=Inf)::Real

Return the radius of a hyperrectangular set.

### Input

- `H` -- hyperrectangular set
- `p` -- (optional, default: `Inf`) norm

### Output

A real number representing the radius.

### Notes

The radius is defined as the radius of the enclosing ball of the given
``p``-norm of minimal volume with the same center.
It is the same for all corners of a hyperrectangular set.
"""
function radius(H::AbstractHyperrectangle, p::Real=Inf)::Real
    return norm(radius_hyperrectangle(H), p)
end

"""
    ∈(x::AbstractVector{N}, H::AbstractHyperrectangle{N})::Bool where {N<:Real}

Check whether a given point is contained in a hyperrectangular set.

### Input

- `x` -- point/vector
- `H` -- hyperrectangular set

### Output

`true` iff ``x ∈ H``.

### Algorithm

Let ``H`` be an ``n``-dimensional hyperrectangular set, ``c_i`` and ``r_i`` be
the box's center and radius and ``x_i`` be the vector ``x`` in dimension ``i``,
respectively.
Then ``x ∈ H`` iff ``|c_i - x_i| ≤ r_i`` for all ``i=1,…,n``.
"""
function ∈(x::AbstractVector{N},
           H::AbstractHyperrectangle{N})::Bool where {N<:Real}
    @assert length(x) == dim(H)
    for i in eachindex(x)
        if abs(center(H)[i] - x[i]) > radius_hyperrectangle(H, i)
            return false
        end
    end
    return true
end


# --- common AbstractHyperrectangle functions ---


"""
    high(H::AbstractHyperrectangle{N})::Vector{N} where {N<:Real}

Return the higher coordinates of a hyperrectangular set.

### Input

- `H` -- hyperrectangular set

### Output

A vector with the higher coordinates of the hyperrectangular set.
"""
function high(H::AbstractHyperrectangle{N})::Vector{N} where {N<:Real}
    return center(H) .+ radius_hyperrectangle(H)
end

"""
    high(H::AbstractHyperrectangle{N}, i::Int)::N where {N<:Real}

Return the higher coordinate of a hyperrectangular set in a given dimension.

### Input

- `H` -- hyperrectangular set
- `i` -- dimension of interest

### Output

The higher coordinate of the hyperrectangular set in the given dimension.
"""
function high(H::AbstractHyperrectangle{N}, i::Int)::N where {N<:Real}
    return center(H)[i] + radius_hyperrectangle(H, i)
end

"""
    low(H::AbstractHyperrectangle{N})::Vector{N} where {N<:Real}

Return the lower coordinates of a hyperrectangular set.

### Input

- `H` -- hyperrectangular set

### Output

A vector with the lower coordinates of the hyperrectangular set.
"""
function low(H::AbstractHyperrectangle{N})::Vector{N} where {N<:Real}
    return center(H) .- radius_hyperrectangle(H)
end

"""
    low(H::AbstractHyperrectangle{N}, i::Int)::N where {N<:Real}

Return the lower coordinate of a hyperrectangular set in a given dimension.

### Input

- `H` -- hyperrectangular set
- `i` -- dimension of interest

### Output

The lower coordinate of the hyperrectangular set in the given dimension.
"""
function low(H::AbstractHyperrectangle{N}, i::Int)::N where {N<:Real}
    return center(H)[i] - radius_hyperrectangle(H, i)
end

"""
    split(H::AbstractHyperrectangle{N}, num_blocks::AbstractVector{Int}
         ) where {N<:Real}

Partition a hyperrectangular set into uniform sub-hyperrectangles.

### Input

- `H`          -- hyperrectangular set
- `num_blocks` -- number of blocks in the partition for each dimension

### Output

A list of `Hyperrectangle`s.
"""
function split(H::AbstractHyperrectangle{N}, num_blocks::AbstractVector{Int}
              )::Vector{Hyperrectangle{N}} where {N<:Real}
    @assert length(num_blocks) == dim(H) "need number of blocks in each dimension"
    radius = copy(radius_hyperrectangle(H))
    total_number = 1
    lo = low(H)
    hi = high(H)

    # precompute center points in each dimension
    centers = Vector{StepRangeLen{N}}(undef, dim(H))
    for (i, m) in enumerate(num_blocks)
        if m <= 0
            throw(ArgumentError(m, "each dimension needs at least one block"))
        elseif m == one(N)
            centers[i] = range(lo[i] + radius[i], length=1)
        else
            radius[i] /= m
            centers[i] = range(lo[i] + radius[i], step=(2 * radius[i]),
                               length=m)
            total_number *= m
        end
    end

    # create hyperrectangles for every combination of the center points
    result = Vector{Hyperrectangle{N}}(undef, total_number)
    for (i, center) in enumerate(product(centers...))
        result[i] = Hyperrectangle(collect(center), copy(radius))
    end
    return result
end
