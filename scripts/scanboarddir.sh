#!/bin/bash
BOARDS_IN="tmp/.boards.in"
VERSIONS_IN="tmp/.versions.in"
PACKAGES_IN="tmp/.packages.in"
CONFIGDEPS="tmp/.configdeps"

echo_package()
{
    local board="$1"
    local version="$2"
    local package="$3"
    echo -e "TARGETPACKAGE-\$(CONFIG_PACKAGE_${board}_${version}_${package}) += $package" >>$CONFIGDEPS
    echo -e "config PACKAGE_${board}_${version}_${package}\n\
        bool \"${package}..................for ${board} firmware version ${version}\"\n\
        default y \n\
        help\n\
          ${package} for ${board} firmware version ${version}\n"
}

scanpackage()
{
    local basedir=$(dirname $1)
    local board=$(basename $basedir)
    local version=$(basename $1)
    local profiles=$(ls $1/*.manifest)
    [ -z "$profiles" ] && return
    echo -e "if VERSION_${board}_${version}\n" >>$PACKAGES_IN
    echo "menu \"Select ${board} version ${version} build-in packages\"" >>$PACKAGES_IN
    {\
      for p in $profiles;do \
        while read -r package;do \
            echo_package $board $version $package; \
        done < "$p"; \
      done \
    } >> $PACKAGES_IN
    echo "endmenu" >>$PACKAGES_IN
    echo -e "endif\n" >>$PACKAGES_IN
}

scanversion()
{
    local board=$(basename $1)
    local versions=$(dir $1)
    echo -e "if GL_MODEL_$board\n" >>$VERSIONS_IN
    echo "choice" >>$VERSIONS_IN
    echo "    prompt \"Select version for ${board}\"" >>$VERSIONS_IN
    for v in $versions; do
        scanpackage "$1/$v"
        echo -e "TARGETVERSION-\$(CONFIG_VERSION_${board}_${v}) += $v" >>$CONFIGDEPS
        echo -e "config VERSION_${board}_${v}\n\
            bool \"${board} version ${v}\"\n\
            help\n\
              Build ${board} firmware version ${v}\n" >>$VERSIONS_IN
    done
    echo "endchoice" >>$VERSIONS_IN
    echo -e "endif\n" >>$VERSIONS_IN
}

scanboard()
{
    local boards=$(dir $1)
    echo "choice" >>$BOARDS_IN
    echo "    prompt \"Select GL.iNet router model\"" >>$BOARDS_IN
    for d in $boards; do
        scanversion "$1/$d"
        echo -e "TARGETMODEL-\$(CONFIG_GL_MODEL_${d}) += $d" >>$CONFIGDEPS
        echo -e "config GL_MODEL_$d\n\
            bool \"GL.iNet $d\"\n\
            help\n\
              Build firmware images for GL.iNet $d\n" >>$BOARDS_IN
    done
    echo "endchoice" >>$BOARDS_IN

}

rm $BOARDS_IN 2>/dev/null
rm $PACKAGES_IN 2>/dev/null
rm $VERSIONS_IN 2>/dev/null
rm $CONFIGDEPS 2>/dev/null
echo "source \"$BOARDS_IN\"" >tmp/tmpglboard.in
echo "source \"$VERSIONS_IN\"" >>tmp/tmpglboard.in
echo "source \"$PACKAGES_IN\"" >>tmp/tmpglboard.in
scanboard $@