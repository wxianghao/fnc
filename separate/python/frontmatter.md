---
numbering:
  headings: false
kernelspec:
  display_name: Python 3
  language: python
  name: python3
---
```{code-cell}
:tags: [remove-cell]
from numpy import *
from scipy import linalg
from scipy.linalg import norm
from matplotlib.pyplot import *
from prettytable import PrettyTable
from timeit import default_timer as timer
import sys
sys.path.append('fncbook/')
import fncbook as FNC

# This (optional) block is for improving the display of plots.
# from IPython.display import set_matplotlib_formats
# set_matplotlib_formats("svg","pdf")
# %config InlineBackend.figure_format = 'svg'
rcParams["figure.figsize"] = [7, 4]
rcParams["lines.linewidth"] = 2
rcParams["lines.markersize"] = 4
rcParams['animation.html'] = "jshtml"  # or try "html5"
```


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
