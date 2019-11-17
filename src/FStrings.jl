module FStrings
using Printf

export @f_str

regex = r"(?<!\\)\{(.*?)(?::+?(.*?))?(?<!\\)\}"


"""
    @f_str(string::AbstractString)

Loose implementation of `fstring` literal string interpolation as in Python.

# Examples
```julia-repl
using FStrings
julia> f"π = {π:.2f}"
"3.14"
```

# References

- (PEP 498 -- Literal String Interpolation)[https://www.python.org/dev/peps/pep-0498/]
"""
macro f_str(string::AbstractString)
    new_string = ""
    args = Any[]
    last_pos = 1
    for (idx, match) = enumerate(eachmatch(regex, string))
        new_string *= string[last_pos:match.offset-1]
        last_pos = match.offset + length(match.match)

        expr = match.captures[1]
        if length(expr) == 0
            @warn "Format string field without content present - skipping."
            continue
        end
        if match.captures[2] === nothing
            frmt = "s"
        else
            frmt = match.captures[2]
        end
        new_string *= "%$frmt"
        push!(args, Meta.parse(expr))
    end
    if last_pos <= length(string)
        new_string *= string[last_pos:end]
    end

    ex = :(@sprintf($new_string, $(esc.(args)...)))
    return ex
end

end  # module
