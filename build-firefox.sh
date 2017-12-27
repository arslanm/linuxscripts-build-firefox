#!/bin/bash

    # Prompt for architecture and release channel
        clear
        echo "Mozilla Firefox packager for Debian-based Linux distributions"
        echo ""
        echo "Which architecture would you like to target?"
        echo ""
        echo "[1] i386  (32-bit)"
        echo "[2] amd64 (64-bit)"
        echo ""
        echo "Please enter a number below:"
        echo ""
        read PKGARCH
        echo ""
        echo "Which release channel would you like to download?"
        echo ""
        echo "[1] Firefox Quantum Stable channel release"
        echo "[2] Firefox Quantum Beta channel release"
        echo "[3] Firefox Developer Edition"
        echo ""
        echo "Please enter a number below:"
        read FXREL

    # Set variables for user options
        # Architecture
            if [ $PKGARCH = 1 ]; then
                FXOS=linux
                FXARCH=i686
                DEBARCH=i386
            elif [ $PKGARCH = 2 ]; then
                FXOS=linux64
                FXARCH=x86_64
                DEBARCH=amd64
            fi

        # Release channel
            if [ $FXREL = 1 ]; then
                FXCHANNEL=firefox-latest-ssl
                FXDIR=firefox
            elif [ $FXREL = 2 ]; then
                FXCHANNEL=firefox-beta-latest-ssl
                FXDIR=firefox
            elif [ $FXREL = 3 ]; then
                FXCHANNEL=firefox-devedition-latest-ssl
                FXDIR=devedition
            fi

    # Check for the latest version of Firefox
        VERSION=${VERSION:-$(wget --spider -S --max-redirect 0 "https://download.mozilla.org/?product=${FXCHANNEL}&os=${FXOS}&lang=en-US" 2>&1 | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}')}

    # Set download URL
        FIREFOXPKG="https://download-installer.cdn.mozilla.net/pub/${FXDIR}/releases/${VERSION}/linux-${FXARCH}/en-US/firefox-${VERSION}.tar.bz2"

    # Download and extract the latest Firefox release package
        clear
        echo "Downloading Firefox $VERSION ..."
        wget --quiet --show-progress -O "firefox-$VERSION.tar.bz2" $FIREFOXPKG
        clear
        echo "Extracting files..."
        tar xvf firefox-$VERSION.tar.bz2
        rm firefox-$VERSION.tar.bz2

    # Move files to Debian package build directory
        mkdir firefox-${VERSION}_${DEBARCH}
        mkdir -p firefox-${VERSION}_${DEBARCH}/usr/share/applications
        mkdir -p firefox-${VERSION}_${DEBARCH}/opt
        mv firefox firefox-${VERSION}_${DEBARCH}/opt/firefox

    # Create .deb package of Firefox
        clear
        echo "Preparing to build Firefox installation package ..."
        mkdir firefox-${VERSION}_${DEBARCH}/DEBIAN
        cp ./src/DEBIAN/* firefox-${VERSION}_${DEBARCH}/DEBIAN/
        chmod +x firefox-${VERSION}_${DEBARCH}/DEBIAN/postinst
        chmod +x firefox-${VERSION}_${DEBARCH}/DEBIAN/postrm
        chmod 775 firefox-${VERSION}_${DEBARCH}/DEBIAN/*

        printf "Architecture: $DEBARCH\n" | tee -a firefox-${VERSION}_${DEBARCH}/DEBIAN/control
        printf "Version: 1:$VERSION+b0~mozilla\n" | tee -a firefox-${VERSION}_${DEBARCH}/DEBIAN/control

        printf "Installed-Size: " >> firefox-${VERSION}_${DEBARCH}/DEBIAN/control | du -sx --exclude DEBIAN firefox-${VERSION}_${DEBARCH} | tee -a firefox-${VERSION}_${DEBARCH}/DEBIAN/control
        sed -i 's/firefox-'$VERSION'_'$DEBARCH'//g' firefox-${VERSION}_${DEBARCH}/DEBIAN/control

        cp ./src/launcher/firefox.desktop firefox-${VERSION}_${DEBARCH}/usr/share/applications/firefox.desktop
    
        cd firefox-${VERSION}_${DEBARCH}
        find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums
        cd ..

        dpkg-deb --build firefox-${VERSION}_${DEBARCH}
        rm -rf firefox-${VERSION}_${DEBARCH}

    # If --install argument was passed, install the built .deb package
        while test $# -gt 0
        do
            case "$1" in
                --install) 
                clear
                echo "Installing Firefox $VERSION ..."
                sudo dpkg -i firefox-${VERSION}_${DEBARCH}.deb
                echo ""
                    ;;
            esac
            shift
        done

        exit 0
