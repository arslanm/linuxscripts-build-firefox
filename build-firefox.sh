#!/bin/bash
        CPUARCH=`uname -m`

    if [ "$CPUARCH" = "x86_64" ]; then
        FXARCH=linux64
        DEBARCH=amd64
    else
        FXARCH=linux
        DEBARCH=i386
    fi

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
            VERSION=${VERSION:-$(wget --spider -S --max-redirect 0 "https://download.mozilla.org/?product=firefox-latest-ssl&os=${FXARCH}&lang=en-US" 2>&1 | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}')}
        else
        
            VERSION=${VERSION:-$(wget --spider -S --max-redirect 0 "https://download.mozilla.org/?product=firefox-beta-latest-ssl&os=${FXARCH}&lang=en-US" 2>&1 | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}')}
        fi

    # Set download URL
        FIREFOXPKG="https://download.mozilla.org/?product=firefox-${VERSION}&os=${FXARCH}&lang=en-US"

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