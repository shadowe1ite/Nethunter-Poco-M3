#/bin/bash
set -e

[ ! -e "scripts/packaging/pack.sh" ] && git submodule init && git submodule update
[ ! -e "toolchain" ] && echo "Make toolchain avaliable at $(pwd)/toolchain" && exit

# Patch for 4.14
sed -i 's/#ifdef CONFIG_KPROBES/#if 0/g' KernelSU/kernel/ksu.c

export KBUILD_BUILD_USER=shadow
export KBUILD_BUILD_HOST=elite

PATH=$PWD/toolchain/bin:$PATH

rm -rf out
make O=out CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 -j$(nproc) vendor/nh_defconfig #chime_defconfig
scripts/config --file out/.config --disable MODULE_SIG --disable MODULE_SIG_FORCE --disable MODULE_SIG_ALL --disable MODULE_SIG_SHA512 --disable MODULE_SIG_KEY 2>/dev/null || true
make O=out CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 -j$(nproc) olddefconfig
grep -Eq '^CONFIG_MODULE_SIG(_FORCE|_ALL)?=y' out/.config && { echo "MODULE_SIG masih aktif di out/.config"; exit 1; }
toilet -f future --filter border:metal BUILD START | lolcat
make O=out CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 -j$(nproc) 2>&1 | tee ./out/build.log
toilet -f future --filter border:metal BUILD END | lolcat
