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

# Generating localised XIBs

    ZIPPITY_LANG=de
    ibtool --strings-file $ZIPPITY_LANG.lproj/ZPAboutViewController.strings \
        --write $ZIPPITY_LANG.lproj/ZPAboutViewController.xib en.lproj/ZPAboutViewController.xib
    ibtool --strings-file $ZIPPITY_LANG.lproj/ZPAboutViewController.strings \
        --write $ZIPPITY_LANG.lproj/ZPAboutViewController-iPad.xib en.lproj/ZPAboutViewController-iPad.xib
    ibtool --strings-file $ZIPPITY_LANG.lproj/ZPUnrecognisedFileTypeViewController.strings \
        --write $ZIPPITY_LANG.lproj/ZPUnrecognisedFileTypeViewController.xib en.lproj/ZPUnrecognisedFileTypeViewController.xib

# Getting the UTI for a given file

Use mdls, part of Spotlight:

    mdls foo.ext
    
# Building and archiving

    # with debug symbols (for TestFlight)
    xcodebuild -workspace Zippity.xcworkspace -configuration Debug -scheme "Zippity" clean archive

    # without debug symbols (for App Store release)
    xcodebuild -workspace Zippity.xcworkspace -configuration Release -scheme "Zippity" clean archive
