using Printf

const REPO_ROOT = dirname(@__DIR__)

function get_lang_header(lang)
    if lang == "python"
        yaml = """
kernelspec:
  display_name: Python 3
  language: python
  name: python3
"""
        init = readlines(joinpath(REPO_ROOT, "python", "FNC_init.py"))
    elseif lang == "matlab"
        yaml = """
kernelspec:
  display_name: MATLAB
  language: matlab
  name: jupyter_matlab_kernel
"""
        init = replace.(readlines(joinpath(REPO_ROOT, "matlab", "FNC_init.m")), "FNC-matlab/" => "../FNC_matlab/")
    elseif lang == "julia"
        yaml = """
        kernelspec:
          display_name: Julia 1
          language: julia
          name: julia-1.12
        """
        init = readlines(joinpath(REPO_ROOT, "julia", "FNC_init.jl"))
    end
    return (; yaml, init)
end

function get_code_blocks(chap, lang)
    header = get_lang_header(lang)

    # read functions and demos contents
    code_file = readlines(joinpath(REPO_ROOT, lang, "chapter$chap.md"))
    func_start = something(findfirst(contains("## Functions"), code_file), length(code_file) + 1)
    example_start = something(findfirst(contains("## Examples"), code_file), length(code_file) + 1)

    blocks = Dict()
    idx = func_start + 1
    while idx < example_start
        fun_idx = findnext(contains(r"\(function-.*\)"), code_file, idx)
        @show fun_idx
        isnothing(fun_idx) && break
        tag = match(r"\((.*-.*)\)", code_file[fun_idx]).captures[1]
        drop_idx = findnext(contains("{dropdown}"), code_file, fun_idx)
        backticks = match(r"(`+){dropdown}", code_file[drop_idx]).captures[1]
        drop_end = findnext(contains(Regex("$backticks")), code_file, drop_idx+1)
        blocks[tag] = code_file[drop_idx+2:drop_end-1]
        idx = drop_end + 1
    end

    idx = example_start + 1
    while idx < length(code_file)
        exam_idx = findnext(contains(r"(demo-.*-)"), code_file, idx)
        isnothing(exam_idx) && break
        tag = match(r"\((.*)\)", code_file[exam_idx]).captures[1]
        println("Found demo tag: $tag")
        drop_idx = findnext(contains("{dropdown}"), code_file, exam_idx)
        backticks = match(r"(`+){dropdown}", code_file[drop_idx]).captures[1]
        drop_end = findnext(contains(Regex("$backticks")), code_file, drop_idx+1)
        blocks[tag] = code_file[drop_idx+2:drop_end-1]
        idx = drop_end + 1
    end
    return header, blocks
end

# only_files: when provided, process only those filenames and skip copying
# non-md files from dir (safe to use on the repo root).
function transfer_content(dir, new_dir, chap, lang; only_files=nothing)
    header = get_lang_header(lang)
    blocks = Dict()
    if chap > 0
        println("Getting code blocks for chapter $chap")
        _, blocks = get_code_blocks(chap, lang)
    end

    # fix up code includes
    if lang == "python"
        try
            fn = @sprintf("chapter%02d.py", chap)
            cp(joinpath(REPO_ROOT, "python", "fncbook", "fncbook", fn), joinpath(new_dir, fn); force=true)
        catch
        end
        for (key, val) in pairs(blocks)
            blocks[key] = replace.(val, "fncbook/fncbook/" => "")
        end
    elseif lang == "julia"
        try
            fn = @sprintf("chapter%02d.jl", chap)
            cp(joinpath(REPO_ROOT, "julia", "FNCFunctions", "src", fn), joinpath(new_dir, fn); force=true)
        catch
        end
        for (key, val) in pairs(blocks)
            blocks[key] = replace.(val, "FNCFunctions/src/" => "")
        end
    elseif lang == "matlab"
        cp(joinpath(REPO_ROOT, "matlab", "FNC-matlab"), joinpath(REPO_ROOT, "separate", "matlab", "FNC_matlab"); force=true)
        for (key, val) in pairs(blocks)
            blocks[key] = replace.(val, "FNC-matlab/" => "../FNC_matlab/")
        end
    end

    # transfer other files (skip when only_files is given — caller handles non-md assets)
    if isnothing(only_files)
        nonmd = filter(!endswith(".md"), readdir(dir))
        foreach(file -> cp(joinpath(dir, file), joinpath(new_dir, file); force=true), nonmd)
    end

    # process markdown files
    all_md = filter(endswith(".md"), readdir(dir))
    md_files = isnothing(only_files) ? all_md : filter(in(only_files), all_md)
    excerpt = []
    for file in md_files
        println("\nProcessing $file")
        file_path = joinpath(dir, file)
        md_content = readlines(file_path)
        open(joinpath(new_dir, file), "w") do f
            # write out the header, replacing any existing kernelspec with the
            # language-specific one.  Fires whenever the file has frontmatter.
            idx = findnext(startswith("---"), md_content, 2)
            if !isnothing(idx)
                write(f, "---\n")
                # Copy existing frontmatter, skipping any kernelspec: block
                # (it will be replaced by the language-specific yaml below).
                in_kernelspec = false
                for line in md_content[2:idx-1]
                    if startswith(line, "kernelspec:")
                        in_kernelspec = true
                    elseif in_kernelspec && (startswith(line, " ") || startswith(line, "\t"))
                        continue
                    else
                        in_kernelspec = false
                        write(f, line * "\n")
                    end
                end
                write(f, header.yaml * "---\n")
                write(f, "```{code-cell}\n:tags: [remove-cell]\n")
                foreach(line -> write(f, line * "\n"), header.init)
                write(f, "```\n\n")
                idx += 1
            else
                idx = 1
            end

            # work up to each tab set
            while idx < length(md_content)
                tab_idx = findnext(contains(r"([`:]+){tab-set}"), md_content, idx)
                isnothing(tab_idx) && break
                foreach(line -> write(f, line * "\n"), md_content[idx:tab_idx-1])
                backticks = match(r"([`:]+){tab-set}", md_content[tab_idx]).captures[1]
                tab_end = findnext(contains(Regex("$backticks")), md_content, tab_idx+1)
                excerpt = md_content[tab_idx:tab_end]
                @show tab_idx, tab_end

                # find the tab-item for the desired language
                item_idx = findfirst(contains(Regex("([`:]+){tab-item}.*$lang")), lowercase.(excerpt))
                item_ticks = match(r"([`:]+){tab-item}", excerpt[item_idx]).captures[1]
                item_end = findnext(contains(Regex("$item_ticks")), excerpt, item_idx + 1)
                @show item_idx, item_end
                embed_idx = findnext(contains(r"{embed}"), excerpt, item_idx + 1)
                if isnothing(embed_idx)
                    println("no embed found")
                    # just include raw content
                    foreach(excerpt[item_idx+1:item_end-1]) do line
                        !startswith(line, ":sync:") && write(f, line * "\n")
                    end
                else
                    println("embed at $embed_idx")
                    embed = match(r".*{embed}[ ]*#(.*)", excerpt[embed_idx])
                    tag = embed.captures[1]
                    foreach(line -> write(f, line * "\n"), blocks[tag])
                end
                idx = tab_end + 1
            end

            # write out the rest of the file
            foreach(line -> write(f, line * "\n"), md_content[idx:end])
        end
    end
end

##

for lang in ["julia", "matlab", "python"]
    println("\n===== Processing $lang =====")
    for chap in 1:13
        println("\nProcessing chapter $chap for $lang")
        dir = joinpath(REPO_ROOT, "chapter$chap")
        new_dir = joinpath(REPO_ROOT, "separate", lang, "chapter$chap")
        mkpath(new_dir)
        mkpath(joinpath(new_dir, "figures"))
        transfer_content(dir, new_dir, chap, lang)
    end

    println("\nProcessing appendix for $lang")
    dir = joinpath(REPO_ROOT, "appendix")
    new_dir = joinpath(REPO_ROOT, "separate", lang, "appendix")
    mkpath(new_dir)
    transfer_content(dir, new_dir, 0, lang)

    dir = REPO_ROOT
    new_dir = joinpath(REPO_ROOT, "separate", lang)
    for fn in ["home.md", "genindex.md", "refs.md", "FNC.bib", "_static", "frontmatter"]
        cp(joinpath(dir, fn), joinpath(new_dir, fn); force=true)
    end
    cp(joinpath(dir, lang, "setup.md"), joinpath(new_dir, "setup.md"); force=true)

    # Process root-level md files that contain tab-sets.
    # only_files avoids copying unrelated files from the repo root.
    for fn in ["usage.md"]
        isfile(joinpath(dir, fn)) || continue
        transfer_content(dir, new_dir, 0, lang; only_files=[fn])
    end

    # Copy pre-generated animation mp4 files from the language figures directory
    # into every chapter's figures directory.  MyST validates figure references
    # before executing notebooks, so these must exist even if execution will
    # regenerate them.  (mp4s are gitignored; duplication across chapters is fine.)
    lang_figures = joinpath(REPO_ROOT, lang, "figures")
    if isdir(lang_figures)
        for mp4_file in filter(endswith(".mp4"), readdir(lang_figures))
            for chap in 1:13
                dest = joinpath(new_dir, "chapter$chap", "figures", mp4_file)
                isdir(dirname(dest)) && cp(joinpath(lang_figures, mp4_file), dest; force=true)
            end
        end
    end

    if lang == "python"
        cp(joinpath(REPO_ROOT, "python", "roswelladj.mat"), joinpath(new_dir, "chapter8", "roswelladj.mat"); force=true)
        cp(joinpath(REPO_ROOT, "python", "voting.mat"), joinpath(new_dir, "chapter7", "voting.mat"); force=true)
    elseif lang == "julia"
        cp(joinpath(REPO_ROOT, "julia", "roswell.jld2"), joinpath(new_dir, "chapter8", "roswell.jld2"); force=true)
        cp(joinpath(REPO_ROOT, "julia", "smallworld.jld2"), joinpath(new_dir, "chapter8", "smallworld.jld2"); force=true)
        cp(joinpath(REPO_ROOT, "julia", "voting.jld2"), joinpath(new_dir, "chapter7", "voting.jld2"); force=true)
    elseif lang == "matlab"
        for chap in [4, 6, 12, 13]
            for fn in filter(contains(Regex("f$chap.*\\.m")), readdir(joinpath(REPO_ROOT, "matlab")))
                cp(joinpath(REPO_ROOT, "matlab", fn), joinpath(new_dir, "chapter$chap", fn); force=true)
            end
        end
        for chap in 2:13
            cp(joinpath(REPO_ROOT, "matlab", "redsblues.m"), joinpath(new_dir, "chapter$chap", "redsblues.m"); force=true)
        end
        cp(joinpath(REPO_ROOT, "matlab", "roswelladj.mat"), joinpath(new_dir, "chapter8", "roswelladj.mat"); force=true)
        cp(joinpath(REPO_ROOT, "matlab", "smallworld.mat"), joinpath(new_dir, "chapter8", "smallworld.mat"); force=true)
        cp(joinpath(REPO_ROOT, "matlab", "voting.mat"), joinpath(new_dir, "chapter7", "voting.mat"); force=true)
    end
end
