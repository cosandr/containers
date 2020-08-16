import re
import subprocess
from typing import List

from packaging import version


def get_install_list() -> List[str]:
    """Get all available pyenv versions to install"""
    versions = []
    s = subprocess.run(['pyenv', 'install', '--list'], check=True, text=True, capture_output=True)
    # Skip first line 'Available versions:'
    for line in s.stdout.splitlines()[1:]:
        versions.append(line.strip())
    return versions


def get_installed_list() -> List[str]:
    """List of already installed versions"""
    versions = []
    s = subprocess.run(['pyenv', 'versions', '--bare', '--skip-aliases'], check=True, text=True, capture_output=True)
    for line in s.stdout.splitlines():
        versions.append(line.strip())
    return versions


def install_python(install_version: str = 'latest'):
    """pyenv install"""
    re_stable_version = re.compile(r'^\s*(\d\.\d+(?:\.)?(?:\d+)?)\s*$')
    print('Getting available versions')
    avail_versions = get_install_list()
    if install_version == 'latest':
        print('Looking for the latest stable version')
        tmp = None
        for v in avail_versions:
            if re_stable_version.match(v):
                v_parsed = version.parse(v)
                if not tmp or v_parsed > tmp:
                    tmp = v_parsed
        install_version = str(tmp)
    else:
        if not install_version in avail_versions:
            raise RuntimeError(f'{install_version} not available, check \'pyenv install --list\'')
    installed = get_installed_list()
    if install_version in installed:
        print(f'Python {install_version} is already installed')
        return
    subprocess.run(['pyenv', 'install', install_version], check=True)
