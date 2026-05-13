# Build and deploy scripts

All commands run from the repo root inside the pixi environment:

```
pixi run <command>
```

## Commands

### `separate`
Parses the tabbed source files in `chapter*/` and regenerates the standalone
language versions in `separate/julia/`, `separate/matlab/`, and
`separate/python/`. Run this whenever source content changes.

```
pixi run separate
```

### `verify`
Checks that the separated versions are structurally consistent with the source:
counts of math blocks, theorems, definitions, exercises, headings, etc. Only
shared content (outside tab-sets) is compared. Prints failures grouped by file;
silent on success.

```
pixi run verify
```

### `build`
Builds all four MyST sites (main + three language versions) with notebook
execution and assembles the output into `_site/`. The language sites are built
with `BASE_URL=/julia` (etc.) so asset paths work as subpaths of the main
domain.

```
pixi run build
```

### `deploy`
Pushes `_site/` to the `gh-pages` branch via `ghp-import`, setting the CNAME
to `fncbook.com`. Run after `build`.

```
pixi run deploy
```

### `release`
Full pipeline: runs `build`, then `deploy`, then creates and pushes a git tag.
Optionally pass a version string; defaults to today's date (`YYYY.MM.DD`).

```
pixi run release              # tags as vYYYY.MM.DD
pixi run release -- 2025.09   # tags as v2025.09
```

After releasing you can optionally attach a GitHub Release:

```
gh release create vYYYY.MM.DD --generate-notes
```

## Typical workflow

```
# 1. Edit source files in chapter*/
pixi run separate     # regenerate separate/
pixi run verify       # check for structural problems
pixi run build        # build all sites
pixi run deploy       # push to GitHub Pages

# Or all at once as a tagged release:
pixi run release
```

The `separate` step requires Julia. The `build` step executes notebooks, which
requires MATLAB (for the matlab site) and a running Julia kernel. MATLAB
execution uses the `jupyter-matlab-proxy` kernel; see the repo README if the
MATLAB kernel fails to start.
