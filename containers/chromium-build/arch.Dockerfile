FROM archlinux/base

RUN pacman --noconfirm --needed -Syu sudo base-devel git && \
    echo 'makepkg config: march=native' && \
    sed -i -re 's/(^C(XX)?FLAGS=")-march=x86-64/\1-march=native/g' /etc/makepkg.conf && \
    echo 'makepkg config: use all threads' && \
    sed -i 's/^#MAKEFLAGS.*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf && \
    echo 'makepkg config: parallel zstd compression' && \
    sed -i 's/^COMPRESSZST.*/COMPRESSZST=(zstd -c -z -q - --threads=0)/' /etc/makepkg.conf && \
    echo 'sudoers: no password for wheel group' && \
    sed -i '0,/^# %wheel ALL=(ALL) NOPASSWD: ALL/s//%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers && \
    echo 'user: Create abc user and group' && \
    groupadd --gid=1000 abc && useradd --create-home --uid=1000 --gid=1000 --groups wheel abc && \
    sudo -u abc git clone https://aur.archlinux.org/chromium-vaapi.git /home/abc/chromium-vaapi && \
    cd /home/abc/chromium-vaapi && \
    sudo -u abc makepkg -so --noconfirm --needed

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "bash" ]
