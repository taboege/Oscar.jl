export GraphicalModel, graph, ring, param_ring, param_gens, vanishing_ideal

import Oscar.graph
import Oscar.vertices
import Oscar.gens
import Base.show


###################################################################################
#
#       Additional functions for graphs
#
###################################################################################


function vertices(G::Graph)

    E = [[src(e), dst(e)] for e in edges(G)]
    
    sort(unique(reduce(vcat, E)))
end



###################################################################################
#
#       Additional functions for matrices
#
###################################################################################


function cofactor(A)
    
    matrix(base_ring(A), [[(-1)^(i+j)*det(A[filter(l -> l != i, 1:n_rows(A)), filter(l -> l != j, 1:n_columns(A))]) for j in 1:n_columns(A)] for i in 1:n_rows(A)])
end


function adjugate(A::Generic.MatSpaceElem)
    
    transpose(cofactor(A))
end



###################################################################################
#
#       Generic Graphical Models
#
###################################################################################



struct GraphicalModel{G, T}
    graph::G
    ring::T
    param_ring::Ring
    param_gens
end



# todo
function graph(M::GraphicalModel)

    M.graph
end



# todo
function ring(M::GraphicalModel)

    M.ring
end



function param_ring(M::GraphicalModel)

    M.param_ring
end



function param_gens(M::GraphicalModel)

    M.param_gens
end




include("GaussianGraphicalModels.jl")




@doc raw"""
    vanishing_ideal(M::GraphicalModel)

Computes the vanishing ideal for a graphical model `M`. 
This is done by computing the kernel of the parameterization. 

## Examples

``` jldoctest directed_ggm
julia> vanishing_ideal(M)
Ideal generated by
  -s[1, 2]*s[2, 3] + s[1, 3]*s[2, 2]
```
"""
function vanishing_ideal(M::GraphicalModel)

    kernel(parameterization(M))
end
