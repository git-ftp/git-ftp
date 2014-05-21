#!/bin/sh

oneTimeSetUp() {
	BASE_PATH=$(readlink -f $TESTDIR/..)/
	# Maybe this is more robust?
	#BASE_PATH=$TESTDIR/../

	GIT_FTP_CMD="${BASE_PATH}git-ftp"
	: ${GIT_FTP_USER=ftp}
	: ${GIT_FTP_PASSWD=}
	: ${GIT_FTP_ROOT=localhost/}

	START=$(date +%s)
}

oneTimeTearDown() {
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	echo "It took $DIFF seconds"
}

setUp() {
	GIT_PROJECT_PATH=$(mktemp -d -t git-ftp-XXXX)
	GIT_PROJECT_NAME=$(basename $GIT_PROJECT_PATH)

	GIT_FTP_URL="$GIT_FTP_ROOT$GIT_PROJECT_NAME"

	CURL_URL="ftp://$GIT_FTP_USER:$GIT_FTP_PASSWD@$GIT_FTP_URL"

	cd $GIT_PROJECT_PATH

	# make some content
	for i in 1 2 3 4 5
	do
		echo "$i" >> ./"test $i.txt"
		mkdir -p "dir $i"
		echo "$i" >> "dir $i/test $i.txt"
	done;

	# git them
	git init > /dev/null 2>&1
	git add . > /dev/null 2>&1
	git commit -a -m "init" > /dev/null 2>&1
}

tearDown() {
	cd ${TESTDIR}
	rm -rf $GIT_PROJECT_PATH
	command -v lftp >/dev/null 2>&1 && {
		lftp -u $GIT_FTP_USER,$GIT_FTP_PASSWD $GIT_FTP_ROOT -e "set ftp:list-options -a; rm -rf '$GIT_PROJECT_NAME'; exit" > /dev/null 2>&1
	}
}

test_displays_usage() {
	usage=$($GIT_FTP_CMD 2>&1)
	assertEquals "git-ftp <action> [<options>] <url>" "$usage"
}

test_prints_version() {
	version=$($GIT_FTP_CMD 2>&1 --version)
	assertEquals = "git-ftp version 1.0.0-rc.1"  "$version"
}

test_inits_and_pushes() {
	cd $GIT_PROJECT_PATH

	# this should pass
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	rtrn=$?
	assertEquals 0 $rtrn

	# this should fail
	init2=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL 2>&1)
	rtrn=$?
	assertEquals 2 $rtrn
	assertEquals "fatal: Commit found, use 'git ftp push' to sync. Exiting..." "$init2"

	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1

	# this should pass
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_pushes_and_fails() {
	cd $GIT_PROJECT_PATH
	push="$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL 2>&1)"
	rtrn=$?
	assertEquals "fatal: Could not get last commit. Network down? Wrong URL? Use 'git ftp init' for the inital push., exiting..." "$push"
	assertEquals 5 $rtrn
}

test_defaults() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password $GIT_FTP_PASSWD
	git config git-ftp.url $GIT_FTP_URL

	init=$($GIT_FTP_CMD init)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_defaults_uses_url_by_cli() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password $GIT_FTP_PASSWD
	git config git-ftp.url notexisits

	init=$($GIT_FTP_CMD init $GIT_FTP_URL)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_defaults_uses_user_by_cli() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user johndoe
	git config git-ftp.password $GIT_FTP_PASSWD
	git config git-ftp.url $GIT_FTP_URL

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_defaults_uses_password_by_cli() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password wrongpasswd
	git config git-ftp.url $GIT_FTP_URL

	init=$($GIT_FTP_CMD init -p $GIT_FTP_PASSWD)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_scopes() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password wrongpasswd
	git config git-ftp.url $GIT_FTP_URL

	git config git-ftp.testing.password $GIT_FTP_PASSWD

	init=$($GIT_FTP_CMD init -s testing)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_scopes_using_branchname_as_scope() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.production.user $GIT_FTP_USER
	git config git-ftp.production.password $GIT_FTP_PASSWD
	git config git-ftp.production.url $GIT_FTP_URL
	git checkout -b production > /dev/null 2>&1

	init=$($GIT_FTP_CMD init -s)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_overwrite_defaults_by_scopes_emtpy_string() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password $GIT_FTP_PASSWD
	git config git-ftp.url $GIT_FTP_URL

	git config git-ftp.testing.password ''

	init=$($GIT_FTP_CMD init -s testing 2>/dev/null)
	rtrn=$?
	assertEquals 4 $rtrn
}

test_scopes_uses_password_by_cli() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password wrongpasswd
	git config git-ftp.url $GIT_FTP_URL

	git config git-ftp.testing.password wrongpasswdtoo

	init=$($GIT_FTP_CMD init -s testing -p $GIT_FTP_PASSWD)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_delete() {
	cd $GIT_PROJECT_PATH

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertTrue 'test failed: file does not exist' "remote_file_exists 'test 1.txt'"

	git rm "test 1.txt" > /dev/null 2>&1
	git commit -a -m "delete file" > /dev/null 2>&1

	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: file still exists' "remote_file_exists 'test 1.txt'"
	assertTrue 'test failed: file does not exist' "remote_file_exists 'dir 1/test 1.txt'"

	git rm -r "dir 1" > /dev/null 2>&1
	git commit -a -m "delete dir" > /dev/null 2>&1

	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: dir and file still exists' "remote_file_exists 'dir 1/test 1.txt'"
	assertFalse 'test failed: dir still exists' "remote_file_exists 'dir 1/'"
}

test_ignore_single_file() {
	cd $GIT_PROJECT_PATH
	echo "test 1\.txt" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: file was not ignored' "remote_file_exists 'test 1.txt' ]"
}

test_ignore_dir() {
	cd $GIT_PROJECT_PATH
	echo "dir 1/.*" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: dir was not ignored' "remote_file_exists 'dir 1/test 1.txt'"
	assertTrue 'test failed: wrong dir was ignored' "remote_file_exists 'dir 2/test 2.txt'"
}

test_ignore_wildcard_files() {
	cd $GIT_PROJECT_PATH
	echo "test.*\.txt" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	for i in 1 2 3 4 5
	do
		assertFalse 'test failed: was not ignored' "remote_file_exists 'test $i.txt'"
	done;
}

test_hidden_file_only() {
	cd $GIT_PROJECT_PATH
	echo "test" > .htaccess
	git add . > /dev/null 2>&1
	git commit -a -m "init" > /dev/null 2>&1
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertTrue 'test failed: .htaccess not uploaded' "remote_file_exists '.htaccess'"
}


test_file_with_nonchar() {
	cd $GIT_PROJECT_PATH
	echo "test" > ./#4253-Release Contest.md
	git add . > /dev/null 2>&1
	git commit -a -m "init" > /dev/null 2>&1

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertTrue 'test failed: #4253-Release Contest.md not uploaded' "remote_file_exists '#4253-Release Contest.md'"

	git rm './#4253-Release Contest.md' > /dev/null 2>&1
	git commit -a -m "delete" > /dev/null 2>&1

	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertFalse 'test failed: #4253-Release Contest.md still exists in '$CURL_URL "remote_file_exists '\#4253-Release Contest.md'"
}

test_syncroot() {
	cd $GIT_PROJECT_PATH
	mkdir foobar && echo "test" > foobar/syncroot.txt
	git add . > /dev/null 2>&1
	git commit -a -m "syncroot test" > /dev/null 2>&1
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD --syncroot foobar $GIT_FTP_URL)
	assertTrue 'test failed: syncroot.txt not there as expected' "remote_file_exists 'syncroot.txt'"
}

disabled_test_file_named_dash() {
	cd $GIT_PROJECT_PATH
	echo "foobar" > -
	assertTrue 'test failed: file named - not there as expected' "[ -f '$GIT_PROJECT_PATH/-' ]"
	git add . > /dev/null 2>&1
	git commit -a -m "file named - test" > /dev/null 2>&1
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD)
	rtrn=$?
	assertEquals 0 $rtrn
}

remote_file_exists() {
	head=$(curl "$CURL_URL/$1" --head)
	return $?
}

# load and run shUnit2
TESTDIR=$(dirname $0)
. $TESTDIR/shunit2-2.1.6/src/shunit2
