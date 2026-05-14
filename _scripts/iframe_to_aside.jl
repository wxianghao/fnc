#!/usr/bin/env julia
# Replaces <iframe id="kaltura_player"> tags with MyST aside+tab-set blocks.
# If the aside block already follows the iframe, just removes the iframe line.
#
# Usage:
#   julia _scripts/iframe_to_aside.jl                 # all chapter*/**/*.md
#   julia _scripts/iframe_to_aside.jl path/to/file.md ...

const REPO_ROOT = dirname(@__DIR__)

const IFRAME_RE = r"<iframe\s+id=\"kaltura_player\"\s+src='([^']+)'[^\n]*</iframe>"

function aside_block(src_url)
    url = replace(src_url, "&amp;" => "&")
    """::::{aside}

`````{tab-set}
````{tab-item} Julia
:sync: julia
:::{div}
:width: 100%
```{iframe} $url

```
:::
````

````{tab-item} MATLAB
:sync: matlab
````

````{tab-item} Python
:sync: python
````
`````

::::"""
end

function convert_file(path)
    content = read(path, String)
    !contains(content, "kaltura_player") && return

    # If aside block immediately follows the iframe, just drop the iframe line.
    new_content = replace(content, Regex(IFRAME_RE.pattern * raw"\n(?=::::)") => "")

    # Replace any remaining iframes with a generated aside block.
    new_content = replace(new_content, IFRAME_RE => function(s)
        url = match(IFRAME_RE, s).captures[1]
        aside_block(url)
    end)

    if new_content != content
        write(path, new_content)
        println("Converted: $path")
    end
end

files = if isempty(ARGS)
    chapter_dirs = filter(startswith("chapter"), readdir(REPO_ROOT))
    md_files = String[]
    for d in chapter_dirs
        dir = joinpath(REPO_ROOT, d)
        append!(md_files, filter(endswith(".md"), joinpath.(dir, readdir(dir))))
    end
    md_files
else
    collect(ARGS)
end

foreach(convert_file, files)
