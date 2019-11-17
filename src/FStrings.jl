module FStrings
using Printf

export @f_str

regex = r"(?<!\\)\{(.*?)(?::+?(.*?))?(?<!\\)\}"


"""
    @f_str(string::AbstractString)

Loose implementation of Python style `fstring` literal string interpolation
based on `Printf.@sprintf`.

# Examples
```julia-repl
julia> using FStrings
julia> f"π = {π:.2f}"
"π = 3.14"
```

# Format specifiers
Please refer to `Printf.@sprintf` for further details on the available
format specifiers. Also refer to the principle syntax of `fstring` via PEP 498.

# References
- [`Printf.@sprintf`]: https://docs.julialang.org/en/v1/stdlib/Printf/#Printf.@sprintf
- [PEP 498]: https://www.python.org/dev/peps/pep-0498/
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
