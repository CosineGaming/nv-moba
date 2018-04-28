#!/usr/bin/python3
from pathlib import Path

# Current working directory
cwd = Path.cwd()

for path in cwd.glob('**/*.tscn'):
    result = []

    with path.open() as f:
        for line in f.readlines():
            if line.startswith('_sections_unfolded'):
                # Skip lines that start with _sections_unfolded
                continue
            elif line.startswith('[node') and 'parent=' not in line:
                # Root node, remove 'index="0"'
                result.append(line.replace(' index="0"', ''))
            else:
                # Add line as is
                result.append(line)

    with path.open('w') as f:
        f.writelines(result)