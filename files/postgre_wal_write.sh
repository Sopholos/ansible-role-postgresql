#! /usr/bin/env bash
# Ansible managed

# Set error handling
set -e

while [ $# -gt 0 ]; do
	if [[ $1 == "-"* ]]; then
		v="${1/-/}"
		declare "$v"="$2"
		shift
	fi
	shift
done

echo "\ArchiveFullPath: '$ArchiveFullPath' \ArchiveName: '$ArchiveName' \BackupPath: '$BackupPath' \s3Endpoint: '$s3Endpoint' \s3Profile: '$s3Profile'"

# Validate required parameters
if [[ -z "$ArchiveFullPath" ]]; then
	echo "Missing required parameter ArchiveFullPath"
	exit 1
fi

if [[ -z "$ArchiveName" ]]; then
	echo "Missing required parameter ArchiveName"
	exit 1
fi

if [[ -z "$BackupPath" ]]; then
	echo "Missing required parameter BackupPath"
	exit 1
fi

backwal="$BackupPath"

if [[ -n "$s3Endpoint" || -n "$s3Profile" || "$BackupPath" == s3://* ]]; then
	destination="$backwal/$ArchiveName"
	aws_args=("s3" "cp" "$ArchiveFullPath" "$destination")

	if [[ -n "$s3Endpoint" ]]; then
		aws_args+=("--endpoint-url" "$s3Endpoint")
	fi

	if [[ -n "$s3Profile" ]]; then
		aws_args+=("--profile" "$s3Profile")
	fi

	aws "${aws_args[@]}"

	exit $?;
else
	if [[ ! -d "$backwal" ]]; then
		mkdir -p "$backwal"
	fi

	destination="$backwal/$ArchiveName"
	cp "$ArchiveFullPath" "$destination"

	doneFile="${destination}.done"
	date "+%Y-%m-%d %H:%M:%S" > "$doneFile"
fi