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
julia> f"π ≈ {π:.2f}"
"π ≈ 3.14"
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
        ext_string = string[last_pos:match_.offset-1]
        ext_string = replace(ext_string, "%"=>"%%")
        new_string *= ext_string
        last_pos = match_.offset + length(match_.match)

        expr_txt = match_.captures[1]
        if length(expr_txt) == 0
            @warn "Format string field without content present - skipping."
            continue
        end
        expr = Meta.parse(expr_txt)  # Needs to be valid Julia code

        frmt_txt = match_.captures[2]
        if frmt_txt === nothing
            frmt = "s"
        elseif frmt_txt == ""
            frmt = "s"
        #elseif frmt_txt[end] == 'b'
        # Potential extension for a binary format. Could use `bitstring` 
        # to convert result of expr. Needs parsing of the leading `0`
        # and bitwidth count. I.e. f"{123:b}", f"{123:8b}", f"{123:08b}"
        else  
            frmt = frmt_txt
        end
        # *) Handle invalid format strings already here
        if match(regex_valid_format_specifiers, frmt) === nothing
            exc_txt = "invalid printf format string: \"$frmt\""
            exc = :(throw(ArgumentError($exc_txt)))
            return exc
        end
        new_string *= "%$frmt"

        push!(args, expr)
    end
    if last_pos <= length(string)
        ext_string = string[last_pos:end]
        ext_string = replace(ext_string, "%"=>"%%")
        new_string *= ext_string
    end

    # `macro f_str` received escape characters (e.g. `"\n"`) with the backslash
    # escaped. Need to undo this before passing it on.
    new_string = unescape_string(new_string)

    # In case `new_string` is empty, the `@sprintf` throws `LoadError`.
    # Workaround for now:
    if length(new_string) == 0
        return new_string
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
