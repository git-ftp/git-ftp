#!/bin/sh

oneTimeSetUp() {
	GIT_PROJECT_NAME="git-ftp-test"

	GIT_PROJECT_PATH="/tmp/git-ftp-test"
	FTP_PROJECT_PATH="/opt/lampp/htdocs/$GIT_PROJECT_NAME"

	BASE_PATH="$(pwd)/../"
	GIT_FTP_CMD="${BASE_PATH}git-ftp"
	GIT_FTP_USER="nobody"
	GIT_FTP_PASSWD="lampp"
	GIT_FTP_URL="localhost/$GIT_PROJECT_NAME"

	echo Starting FTP Server
	sudo /opt/lampp/lampp start > /dev/null 2>&1
	START=$(date +%s)
}

oneTimeTearDown() {
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	echo "It took $DIFF seconds"
	echo Stopping FTP Server
	sudo /opt/lampp/lampp stop > /dev/null 2>&1
}

setUp() {
	sudo rm -rf $FTP_PROJECT_PATH
	mkdir -p $GIT_PROJECT_PATH
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
	cd ${BASE_PATH}/tests
	rm -rf $GIT_PROJECT_PATH
	sudo rm -rf $FTP_PROJECT_PATH
}

test_displays_usage() {
	usage=$($GIT_FTP_CMD 2>&1)
	assertEquals "git-ftp <action> [<options>] <url>" "$usage"
}

test_prints_version() {
	version=$($GIT_FTP_CMD 2>&1 --version)
	assertEquals = "git-ftp version 0.8.3-snapshot"  "$version"
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

	init=$($GIT_FTP_CMD init -s testing)
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

	assertTrue 'test failed: file does not exist' "[ -r '$FTP_PROJECT_PATH/test 1.txt' ]"

	git rm "test 1.txt" > /dev/null 2>&1
	git commit -a -m "delete file" > /dev/null 2>&1

	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: file still exists' "[ -r '$FTP_PROJECT_PATH/test 1.txt' ]"
	assertTrue 'test failed: file does not exist' "[ -r '$FTP_PROJECT_PATH/dir 1/test 1.txt' ]"

	git rm -r "dir 1" > /dev/null 2>&1
	git commit -a -m "delete dir" > /dev/null 2>&1

	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: dir and file still exists' "[ -r '$FTP_PROJECT_PATH/dir 1/test 1.txt' ]"
	assertFalse 'test failed: dir still exists' "[ -d '$FTP_PROJECT_PATH/dir 1' ]"
}

test_ignore_single_file() {
	cd $GIT_PROJECT_PATH
	echo "test 1\.txt" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: file was not ignored' "[ -f '$FTP_PROJECT_PATH/test 1.txt' ]"
}

test_ignore_dir() {
	cd $GIT_PROJECT_PATH
	echo "dir 1/.*" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: dir was not ignored' "[ -f '$FTP_PROJECT_PATH/dir 1/test 1.txt' ]"
	assertTrue 'test failed: wrong dir was ignored' "[ -f '$FTP_PROJECT_PATH/dir 2/test 2.txt' ]"
}

test_ignore_wildcard_files() {
	cd $GIT_PROJECT_PATH
	echo "test.*\.txt" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	for i in 1 2 3 4 5
	do
		assertFalse 'test failed: was not ignored' "[ -f '$FTP_PROJECT_PATH/test $i.txt' ]"
	done;
}

test_hidden_file_only() {
	cd $GIT_PROJECT_PATH
	echo "test" > .htaccess
	git add . > /dev/null 2>&1
	git commit -a -m "init" > /dev/null 2>&1
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertTrue 'test failed: .htaccess not uploaded' "[ -f '$FTP_PROJECT_PATH/.htaccess' ]"
}

test_syncroot() {
	cd $GIT_PROJECT_PATH
	mkdir foobar && echo "test" > foobar/syncroot.txt
	git add . > /dev/null 2>&1
	git commit -a -m "syncroot test" > /dev/null 2>&1
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD --syncroot foobar $GIT_FTP_URL)
	assertTrue 'test failed: syncroot.txt not there as expected' "[ -f '$FTP_PROJECT_PATH/syncroot.txt' ]"
}

test_file_named_dash() {
	cd $GIT_PROJECT_PATH
	echo "foobar" > -
	assertTrue 'test failed: file named - not there as expected' "[ -f '$GIT_PROJECT_PATH/-' ]"
	git add . > /dev/null 2>&1
	git commit -a -m "file named - test" > /dev/null 2>&1
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD)
	rtrn=$?
	assertEquals 0 $rtrn
}
# load and run shUnit2
. ./shunit2-2.1.6/src/shunit2
