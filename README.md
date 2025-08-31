This script packs packages listed in a modules.txt file into a single .zip file that athens can work with.

Make sure modules.txt has the packages you want listed there with versions.
right format is "<module>@<version>"
examples:
- github.com/beorn7/perks@v1.0.1
- golang.org/x/sys@v0.11.0
- cloud.google.com/go/storage@v1.30.1

or another possible format is "<module> <version>"
examples:
- github.com/beorn7/perks v1.0.1
- golang.org/x/sys v0.11.0
- cloud.google.com/go/storage v1.30.1
## There is a provided example `modules.txt` file in this repository

Tools needed to make this script work:
- go
- pacmod
- jq
- zip
- unzip

Usage: 
./fetch_modules.sh modules.txt 

© 2025 Shon Bazov
All rights reserved