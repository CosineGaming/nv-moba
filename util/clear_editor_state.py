#!/usr/bin/python3
from pathlib import Path

# current working directory
cwd = Path.cwd()

for path in cwd.glob('**/*.tscn'):
    result = []

    with path.open() as f:
        for line in f.readlines():
            if line.startswith('_sections_unfolded'):
                # Skip lines that start with _sections_unfolded
                # This is a list of sections of each node that are unfolded in the inspector.
                if result[-1] == '\n':
                    # Remove previous line if it's empty
                    # _sections_unfolded also adds an empty line if it is the only value of a node.
                    result.pop()
                continue
            elif line.startswith('editor/display_folded'):
                # Skip lines that start with editor/display_folded
                # This is added to nodes that are folded in the scene tree.
                continue
            elif line.startswith('[node') and 'parent=' not in line:
                # Root node, remove 'index="0"'
                # This is added to root nodes of scenes that are open in the editor.
                result.append(line.replace(' index="0"', ''))
            elif line.startswith('rect_clip_content = false'):
                continue
            else:
                # Add line as is
                result.append(line)

    with path.open('w') as f:
        f.writelines(result)

