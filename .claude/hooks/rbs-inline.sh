#!/bin/bash

# Hook input is JSON from stdin
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')

cd "$CLAUDE_PROJECT_DIR" || exit 1

# Handle Edit or Write tools
if [[ "$tool_name" == "Edit" || "$tool_name" == "Write" ]]; then
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

    if [[ ! "$file_path" =~ \.rb$ ]]; then
        exit 0
    fi

    if [[ ! "$file_path" =~ /lib/ ]]; then
        exit 0
    fi

    echo "Running rbs-inline for $file_path..." >&2

    if ! "$CLAUDE_PROJECT_DIR/bin/rbs-inline" --opt-out --output=sig/ "$file_path" >&2; then
        echo "Warning: RBS generation failed for $file_path" >&2
        exit 0
    fi

    echo "RBS generation completed." >&2
    exit 0
fi

# Handle Bash tool for mv command
if [[ "$tool_name" == "Bash" ]]; then
    command=$(echo "$input" | jq -r '.tool_input.command // ""')

    # Check if this is a mv command
    if [[ ! "$command" =~ ^[[:space:]]*(mv|git\ mv)[[:space:]] ]]; then
        exit 0
    fi

    # Extract source and destination paths from mv command
    # Handle common patterns: mv src dest, git mv src dest
    # Remove the mv/git mv prefix and get the paths
    paths=$(echo "$command" | sed -E 's/^[[:space:]]*(git[[:space:]]+)?mv[[:space:]]+//')

    # Split into source and destination (simple case, space-separated)
    # This handles: mv old.rb new.rb, mv old.rb dir/
    source_path=$(echo "$paths" | awk '{print $1}')
    dest_path=$(echo "$paths" | awk '{print $2}')

    # Check if source was a .rb file in lib/
    if [[ ! "$source_path" =~ \.rb$ ]] || [[ ! "$source_path" =~ lib/ ]]; then
        exit 0
    fi

    echo "Detected mv of Ruby file in lib/: $source_path -> $dest_path" >&2

    # Calculate the corresponding .rbs file path for the source
    # Convert lib/path/to/file.rb to sig/path/to/file.rbs
    source_rbs=$(echo "$source_path" | sed -E 's|^(.*/)?lib/|sig/|; s|\.rb$|.rbs|')

    # Remove the old .rbs file if it exists
    if [[ -f "$source_rbs" ]]; then
        echo "Removing old RBS file: $source_rbs" >&2
        rm -f "$source_rbs"
    fi

    # Determine the new .rb file path
    # If dest is a directory, append the source filename
    if [[ -d "$dest_path" ]]; then
        dest_file="$dest_path/$(basename "$source_path")"
    else
        dest_file="$dest_path"
    fi

    # Check if the destination is in lib/
    if [[ ! "$dest_file" =~ lib/ ]]; then
        echo "Destination is not in lib/, skipping RBS generation" >&2
        exit 0
    fi

    # Generate RBS for the new file
    if [[ -f "$dest_file" ]]; then
        echo "Running rbs-inline for $dest_file..." >&2

        if ! "$CLAUDE_PROJECT_DIR/bin/rbs-inline" --opt-out --output=sig/ "$dest_file" >&2; then
            echo "Warning: RBS generation failed for $dest_file" >&2
            exit 0
        fi

        echo "RBS generation completed." >&2
    fi

    exit 0
fi

exit 0
