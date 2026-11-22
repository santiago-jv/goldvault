"""Require a release tag matching Flutter's declared version."""
import os
import re
from pathlib import Path


def validate_version(pubspec, tag):
    match = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+([1-9]\d*)\s*$', pubspec, re.MULTILINE)
    if not match:
        raise ValueError('pubspec.yaml must declare version X.Y.Z+BUILD with a positive build number')
    expected = f'v{match.group(1)}'
    if tag != expected:
        raise ValueError(f'Release tag must be {expected}, got {tag!r}')
    return expected


if __name__ == '__main__':
    print(validate_version(Path('pubspec.yaml').read_text(), os.environ['RELEASE_TAG']))
