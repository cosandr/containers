import os
from dataclasses import dataclass


@dataclass
class Mount:
    src: str
    dst: str = ''
    is_file: bool = None
    is_volume: bool = False
    not_empty: bool = False

    def __str__(self):
        opts = []
        if self.is_file:
            opts.append('file')
        if self.is_volume:
            opts.append('volume')
        if self.not_empty:
            opts.append('not_empty')
        ret_str = f'- {self.src}'
        if self.dst:
            ret_str += f' -> {self.dst}'
        ret_str += f' ({",".join(opts)})'
        return ret_str

    def __post_init__(self):
        if self.is_file is None:
            self.is_file = os.path.isfile(self.src)

    def to_systemd(self):
        if self.is_volume:
            return ''
        if self.not_empty and not self.is_file:
            return f'ConditionDirectoryNotEmpty={self.src}'
        return f'ConditionPathExists={self.src}'
