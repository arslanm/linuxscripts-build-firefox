#!/bin/bash
    
    # Prompt for Release type
        clear
        echo "Mozilla Firefox packager for Debian-based Linux distributions"
        echo ""
        echo "Which release channel would you like to download?"
        echo ""
        echo "[1] Stable"
        echo "[2] Beta"
        echo ""
        echo "Please enter a number below:"
        read FXREL

    # Check for the latest version of Firefox
        if [ $FXREL = 1 ]
        then
            VERSION=${VERSION:-$(wget --spider -S --max-redirect 0 "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US" 2>&1 | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}')}
        else
        
            VERSION=${VERSION:-$(wget --spider -S --max-redirect 0 "https://download.mozilla.org/?product=firefox-beta-latest-ssl&os=linux64&lang=en-US" 2>&1 | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}')}
        fi

    # Set download URL
        FIREFOXPKG="https://download.mozilla.org/?product=firefox-${VERSION}&os=linux64&lang=en-US"

    # Download and extract the latest Firefox release package
        clear
        echo "Downloading Firefox $VERSION ..."
        wget --quiet --show-progress -O "firefox-$VERSION.tar.bz2" $FIREFOXPKG
        clear
        echo "Extracting files..."
        tar xvf firefox-$VERSION.tar.bz2
        rm firefox-$VERSION.tar.bz2

    # Move files to Debian package build directory
        mkdir firefox-${VERSION}_amd64
        mkdir -p firefox-${VERSION}_amd64/usr/share/applications
        mkdir -p firefox-${VERSION}_amd64/opt
        mv firefox firefox-${VERSION}_amd64/opt/firefox

    # Create .deb package of Firefox
        clear
        echo "Preparing to build Firefox installation package ..."
        mkdir firefox-${VERSION}_amd64/DEBIAN
        cp ./src/DEBIAN/* firefox-${VERSION}_amd64/DEBIAN/
        chmod +x firefox-${VERSION}_amd64/DEBIAN/postinst
        chmod +x firefox-${VERSION}_amd64/DEBIAN/postrm
        chmod 775 firefox-${VERSION}_amd64/DEBIAN/*

        printf "Version: $VERSION\n" | tee -a firefox-${VERSION}_amd64/DEBIAN/control

        printf "Installed-Size: " >> firefox-${VERSION}_amd64/DEBIAN/control | du -sx --exclude DEBIAN firefox-${VERSION}_amd64 | tee -a firefox-${VERSION}_amd64/DEBIAN/control
        sed -i 's/firefox-'$VERSION'_amd64//g' firefox-${VERSION}_amd64/DEBIAN/control

        cp ./src/launcher/firefox.desktop firefox-${VERSION}_amd64/usr/share/applications/firefox.desktop
    
        cd firefox-${VERSION}_amd64
        find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums
        cd ..

        dpkg-deb --build firefox-${VERSION}_amd64
        rm -rf firefox-${VERSION}_amd64

    # If --install argument was passed, install the built .deb package
        while test $# -gt 0
        do
            case "$1" in
                --install) 
                clear
                echo "Installing Firefox $VERSION ..."
                sudo dpkg -i firefox-${VERSION}_amd64.deb
                echo ""
                    ;;
            esac
            shift
        done

        exit 0