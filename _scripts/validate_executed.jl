using JSON

"""
    find_objects(data)

# Arguments
- `data`: The JSON data structure

# Returns
- `Vector{Dict}`: Array of dictionaries that have key=value
"""
function find_objects(data, key="output_type", value="execute_result")
    results = Vector{typeof(data)}()

    # Helper function to recursively traverse the data structure
    function traverse(obj)
        if isa(obj, JSON.Object)
            # Check if this dictionary has type="output"
            if haskey(obj, key) && obj[key] == value
                push!(results, obj)
            end

            # Recursively traverse all values in the dictionary
            for (key, value) in obj
                traverse(value)
            end

        elseif isa(obj, Array)
            # Recursively traverse all elements in the array
            for item in obj
                traverse(item)
            end
        end
        # For primitive types (String, Number, Bool, etc.), do nothing
    end

    traverse(data)
    return results
end

# Validate that HTML build files have output content.

# number of intentional errors in some files
intended = Dict("matrices.json" => 3, "structure.json" => 3, "linear-systems.json" => 2)

println("Top level repo: ")

root = joinpath("_build", "html")
found = Dict()
files = filter(endswith(".json"), readdir(root))
println("Checking $(length(files)) files...")
for fname in files
    json = JSON.parsefile(joinpath(root, fname))
    for lang in ["julia", "python", "matlab"]
        for obj in find_objects(json, "sync", lang)
            for er in find_objects(obj, "output_type", "error")
                get!(found, fname, Dict())[lang] = er["evalue"]
            end
        end
    end
    for obj in find_objects(json, "sync", "matlab")
        for er in find_objects(obj, "name", "stderr")
            if !contains(er["text"], "Warning:")  # ignore warnings
                get!(found, fname, Dict())["matlab"] = er["text"]
            end
        end
    end
end

println("------")
for (key, value) in found
    println("\n- File: $key")
    if haskey(intended, key)
        if length(value) == intended[key]
            println("  Found expected number of errors: $(length(value))")
            continue
        end
    end
    for (lang, err) in value
        println("  $lang error: $err")
    end
    println()
end


println("\nSeparate trees:")

for lang in ["julia", "python", "matlab"]
    local root = joinpath("separate", lang, "_build", "html")
    local found = Dict()
    local files = filter(endswith(".json"), readdir(root))
    println("\n$lang\n------")
    for fname in files
        json = JSON.parsefile(joinpath(root, fname))
        for er in find_objects(json, "output_type", "error")  # for python and julia
            push!(get!(found, fname, []), er["evalue"])
        end
        (lang == "matlab") || continue
        for er in find_objects(json, "name", "stderr")  # for matlab
            if !contains(er["text"], "Warning:")  # ignore warnings
                push!(get!(found, fname, []), er["text"])
            end
        end
    end

    for (key, value) in found
        println("\n- File: $key")
        foreach(println, value)
    end
end