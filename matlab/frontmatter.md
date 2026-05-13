---
kernelspec:
  display_name: MATLAB
  language: matlab
  name: jupyter_matlab_kernel
numbering:
  headings: false
---

# Frontmatter

## Usage

(demo-usage-matlab)=

``````{dropdown} @demo-usage
:open:
```{code-cell}
disp("Welcome to MATLAB! Did you know that random numbers can be used to approximate pi? Look:")
x = rand(2, 10000);
hits = x(1, :) .^2 + x(2, :).^2 < 1;
approx = 4 * sum(hits) / size(x, 2)
```
``````
