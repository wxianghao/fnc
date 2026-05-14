---
numbering:
  headings: false
kernelspec:
  display_name: Julia 1
  language: julia
  name: julia-1.12
---
```{code-cell}
:tags: [remove-cell]
import Pkg; Pkg.activate("/Users/driscoll/Documents/GitHub/fnc")

using FNCFunctions

using Plots
default(
    titlefont=(11,"Helvetica"),
    guidefont=(11,"Helvetica"),
    linewidth = 2,
    markersize = 3,
    msa = 0,
    size=(500,320),
    label="",
    html_output_format = "svg"
)

using PrettyTables, LaTeXStrings, Printf
using LinearAlgebra
```

# Frontmatter

## Usage

(demo-usage-julia)=

``````{dropdown} @demo-usage
:open:
```{code-cell}
println("Welcome to Julia! Do you know π to 100 digits? Because I do! Look:")
setprecision(328)
BigFloat(π)
```
``````
