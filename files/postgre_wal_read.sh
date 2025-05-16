#! /usr/bin/env bash
# Ansible managed

while [ $# -gt 0 ]; do
    if [[ $1 == "-"* ]]; then
        v="${1/-/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

echo "\ArchiveFullPath: '$ArchiveFullPath' \ArchiveName: '$ArchiveName' \BackupPath: '$BackupPath' \s3Endpoint: '$s3Endpoint' \s3Profile: '$s3Profile'"

backwal=$BackupPath

if [[ -n "$s3Endpoint" || -n "$s3Profile" || "$BackupPath" == s3://* ]]; then
    walFile="${backwal}/${ArchiveName}"
    awsArgs=("s3" "cp" "$walFile" "$ArchiveFullPath")

    if [[ -n "$s3Endpoint" ]]; then
        awsArgs+=("--endpoint-url" "$s3Endpoint")
    fi

    if [[ -n "$s3Profile" ]]; then
        awsArgs+=("--profile" "$s3Profile")
    fi

    aws "${awsArgs[@]}"

	exit $?;
fi

ext7z=".7z"
walFile=$backwal/$ArchiveName
walFile7z=$walFile$ext7z

echo "\walFile: '$walFile' \walFile7z: '$walFile7z'"

if [ ! -f $walFile ]; then
	walFile=$backwal/oldstorage/$ArchiveName
fi

if [ -f $walFile ]; then
	echo Copying $walFile $ArchiveFullPath
	cp $walFile $ArchiveFullPath
	exit $?;
fi

if [ ! -f $walFile7z ]; then
	walFile7z=$backwal/oldstorage/$ArchiveName$ext7z
fi

if [ -f $walFile7z ]; then
	tmpdst="/tmp/wal_copy"
	echo Copying $walFile7z $tmpdst
	/bin/cp -rf -T $walFile7z $tmpdst

	ret=$?
	if [ $ret -ne 0 ]; then
		echo failed to copy $walFile7z
		exit $ret;
	fi

	tmpfold="/tmp/wal_copy_ex"
	mkdir -p $tmpfold

	/usr/lib/p7zip/7z \
		x "$tmpdst" \
		-o"$tmpfold" \
		-bd -aoa

	ret=$?
	if [ $ret -ne 0 ]; then
		echo failed to unarchive $walFile7z
		exit $ret;
	fi

	source=$tmpfold/$ArchiveName
	/bin/mv -f $source $ArchiveFullPath

    exit $?;
fi

echo file not found
exit 1
