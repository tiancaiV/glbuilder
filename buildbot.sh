#!/bin/sh

WORKDIR="$(pwd)"

sudo -E apt-get update 
sudo -E apt-get install device-tree-compiler g++ ncurses-dev python asciidoc bash bc binutils bzip2 fastjar\
 flex gawk gcc genisoimage gettext git intltool jikespg libgtk2.0-dev libncurses5-dev libssl-dev make mercurial\
  patch perl-modules python2.7-dev rsync ruby sdcc subversion unzip util-linux wget xsltproc zlib1g-dev zlib1g-dev -y

failed()
{
	echo "================show .config start================="
	cat .config
	echo "================show .config end================="
	echo "make ${2} for ${1} failed!"
	exit 1
}

mkdir -p ${WORKDIR}/assets

TESTMODELS="ar750 ar750s ar300m x300b x750 xe300 mt1300 b1300 sft1200"

#for m in $(dir ${WORKDIR}/board);do
for m in $TESTMODELS;do
	for v in $(dir ${WORKDIR}/board/${m});do
		echo CONFIG_GL_MODEL_"${m}"=y > .config
		echo CONFIG_VERSION_"${m}"_"${v}"=y >>.config
		make defconfig
		make || failed "${m}" "${v}"
		find ./bin/"${m}"-"${v}"/target -name  "*${m}*.tar" -exec cp -f {} "${WORKDIR}/assets/${m}-${v}.tar" \;
		find ./bin/"${m}"-"${v}"/target -name  "*${m}*.img" -exec cp -f {} "${WORKDIR}/assets/${m}-${v}.img" \;
		find ./bin/"${m}"-"${v}"/target -name  "*${m}*.bin" -exec cp -f {} "${WORKDIR}/assets/${m}-${v}.bin" \;
		[ -f "${WORKDIR}/assets/${m}-${v}.tar" ] || [ -f "${WORKDIR}/assets/${m}-${v}.img" ] || [ -f "${WORKDIR}/assets/${m}-${v}.bin" ] || {
			 failed "${m}" "${v}"
		}
	done
done

tree assets
