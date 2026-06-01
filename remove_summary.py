#!/usr/bin/env python3
"""Remove all lines starting with /// from C# files."""

import os
from pathlib import Path

def remove_triple_slash_comments(folder: str) -> list[tuple[str, int]]:
    """Remove /// comment lines from all .cs files in folder."""
    results = []
    folder_path = Path(folder)
    
    for cs_file in folder_path.rglob("*.cs"):
        lines = cs_file.read_text(encoding='utf-8').splitlines()
        original_count = len(lines)
        
        # Filter out lines that start with /// (with optional leading whitespace)
        new_lines = [line for line in lines if not line.lstrip().startswith("///")]
        
        if len(new_lines) != original_count:
            cs_file.write_text('\n'.join(new_lines) + '\n', encoding='utf-8')
            results.append((str(cs_file), original_count - len(new_lines)))
    
    return results

if __name__ == "__main__":
    folder = "/home/i/GitHub/BovineLabs/Packages/BovineLabs.Timeline.Grid.Influence"
    results = remove_triple_slash_comments(folder)
    
    if results:
        print(f"Removed /// comments from {len(results)} files:")
        for path, count in results:
            print(f"  {path}: {count} lines removed")
    else:
        print("No /// comment lines found.")