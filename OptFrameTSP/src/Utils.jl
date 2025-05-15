function load_void_into_obj(pointer::Ptr{Cvoid}, type::Type)
    object = convert(Ptr{type}, pointer)
    return unsafe_load(object)
end

# Function to parse the file and extract coordinates
function parse_trp_file(::Type{T}, file_path::AbstractString) where {T}
    # Initialize empty arrays for x and y coordinates
    x_coordinates = T[]
    y_coordinates = T[]

    # Open the file for reading
    open(file_path, "r") do file
        # Read through each line of the file
        for line in eachline(file)
            # Check if the line starts with "NODE_COORD_SECTION"
            if line == "NODE_COORD_SECTION"
                # Start reading coordinates from the next line
                for coord_line in eachline(file)
                    # Split the line into parts
                    parts = split(coord_line)
                    # Break if we reach the end of the coordinates section
                    if isempty(parts) || length(parts) < 3
                        break
                    end
                    # Parse x and y coordinates, ignoring the first column
                    push!(x_coordinates, parse(T, parts[2]))
                    push!(y_coordinates, parse(T, parts[3]))
                end
                break  # Exit after processing the coordinates section
            end
        end
    end

    return (x_coordinates, y_coordinates)
end

parse_trp_file(file_path::AbstractString) = parse_trp_file(Float64, file_path)

function euclidean_distance(x1::T, y1::T, x2::T, y2::T)::T where {T}
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

