import signal
from typing import List

from .os import User, Group
from .mount import Mount


class Container:
    def __init__(self, name, run_user=None, run_group=None, mounts=None, after_units=None, requires_units=None, after_containers=None,
                 requires_containers=None, stop_signal=None):
        self.name: str = name
        self.stop_signal: signal.Signals = stop_signal
        if not self.stop_signal:
            self.stop_signal = signal.SIGTERM
        self.run_user: User = run_user
        self.run_group: Group = run_group
        if not self.run_user:
            self.run_user = User(name='root', uid=0)
        if not self.run_group:
            self.run_group = Group(name='root', gid=0)
        self.mounts: List[Mount] = mounts if mounts else []
        self.after_units = after_units if after_units else []
        self.requires_units = requires_units if requires_units else []
        self.after_containers = after_containers if after_containers else []
        self.requires_containers = requires_containers if requires_containers else []

    def __str__(self):
        ret_str = f'--> {self.name}\nRun as user {self.run_user}, group {self.run_group}\nStop signal {self.stop_signal.name}'
        if self.mounts:
            ret_str += f', {len(self.mounts)} mounts'
            for m in self.mounts:
                ret_str += f'\n{m}'
        return ret_str
