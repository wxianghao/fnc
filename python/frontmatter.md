---
kernelspec:
  display_name: Python 3
  language: python
  name: FNC
numbering:
  headings: false
---

# Frontmatter

## Usage

(demo-usage-python)=

``````{dropdown} @demo-usage
:open:

```{code-cell}
import numpy as np
print("Welcome to Python! Did you know that random numbers can be used to approximate pi? Look:")
x = np.random.rand(2, 10000)
hits = (x**2).sum(axis=0) < 1
approx = 4 * hits.sum() / x.shape[1]
print(f"π ≈ {approx:.4f}")
```
``````
