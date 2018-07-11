if [[ -z "$TARGET_ROOT" ]]; then
    export TARGET_ROOT=$1
fi;
export ARCH=x86_64


function die() {
    echo $@
    exit 1
}


# Configure and build a package
#
# As firsat parameter, this function accepts the build directory
# All remaining parameters are forwarded to ./configure
#
function configure_build() (
    # Note: this is purposely run in a subshell
    cd "$1" || exit 1
    shift
    ./configure --prefix="$TARGET_ROOT" $@ || exit 1
    make $MAKEOPTS || exit 1
    make install || exit 1
) >> build.log 2>&1


[[ -z "$TARGET_ROOT" ]] || die "Target root not specified!"

echo "preparing root"
mkdir -p "$TARGET_ROOT"/{bin,dev,etc,lib,sbin} \
    || die "Failed initially popoulating root!"


if [[ -n "$KERNEL_BUILD_DIR" ]]; then
    echo "building the kernel..."
    (
        [[ -d "$KERNEL_BUILD_DIR" ]] || exit 1
        cp kconfig "$KERNEL_BUILD_DIR/.config" || exit 1
        cd "$KERNEL_BUILD_DIR" || exit 1
        make $MAKEOPTS || exit 1
        make INSTALL_HDR_PATH="$TARGET_ROOT" headers_install || exit 1
    ) >> build.log 2>&1 || die "failed building the kernel!"
fi

if [[ -n "$MUSL_BUILD_DIR" ]]; then
    echo "building musl..."
    configure_build "$MUSL_BUILD_DIR" \
        --enable-visibility \
        --syslibdir="$TARGET_ROOT/lib" \
        || die "failed building musl!"
    echo "/lib" > "$TARGET_ROOT/etc/ld-musl-$ARCH.path"
fi

echo "setting up env for compilation with musl..."
source buildenv

if [[ -n "$BASH_BUILD_DIR" ]]; then
    echo "building bash..."
    configure_build "$BASH_BUILD_DIR" \
        --enable-static-link \
        --disable-largefile \
        --disable-nls \
        --disable-rpath \
        --without-bash-malloc \
        || die "failed building bash!"
fi

if [[ -n "$E2FSPROGS_BUILD_DIR" ]]; then
    echo "building e2fsprogs..."
    configure_build "$E2FSPROGS_BUILD_DIR" \
        --disable-testio-debug \
        --disable-tls \
        --disable-uuidd \
        --disable-mmp \
        --disable-tdb \
        --disable-nls \
        --disable-rpath \
        --disable-fuse2fs \
        || die "failed building e2fsprogs!"
fi

if [[ -n "$PAM_BUILD_DIR" ]]; then
    echo "building pam..."
    configure_build "$PAM_BUILD_DIR" \
        --disable-prelude \
        --enable-regenerate-docu \
        --disable-cracklib \
        --disable-selinux \
        --enable-db=no \
        --disable-nis \
        --disable-nls \
        --disable-rpath \
        || die "failed building pam!"
fi

echo "building utilities..."
(
    cd utils || exit 1
    export CFLAGS="$CFLAGS -static"
    make $MAKEOPTS || exit 1
    make install || exit 1
) >> build.log 2>&1 || die "failed building the utilities!"

