using Printf

const REPO_ROOT = dirname(@__DIR__)
const LANGS = ["julia", "matlab", "python"]

# Directive name → pattern to match on a fence-opening line
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

# Index into lines where the YAML frontmatter ends (exclusive)
function body_start(lines)
    (isempty(lines) || lines[1] != "---") && return 1
    for i in 2:lastindex(lines)
        (lines[i] == "---" || lines[i] == "...") && return i + 1
    end
    return lastindex(lines) + 1
end

function count_file(lines)
    body = @view lines[body_start(lines):end]
    counts = Dict{String,Int}()

    # Directive counts: look at every fence-opening line in the body.
    # Fence-opening lines start with backticks or colons; content lines don't.
    # This intentionally counts nested directives (e.g., {math} inside {prf:theorem}).
    for (name, pattern) in DIRECTIVE_CHECKS
        counts[name] = count(body) do line
            (startswith(line, "`") || startswith(line, ":")) && contains(line, pattern)
        end
    end

    # tab-set orphan count (should be 0 in separated files)
    counts["tab-set"] = count(body) do line
        (startswith(line, "`") || startswith(line, ":")) && contains(line, "{tab-set}")
    end

    # Heading counts: only lines that are NOT inside any fence block.
    # This prevents code-cell init content (e.g., Python "# comment" lines) from
    # being mistaken for headings.
    #
    # Two subtleties handled here:
    # 1. Closing fences may have 0–3 spaces of leading indentation (valid Markdown),
    #    so the regex allows for that rather than anchoring to column 0.
    # 2. A fence line with content after the markers (e.g., ```{math}) is always
    #    an opener; only a line whose markers are followed by nothing is a closer.
    #    This prevents ```{math} from accidentally popping an earlier opener.
    # 3. findlast with exact match lets a closing fence implicitly close unclosed
    #    inner fences of different lengths (e.g., `````  closing both a ````
    #    tab-item and the enclosing `````  tab-set).
    h1 = h2 = h3 = 0
    stack = Tuple{Char,Int}[]

    for line in body
        m = match(r"^ {0,3}([`]{3,}|[:]{3,})(.*)", line)
        if m !== nothing
            fence, rest = m.captures[1], strip(m.captures[2])
            fc, fl = fence[1], length(fence)
            if isempty(rest)
                idx = findlast(==((fc, fl)), stack)
                if idx !== nothing
                    resize!(stack, idx - 1)
                else
                    push!(stack, (fc, fl))  # unmatched closer: treat as opener
                end
            else
                push!(stack, (fc, fl))      # has content: always an opener
            end
        elseif isempty(stack)
            startswith(line, "# ")   && (h1 += 1)
            startswith(line, "## ")  && (h2 += 1)
            startswith(line, "### ") && (h3 += 1)
        end
    end

    counts["h1"] = h1
    counts["h2"] = h2
    counts["h3"] = h3
    return counts
end

const ALL_CHECKS = [first(c) for c in DIRECTIVE_CHECKS]
append!(ALL_CHECKS, ["h1", "h2", "h3"])

# ── Main comparison loop ────────────────────────────────────────────────────

struct Failure
    file::String
    lang::String
    check::String
    src::Int
    sep::Int
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
            src_counts = count_file(readlines(joinpath(src_dir, file)))

            for lang in LANGS
                sep_path = joinpath(REPO_ROOT, "separate", lang, rel)
                if !isfile(sep_path)
                    push!(missing_files, "  $lang: $rel")
                    continue
                end
                sep_counts = count_file(readlines(sep_path))

                for name in ALL_CHECKS
                    s, t = src_counts[name], sep_counts[name]
                    s == t ? (n_pass += 1) : push!(failures, Failure(rel, lang, name, s, t))
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
                @printf("  %-8s  %-22s  source=%-3d  %s=%-3d\n",
                    f.lang, f.check, f.src, f.lang, f.sep)
            end
        end
    end
    println()
    @printf("✗  %d failure(s) in %d file(s). %d checks passed.\n",
        length(failures), length(seen_files), n_pass)
end
