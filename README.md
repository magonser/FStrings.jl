# FStrings.jl

Loose implementation of Python style [`fstring` literal string interpolation][PEP 498]
based on [`Printf.@sprintf`][`Printf.@sprintf`].

## Usage Examples
```julia-repl
using FStrings

julia> f"π = {π:.2f}"
"π = 3.14"

julia> x = 30
julia> f"0x{x+1:02x}"
"0x1f"
```

## Format specifiers
Please refer to [`Printf.@sprintf`][`Printf.@sprintf`]
for further details on the available format specifiers. Also refer to the principle syntax of
[`fstring` literal string interpolation][PEP 498].


[`Printf.@sprintf`]: https://docs.julialang.org/en/v1/stdlib/Printf/#Printf.@sprintf
[PEP 498]: https://www.python.org/dev/peps/pep-0498/
