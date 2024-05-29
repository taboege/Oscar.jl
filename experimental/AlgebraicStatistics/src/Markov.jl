# -*- Markov rings for discrete random variables -*-

export markov_ring, tensor_ring, ring, random_variables, unknowns, state_space, marginal, ci_ideal

struct MarkovRing
  ring
  random_variables
  state_spaces
end

@doc raw"""
    markov_ring(rvs::Pair...; unknown="p", base_ring=QQ)::MarkovRing
    tensor_ring(rvs::Pair...; unknown="p", base_ring=QQ)::MarkovRing

The polynomial ring whose unknowns are the entries of a probability tensor.
`rvs` is a list of pairs `X => Q` where `X` is the name of a random variable
and `Q` is the list of states it takes. The polynomial ring being constructed
will have one variable for each element in the cartesian product of the `Q`s.
It is an Oscar multivariate polynomial ring whose variables are named `p[...]`
and whose `base_ring` is by default `QQ`. These settings can be changed via
the optional arguments.

The name `tensor_ring` is an alias for the constructor `markov_ring` because
that is really what a `MarkovRing` is: the coordinate ring of tensors of a
fixed format. The name `MarkovRing` is kept for compatibility in terminology
with the Macaulay2 package `GraphicalModels`.

## Examples

``` jldoctest ring_props
julia> R = markov_ring("A" => 1:2, "B" => 1:2, "X" => 1:2, "Y" => 1:2)
MarkovRing for random variables A → {1, 2}, B → {1, 2}, X → {1, 2}, Y → {1, 2} in 16 variables over Rational field
```
"""
function markov_ring(rvs::Pair...; unknown="p", base_ring=QQ)::MarkovRing
  random_variables = [p.first for p in rvs];
  state_spaces = [p.second for p in rvs];
  return MarkovRing(
    polynomial_ring(base_ring, unknown => Tuple(state_spaces)),
    random_variables,
    state_spaces
  )
end

const tensor_ring = markov_ring

function Base.show(io::IO, R::MarkovRing)
  print(io, "$(typeof(R)) for random variables ",
    join([string(x) * " → " * "{" * join(R.state_spaces[i], ", ") * "}" for (i, x) in Iterators.enumerate(R.random_variables)], ", "),
    " in $(length(gens(ring(R)))) variables over $(base_ring(ring(R)))"
  )
end

@doc raw"""
    ring(R::MarkovRing)

Return the Oscar multivariate polynomial ring inside the MarkovRing.

## Examples

``` jldoctest ring_props
julia> ring(R)
Multivariate Polynomial Ring in 16 variables p[1, 1, 1, 1], p[2, 1, 1, 1], p[1, 2, 1, 1], p[2, 2, 1, 1], ..., p[2, 2, 2, 2] over Rational field
```
"""
function ring(R::MarkovRing)
  return R.ring[1]
end

@doc raw"""
    random_variables(R::MarkovRing)

Return the list of random variables used to create the MarkovRing.

## Examples

``` jldoctest ring_props
julia> random_variables(R)
4-element Vector{String}:
 "A"
 "B"
 "X"
 "Y"
```
"""
function random_variables(R::MarkovRing)
    return R.random_variables
end

@doc raw"""
    ci_statements(R::MarkovRing)

Returns all the `CIStmt` objects which can be formed on the `random_variables(R)`.

``` jldoctest ring_props
julia> ci_statements(R)
24-element Vector{CIStmt}:
 [A ⫫ B | {}]
 [A ⫫ B | X]
 [A ⫫ B | Y]
 [A ⫫ B | {X, Y}]
 [A ⫫ X | {}]
 [A ⫫ X | B]
 [A ⫫ X | Y]
 [A ⫫ X | {B, Y}]
 [A ⫫ Y | {}]
[...]
```
"""
ci_statements(R::MarkovRing) = ci_statements(random_variables(R))

@doc raw"""
    unknowns(R::MarkovRing)

Return the tensor of variables in the polynomial ring.

## Examples

``` jldoctest ring_props
julia> unknowns(R)
2×2×2×2 Array{Nemo.QQMPolyRingElem, 4}:
[:, :, 1, 1] =
 p[1, 1, 1, 1]  p[1, 2, 1, 1]
 p[2, 1, 1, 1]  p[2, 2, 1, 1]

[:, :, 2, 1] =
 p[1, 1, 2, 1]  p[1, 2, 2, 1]
 p[2, 1, 2, 1]  p[2, 2, 2, 1]

[:, :, 1, 2] =
 p[1, 1, 1, 2]  p[1, 2, 1, 2]
 p[2, 1, 1, 2]  p[2, 2, 1, 2]

[:, :, 2, 2] =
 p[1, 1, 2, 2]  p[1, 2, 2, 2]
 p[2, 1, 2, 2]  p[2, 2, 2, 2]
```
"""
function unknowns(R::MarkovRing)
  return R.ring[2]
end

@doc raw"""
    find_random_variables(R::MarkovRing, K)

Given a subset `K` of `random_variables(R)` return its indices into the data
structure `R.random_variables`.
"""
function find_random_variables(R::MarkovRing, K)
  idx = [findfirst(x -> cmp(string(x), string(k)) == 0, R.random_variables) for k in K]
  if (j = findfirst(r -> r == nothing, idx)) != nothing
    error("random variable $(K[j]) not found in $(typeof(R))($(join([string(x) for x in R.random_variables], ", ")))")
  end
  return idx
end

@doc raw"""
    find_state(R::MarkovRing, K, x)

Given a set of random variables `K` and a joint event `x` they can take,
return the index vector `y` of `x` in the data structure `R.state_spaces`
such that `x[i] = R.state_spaces[J[i]][v[i]]` where `J = find_random_variables(R, K)`.
"""
function find_state(R::MarkovRing, K, x)
  J = find_random_variables(R, K)
  idx = [findfirst(z -> z == xi, R.state_spaces[J[i]]) for (i,xi) in Iterators.enumerate(x)]
  if (j = findfirst(r -> r == nothing, idx)) != nothing
    error("state $(x[j]) not attained by random variable $(string(K[j]))")
  end
  return idx
end

@doc raw"""
    state_space(R::MarkovRing, K=random_variables(R))

Return all states that the random subvector indexed by `K` can attain
in the ring `R`. The result is an `Iterators.product` iterator unless
`K` has only one element in which case it is a vector.

## Examples

``` jldoctest ring_props
julia> collect(state_space(R, ["A", "B"]))
2×2 Matrix{Tuple{Int64, Int64}}:
 (1, 1)  (1, 2)
 (2, 1)  (2, 2)
```
"""
function state_space(R::MarkovRing, K=R.random_variables)
  idx = find_random_variables(R, K)
  return length(idx) == 1 ? R.state_spaces[idx[1]] : Iterators.product([R.state_spaces[i] for i in idx]...)
end

function state_space_indices(R::MarkovRing, K=R.random_variables)
  idx = find_random_variables(R, K)
  return length(idx) == 1 ? range(1, length(R.state_spaces[idx[1]])) : Iterators.product([range(1, length(R.state_spaces[i])) for i in idx]...)
end

# -*- CI equations for MarkovRing -*-

# p is a permutation of 1:n and x is a vector of length n.
# This method returns the components of x permuted by p,
# e.g. apply_permutation([3,2,1], [0,1,2]) == [2,1,0].
function apply_permutation(p, x)
  px = Vector{Int64}(undef, length(p))
  for i in p
    px[p[i]] = x[i]
  end
  return px
end

@doc raw"""
    marginal(R::MarkovRing, K, x)

Return a marginal as a sum of unknowns from `R`. The argument `K` lists
random variables which are fixed to the event `x`; all other random
variables in `R` are summed over their respective state spaces.

## Examples

``` jldoctest ring_props
julia> marginal(R, ["A", "X"], [1,2])
p[1, 1, 2, 1] + p[1, 2, 2, 1] + p[1, 1, 2, 2] + p[1, 2, 2, 2]
```
"""
function marginal(R::MarkovRing, K, x)
  p = unknowns(R)
  N = random_variables(R)
  M = setdiff(N, K)
  summands = Vector()
  ix = find_state(R, K, x)
  for iy in state_space_indices(R, M)
    idx = apply_permutation(
      find_random_variables(R, [K..., M...]),
      [ix..., iy...]
    )
    push!(summands, p[idx...])
  end
  return length(summands) == 1 ? summands[1] : +(summands...)
end

@doc raw"""
    ci_ideal(R::MarkovRing, stmts)::MPolyIdeal

Return the ideal for the conditional independence statements
given by `stmts`.

## Examples

``` jldoctest
julia> R = MarkovRing("A" => 1:2, "B" => 1:2, "X" => 1:2);

julia> ci_ideal(R, [CI"X,A|B", CI"X,B|A"])
ideal(p[1, 1, 1]*p[2, 1, 2] - p[2, 1, 1]*p[1, 1, 2], p[1, 2, 1]*p[2, 2, 2] - p[2, 2, 1]*p[1, 2, 2], p[1, 1, 1]*p[1, 2, 2] - p[1, 2, 1]*p[1, 1, 2], p[2, 1, 1]*p[2, 2, 2] - p[2, 2, 1]*p[2, 1, 2])
```
"""
function ci_ideal(R::MarkovRing, stmts)::MPolyIdeal
  eqs = Vector()
  for stmt in stmts
    # The proper CI equations are the familiar 2x2 determinants in
    # marginals of the probability tensor.
    # TODO: Functional dependence not yet supported.
    QI = state_space(R, stmt.I)
    QJ = state_space(R, stmt.J)
    IJK = [stmt.I..., stmt.J..., stmt.K...]
    for z in state_space(R, stmt.K)
      for x in subsets(QI, 2)
        for y in subsets(QJ, 2)
          p11 = marginal(R, IJK, [x[1], y[1], z...]);
          p12 = marginal(R, IJK, [x[1], y[2], z...]);
          p21 = marginal(R, IJK, [x[2], y[1], z...]);
          p22 = marginal(R, IJK, [x[2], y[2], z...]);
          push!(eqs, p11*p22 - p12*p21)
        end
      end
    end
  end
  return ideal(eqs)
end
