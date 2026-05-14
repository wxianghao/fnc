# Section 4.7

## Example 4.7.1

```{code-cell}
g(x) = [sin(x[1] + x[2]), cos(x[1] - x[2]), exp(x[1] - x[2])]
p = [1, 1];
```


```{code-cell}
using Printf
plt = plot(xlabel="iteration", yaxis=(:log10, "error"),
    title="Convergence of Gauss–Newton")
for R in [1e-3, 1e-2, 1e-1]
    # Define the perturbed function.
    f(x) = g(x) - g(p) + R * normalize([-1, 1, -1])
    x = FNC.levenberg(f, [0, 0])
    r = x[end]
    err = [norm(x - r) for x in x[1:end-1]]
    normres = norm(f(r))
    plot!(err, label=@sprintf("R=%.2g", normres))
end
plt
```

## Example 4.7.2

```{code-cell}
m = 25;
s = range(0.05, 6, length=m)
ŵ = @. 2 * s / (0.5 + s)                      # exactly on the curve
w = @. ŵ + 0.15 * cos(2 * exp(s / 16) * s);     # smooth noise added
```

```{code-cell}
scatter(s, w, label="noisy data",
    xlabel="s", ylabel="v", leg=:bottomright)
plot!(s, ŵ, l=:dash, color=:black, label="perfect data")
```

```{code-cell}
function misfit(x)
    V, Km = x   # rename components for clarity
    return @. V * s / (Km + s) - w
end
```

```{code-cell}
function misfitjac(x)
    V, Km = x   # rename components for clarity
    J = zeros(m, 2)
    J[:, 1] = @. s / (Km + s)              # dw/dV
    J[:, 2] = @. -V * s / (Km + s)^2         # dw/d_Km
    return J
end
```

```{code-cell}
x₁ = [1, 0.75]
x = FNC.newtonsys(misfit, misfitjac, x₁)

@show V, Km = x[end]  # final values
```

```{code-cell}
model(s) = V * s / (Km + s)
plot!(model, 0, 6, label="nonlinear fit")
```

```{math}
:enumerated: false
\frac{1}{w} = \frac{\alpha}{s} + \beta = \alpha \cdot s^{-1} + \beta
```


$$f_i([\alpha,\beta]) = \left(\alpha \cdot \frac{1}{s_i} + \beta\right) - \frac{1}{w_i}$$

```{code-cell}
A = [s .^ (-1) s .^ 0]
u = 1 ./ w
α, β = A \ u
```


```{code-cell}
linmodel(x) = 1 / (β + α / x)
plot!(linmodel, 0, 6, label="linearized fit")
```

