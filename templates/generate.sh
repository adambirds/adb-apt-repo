#!/bin/bash

# Template generator for directory index pages
generate_directory_index() {
    local template_file="$1"
    local output_file="$2"
    local title="$3"
    local heading="$4"
    local description="$5"
    local breadcrumb="$6"
    local content="$7"
    
    cp "$template_file" "$output_file"
    sed -i "s|{{TITLE}}|$title|g" "$output_file"
    sed -i "s|{{HEADING}}|$heading|g" "$output_file"
    sed -i "s|{{DESCRIPTION}}|$description|g" "$output_file"
    sed -i "s|{{BREADCRUMB}}|$breadcrumb|g" "$output_file"
    sed -i "s|{{CONTENT}}|$content|g" "$output_file"
}

# Generate content for directory listings
generate_content_list() {
    local base_dir="$1"
    local content=""
    
    # Add parent directory link if not root
    if [ "$base_dir" != "./" ] && [ "$base_dir" != "." ]; then
        content="<li><a href=\"../\">📁 ../</a><div class=\"description\">Parent directory</div></li>"
    fi
    
    # List directories first
    for item in "$base_dir"*/; do
        if [ -d "$item" ] && [ "$(basename "$item")" != ".git" ] && [ "$(basename "$item")" != ".github" ]; then
            name=$(basename "$item")
            content="$content<li><a href=\"$name/\">📁 $name/</a><div class=\"description\">Directory</div></li>"
        fi
    done
    
    # Then list files
    for item in "$base_dir"*; do
        if [ -f "$item" ] && [ "$(basename "$item")" != "index.html" ]; then
            name=$(basename "$item")
            if [[ "$name" == *.deb ]]; then
                content="$content<li><a href=\"$name\">📦 $name</a><div class=\"description\">Debian package</div></li>"
            elif [[ "$name" == *.gpg ]]; then
                content="$content<li><a href=\"$name\">🔑 $name</a><div class=\"description\">GPG signature</div></li>"
            elif [[ "$name" == "Packages"* ]]; then
                content="$content<li><a href=\"$name\">📄 $name</a><div class=\"description\">Package metadata</div></li>"
            elif [[ "$name" == "Release"* ]] || [[ "$name" == "InRelease" ]]; then
                content="$content<li><a href=\"$name\">📄 $name</a><div class=\"description\">Repository metadata</div></li>"
            else
                content="$content<li><a href=\"$name\">📄 $name</a><div class=\"description\">File</div></li>"
            fi
        fi
    done
    
    echo "$content"
}
