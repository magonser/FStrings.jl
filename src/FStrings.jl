module FStrings
using Printf

export @f_str

# 0) Base version - has problems with `:` inside the Julia code section
# regex = r"(?<!\\)\{(.*?)(?::+?(.*?))?(?<!\\)\}"
# 1) Version that would require the Julia code section to escape `:` to `\:` inside {}
# regex = r"(?<!\\)\{(.*?)(?:(?<!\\):+?(.*?))?(?<!\\)\}"
# 2) Version that can keep normal `:` inside the Julia code, if there is one last `:` present as well
# regex = r"(?<!\\)\{(.*?)(?::+?([^:\n\r]*?))?(?<!\\)\}"
# 3) Version that can handle all cases by automatically matching only allowed format specifiers
# regex = r"(?<!\\)\{(.*?)(?::([^:\n\r^\(^\)^\[^\]]*?))?(?<!\\)\}"
# ...slightly improved matching:
regex = r"(?<!\\)\{(.*?)(?::([^:\n\r\(\)\[\]]*?[^:\n\r\(\)\[\]\d]))?(?<!\\)\}"

# Taken from: https://github.com/JuliaLang/julia/blob/3608c84e6093594fe86923339fc315231492484c/stdlib/Printf/src/Printf.jl
# printf specifiers:
#   %                       # start
#   (\d+\$)?                # arg (not supported)
#   [\-\+#0' ]*             # flags
#   (\d+)?                  # width
#   (\.\d*)?                # precision
#   (h|hh|l|ll|L|j|t|z|q)?  # modifier (ignored)
#   [diouxXeEfFgGaAcCsSp%]  # conversion
regex_valid_format_specifiers = r"^(\d+\$)?[\-\+#0' ]*(\d+)?(\.\d*)?(h|hh|l|ll|L|j|t|z|q)?[diouxXeEfFgGaAcCsSp%]$"

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

# Format Specifiers
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
    for (idx, match_) = enumerate(eachmatch(regex, string))
        new_string *= string[last_pos:match_.offset-1]
        last_pos = match_.offset + length(match_.match)

        expr = match_.captures[1]
        if length(expr) == 0
            @warn "Format string field without content present - skipping."
            continue
        end
        if match_.captures[2] === nothing
            frmt = "s"
        elseif match_.captures[2] == ""
            frmt = "s"
        else
            frmt = match_.captures[2]
        end
        # *) Handle invalid format strings already here
        if match(regex_valid_format_specifiers, frmt) === nothing
            exc_txt = "invalid printf format string: \"$frmt\""
            exc = :(throw(ArgumentError($exc_txt)))
            return exc
        end
        new_string *= "%$frmt"
        push!(args, Meta.parse(expr))
    end
    if last_pos <= length(string)
        new_string *= string[last_pos:end]
    end

    # TODO: Didn't figure out how to escape this, such that
    # `ArgumentErrors` are thrown in the outer scope _without_
    # producing also a `LoadError` when there is a wrong format specifier.
    # If this would work, *) can be removed.
    # Keep in mind though, that `@sprintf` should be evaluated only once
    # in the outside code for performance reasons.
    ex = :(@sprintf($new_string, $(esc.(args)...)))
    return ex
end

end  # module
