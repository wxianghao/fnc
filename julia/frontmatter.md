---
kernelspec:
  display_name: Julia 1
  language: julia
  name: julia-1.12
numbering:
  headings: false
---
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
