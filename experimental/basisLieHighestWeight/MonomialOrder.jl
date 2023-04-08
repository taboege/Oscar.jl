# manages methods for different orders of monomials

function lt_monomial_order(monomial_order, ZZx, x)
    """
    Returns the desired monomial_order function
    """
    #if isa(monomial_order, Function)
    #    return monomial_order
    if monomial_order == "GRevLex"
        choosen_monomial_order = degrevlex(x)
    elseif monomial_order == "RevLex"
        choosen_monomial_order = revlex(x)
    elseif monomial_order == "Lex"
        choosen_monomial_order = lex(x)
    else
        println("no suitable order picked")
    end
    return (mon1, mon2) -> (cmp(choosen_monomial_order, mon1, mon2) == -1)
end
