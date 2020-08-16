import grp
import os
import pwd
from dataclasses import dataclass
from typing import NamedTuple


@dataclass
class Group:
    name: str
    gid: int

    def __str__(self):
        return f'{self.name} [{self.gid}]'


@dataclass
class User:
    name: str
    uid: int

    def __str__(self):
        return f'{self.name} [{self.uid}]'


class IP(NamedTuple):
    four: str
    six: str


@dataclass
class OsUser:
    name: str
    uid: int
    group: str
    gid: int
    home: str

    @classmethod
    def from_username(cls, name: str):
        user_db = pwd.getpwnam(name)
        group_db = grp.getgrgid(user_db.pw_gid)
        return cls(
            name=user_db.pw_name,
            uid=user_db.pw_uid,
            group=group_db.gr_name,
            gid=group_db.gr_gid,
            home=os.path.expanduser(f'~{name}')
        )
