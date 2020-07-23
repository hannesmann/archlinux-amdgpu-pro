#!/bin/bash

# This script extracts transaction scripts of deb packages to a file, so it is possible to read it and compare with previous version.
# After that its needed to carefully convert them to pacman .install files or hooks if needed

majorold=20.20
minorold=1089974

majornew=20.20
minornew=1098277

major=$majornew
minor=$minornew
# major=$majorold
# minor=$minorold

ARCHIVE=amdgpu-pro-$major-$minor-ubuntu-20.04.tar.xz
cd ${ARCHIVE%.tar.xz}
cd unpacked_debs
rm -f *.install_scripts.sh
rm -rf ../install_scripts_"$major"-"$minor"
rm -rf ../install_scripts
mkdir -p ../install_scripts
> transaction_scripts_and_triggers_md5sums.txt # clear file
echo -e "md5sums of transaction scripts and triggers of deb packages from archive ${ARCHIVE}\n" > transaction_scripts_and_triggers_md5sums.txt
for dir in $(ls); do
    for file in postinst preinst prerm; do
        if [ -f $dir/$file ]; then
            file_md5=$(md5sum $dir/$file)
            # echo -e "# $file_md5"  >> $dir.install_scripts.sh
            echo -e "$file_md5"  >> transaction_scripts_and_triggers_md5sums.txt
            #cat $dir/$file >> $dir.install_scripts.sh
            cat $dir/$file > ../install_scripts/"$dir"_"$file".txt
        fi
    done
done
cd ..

# As of 19.30-934563, all (except two) libs debian packages have just ldconfig awaiting trigger. It is done automatically by pacman, so we skip them.
# Two exceptions are:
    #libgl1-amdgpu-mesa-dri_18.3.0-812932_amd64.deb
    #interest /usr/lib/x86_64-linux-gnu/dri
    #libgl1-amdgpu-mesa-dri_18.3.0-812932_i386.deb
    #interest /usr/lib/i386-linux-gnu/dri
# They are triggered when files are changed in interest path. I (Ashark) created corresponding alpm hooks.

cd unpacked_debs
for dir in $(ls -d *deb);
do
    if [ -f "$dir"/triggers ]; then
        if [[ $(cat "$dir"/triggers) == "# Triggers added by dh_makeshlibs/11.1.6ubuntu2
activate-noawait ldconfig" ]];
        then continue; fi
        file_md5=$(md5sum $dir/triggers)
        echo -e "$file_md5" >> transaction_scripts_and_triggers_md5sums.txt
        cat $dir/triggers > ../install_scripts/"$dir"_"triggers".txt
    fi
done

sed -i -e "1 ! s/$major/XX.XX/g" -e "1 ! s/$minor/XXXXXX/g" transaction_scripts_and_triggers_md5sums.txt
cd ..

rename "$major" "XX.XX" install_scripts/*.txt
rename "$minor" "XXXXXX" install_scripts/*.txt
rename "19.2.0" "YY.Y.Y" install_scripts/*.txt
rename "19.2.2" "YY.Y.Y" install_scripts/*.txt
rename "5.6.0.13" "Y.Y.Y.YY" install_scripts/*.txt
rename "5.6.0.15" "Y.Y.Y.YY" install_scripts/*.txt

mv install_scripts install_scripts_"$major"-"$minor"
cd ..
meld amdgpu-pro-$majorold-$minorold-ubuntu-20.04/install_scripts_"$majorold"-"$minorold" amdgpu-pro-$majornew-$minornew-ubuntu-20.04/install_scripts_"$majornew"-"$minornew"
