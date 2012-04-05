# Generating localization files

For *.m files:

    cd Zippity
    genstrings -o en.lproj/ *.m
    
For the settings bundle:

    cd Settings.bundle
    ./generate-settings-strings
    
For XIBs:

    cd Zippity
    ibtool --generate-strings-file en.lproj/ZPAboutViewController.strings en.lproj/ZPAboutViewController.xib 

