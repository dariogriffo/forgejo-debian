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

build_architecture() {
    local build_arch=$1

    if [ ! -f "$build_arch/forgejo" ]; then
        echo "❌ Binary for $build_arch not found. Run build_debian.sh first."
        return 1
    fi

    echo "Building Ubuntu packages for architecture: $build_arch"

    declare -a arr=("jammy" "noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$FORGEJO_VERSION-${BUILD_VERSION}+${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "forgejo-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg FORGEJO_VERSION="$FORGEJO_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg FORGEJO_RELEASE="$build_arch"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "forgejo-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/forgejo_$FULL_VERSION.deb" - > "./forgejo_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./forgejo_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    echo "✅ Successfully built Ubuntu packages for $build_arch"
    return 0
}

if [ "$ARCH" = "all" ]; then
    echo "🚀 Building forgejo $FORGEJO_VERSION-$BUILD_VERSION for all supported architectures (Ubuntu)..."
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

    echo "🎉 All Ubuntu packages built successfully!"
    echo "Generated packages:"
    ls -la forgejo_*.deb
else
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
