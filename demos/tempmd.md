
# Section 6.8

## Example 6.8.1

+++

We'll measure the error at the time $t=1$.

```{code-cell}
using PrettyTables
du_dt(u, t) = u
û = exp
a, b = 0.0, 1.0;
n = [5, 10, 20, 40, 60]
err = []
t, u = [], []
for n in n
    h = (b - a) / n
    t = [a + i * h for i in 0:n]
    u = [1; û(h); zeros(n - 1)]
    f_val = [du_dt(u[1], t[1]); zeros(n)]
    for i in 2:n
        f_val[i] = du_dt(u[i], t[i])
        u[i+1] = -4 * u[i] + 5 * u[i-1] + h * (4 * f_val[i] + 2 * f_val[i-1])
    end
    push!(err, abs(û(b) - u[end]))
end
pretty_table((n=n, h=(b - a) ./ n, err=err); 
    column_labels=["n", "h", "error at t=1"], backend=:html)
```

The error starts out promisingly, but things explode from there. A graph of the last numerical attempt yields a clue.

```{code-cell}
using Plots, LaTeXStrings
plot(t, abs.(u);
    m=3,  label="",
    xlabel=L"t",  yaxis=(:log10, L"|u(t)|"), title="LIAF solution")
```

It's clear that the solution is growing exponentially in time.
