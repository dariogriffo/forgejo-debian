FORGEJO_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}

if [ -z "$FORGEJO_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <forgejo_version> <build_version> [architecture]"
    echo "Example: $0 15.0.2 1 arm64"
    echo "Example: $0 15.0.2 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, armhf, arm64, all"
    exit 1
fi

# Returns the Forgejo download suffix for a given Debian architecture
get_forgejo_release() {
    local arch=$1
    case "$arch" in
        "amd64")  echo "linux-amd64" ;;
        "armhf")  echo "linux-arm-6" ;;
        "arm64")  echo "linux-arm64" ;;
        *)        echo "" ;;
    esac
}

# Downloads the Forgejo binary for the given arch into a local directory
download_binary() {
    local build_arch=$1
    local release_suffix

    release_suffix=$(get_forgejo_release "$build_arch")
    if [ -z "$release_suffix" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, armhf, arm64"
        return 1
    fi

    if [ -f "$build_arch/forgejo" ]; then
        echo "  Binary for $build_arch already downloaded, skipping."
        return 0
    fi

    mkdir -p "$build_arch"

    local url="https://codeberg.org/forgejo/forgejo/releases/download/v${FORGEJO_VERSION}/forgejo-${FORGEJO_VERSION}-${release_suffix}"
    echo "  Downloading $url"
    if ! wget -q -O "$build_arch/forgejo" "$url"; then
        echo "❌ Failed to download Forgejo binary for $build_arch"
        rm -f "$build_arch/forgejo"
        return 1
    fi
}

build_architecture() {
    local build_arch=$1

    echo "Building Debian packages for architecture: $build_arch"

    if ! download_binary "$build_arch"; then
        return 1
    fi

    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$FORGEJO_VERSION-${BUILD_VERSION}+${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "forgejo-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg FORGEJO_VERSION="$FORGEJO_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg FORGEJO_RELEASE="$build_arch"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "forgejo-$dist-$build_arch")"
        if ! docker cp "$id:/forgejo_$FULL_VERSION.deb" - > "./forgejo_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./forgejo_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    echo "✅ Successfully built Debian packages for $build_arch"
    return 0
}

if [ "$ARCH" = "all" ]; then
    echo "🚀 Building forgejo $FORGEJO_VERSION-$BUILD_VERSION for all supported architectures (Debian)..."
    echo ""

    ARCHITECTURES=("amd64" "armhf" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All Debian packages built successfully!"
    echo "Generated packages:"
    ls -la forgejo_*.deb
else
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
