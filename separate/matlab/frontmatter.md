---
numbering:
  headings: false
kernelspec:
  display_name: MATLAB
  language: matlab
  name: jupyter_matlab_kernel
---
```{code-cell}
:tags: [remove-cell]
clear all
format short
set(0, 'defaultaxesfontsize', 12)
set(0, 'defaultlinelinewidth', 1.5)
set(0, 'defaultFunctionLinelinewidth', 1.5)
set(0, 'defaultscattermarkerfacecolor', 'flat')
gcf;
set(gcf, 'Position', [0 0 600 350])
addpath FNC-matlab
```


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
