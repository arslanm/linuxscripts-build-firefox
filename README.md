# Debian package builder for Mozilla Firefox

## Overview
This script will download the latest available stable or beta release of Firefox directly from Mozilla
and package it into a Debian (.deb) package for installation on Debian and derivative distributions
such as Ubuntu, Linux Mint, etc.

## Usage
Clone this repository or download and extract the .ZIP file from GitHub.

Run **./build-firefox.sh**
Select the architecture and release channel that you want to build a package for (stable or beta).

Execute the script with the **--install** flag (e.g. **./build-firefox --install**) to install the package
after it has been built.

## Installation
To install Firefox after it has been built, execute **sudo dpkg -i firefox-*.deb**.

Alternatively, use GDebi or another package manager of your choice.
