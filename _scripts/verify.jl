using Printf

const REPO_ROOT = dirname(@__DIR__)
const LANGS = ["julia", "matlab", "python"]

const DIRECTIVE_CHECKS = [
    ("math",        "{math}"),
    ("definition",  "{prf:definition}"),
    ("theorem",     "{prf:theorem}"),
    ("example",     "{prf:example}"),
    ("algorithm",   "{prf:algorithm}"),
    ("observation", "{prf:observation}"),
    ("lemma",       "{prf:lemma}"),
    ("proof",       "{prf:proof}"),
    ("exercise",    "{exercise}"),
]

function body_start(lines)
    (isempty(lines) || lines[1] != "---") && return 1
    for i in 2:lastindex(lines)
        (lines[i] == "---" || lines[i] == "...") && return i + 1
    end
    return lastindex(lines) + 1
end

# Count directives, tab-set orphans, and headings in a single stateful pass.
#
# When source_mode=true (used for the root chapter files), directives that appear
# inside a {tab-set} block are excluded.  This matters because tab-sets hold
# language-specific content: the source has one copy per language while each
# separated file has only the relevant one.  Excluding them gives the count of
# "shared" content that must appear in every separated version.
#
# Fence tracking notes:
#  • A fence line with content after the markers is always an opener (e.g. ```{math}).
#    A line with only fence markers is a potential closer.  This prevents ```{math}
#    from being mistaken for a closer that pops an earlier opener.
#  • Closing fences may be indented up to 3 spaces (valid Markdown).
#  • findlast with exact (char, length) match lets a closer implicitly close
#    unclosed inner fences of different lengths (e.g. ````` closing an unclosed
#    ```` tab-item before closing the ````` tab-set).
function count_file(lines; source_mode=false)
    body = @view lines[body_start(lines):end]
    counts = Dict{String,Int}(k => 0 for (k, _) in DIRECTIVE_CHECKS)
    merge!(counts, Dict("tab-set" => 0, "h1" => 0, "h2" => 0, "h3" => 0))

    # fence_stack entries: (fc::Char, fl::Int, is_tabset::Bool)
    fence_stack = Tuple{Char,Int,Bool}[]
    tabset_depth = 0

    for line in body
        m = match(r"^ {0,3}([`]{3,}|[:]{3,})(.*)", line)
        if m !== nothing
            fence, rest = m.captures[1], strip(m.captures[2])
            fc, fl = fence[1], length(fence)

            if !isempty(rest)
                # Opener.  Record depth *before* incrementing so that the
                # tab-set opener itself is counted as shared content.
                depth_before = tabset_depth
                is_tabset = contains(rest, "{tab-set}")
                is_tabset && (tabset_depth += 1)
                push!(fence_stack, (fc, fl, is_tabset))

                if !source_mode || depth_before == 0
                    for (name, pattern) in DIRECTIVE_CHECKS
                        contains(rest, pattern) && (counts[name] += 1)
                    end
                    is_tabset && (counts["tab-set"] += 1)
                end

            else
                # Closer: pop back to and including the nearest matching opener.
                idx = findlast(e -> e[1] == fc && e[2] == fl, fence_stack)
                if idx !== nothing
                    for i in idx:lastindex(fence_stack)
                        fence_stack[i][3] && (tabset_depth -= 1)
                    end
                    resize!(fence_stack, idx - 1)
                else
                    push!(fence_stack, (fc, fl, false))  # unmatched: treat as opener
                end
            end

        elseif isempty(fence_stack)
            startswith(line, "# ")   && (counts["h1"] += 1)
            startswith(line, "## ")  && (counts["h2"] += 1)
            startswith(line, "### ") && (counts["h3"] += 1)
        end
    end

    return counts
end

const ALL_CHECKS = [first(c) for c in DIRECTIVE_CHECKS]
append!(ALL_CHECKS, ["h1", "h2", "h3"])

# ── Main comparison loop ────────────────────────────────────────────────────

struct Failure
    file::String
    lang::String
    check::String
    shared::Int   # source count outside tab-sets
    sep::Int      # separated file count
end

function run_checks()
    source_dirs = [(joinpath(REPO_ROOT, "chapter$n"), "chapter$n") for n in 1:13]
    push!(source_dirs, (joinpath(REPO_ROOT, "appendix"), "appendix"))

    failures = Failure[]
    missing_files = String[]
    n_pass = 0

    for (src_dir, rel_dir) in source_dirs
        isdir(src_dir) || continue
        for file in filter(endswith(".md"), readdir(src_dir))
            rel = joinpath(rel_dir, file)
            # Source counts exclude content inside tab-sets ("shared" content)
            src_counts = count_file(readlines(joinpath(src_dir, file)); source_mode=true)

            for lang in LANGS
                sep_path = joinpath(REPO_ROOT, "separate", lang, rel)
                if !isfile(sep_path)
                    push!(missing_files, "  $lang: $rel")
                    continue
                end
                sep_counts = count_file(readlines(sep_path))

                for name in ALL_CHECKS
                    s, t = src_counts[name], sep_counts[name]
                    # sep must be >= shared: the separated file should contain all
                    # shared content plus whatever was in its own tab-items.
                    t >= s ? (n_pass += 1) : push!(failures, Failure(rel, lang, name, s, t))
                end

                if sep_counts["tab-set"] > 0
                    push!(failures, Failure(rel, lang, "tab-set orphan", 0, sep_counts["tab-set"]))
                else
                    n_pass += 1
                end
            end
        end
    end

    return failures, missing_files, n_pass
end

failures, missing_files, n_pass = run_checks()

# ── Report ──────────────────────────────────────────────────────────────────

if !isempty(missing_files)
    println("Missing files:")
    foreach(println, missing_files)
    println()
end

if isempty(failures)
    @printf("✓  All %d checks passed.\n", n_pass)
else
    seen_files = unique(f.file for f in failures)
    for rel in seen_files
        println(rel)
        for f in filter(x -> x.file == rel, failures)
            if f.check == "tab-set orphan"
                @printf("  %-8s  %-22s  %d remaining\n", f.lang, f.check, f.sep)
            else
                @printf("  %-8s  %-22s  shared=%-3d  %s=%-3d\n",
                    f.lang, f.check, f.shared, f.lang, f.sep)
            end
        end
    end
    println()
    @printf("✗  %d failure(s) in %d file(s). %d checks passed.\n",
        length(failures), length(seen_files), n_pass)
end
