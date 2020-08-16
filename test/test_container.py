from internal import *

if __name__ == "__main__":
    s = Container(
        name='test',
        mounts=[
            Mount('/tank/media', not_empty=True),
            Mount('/home/andrei/test.jpg', is_file=True),
        ])
    print(str(s))
