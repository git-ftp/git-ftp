#!/bin/sh
#
# Usage: git-ftp-test.sh
#
# You can define environment variables to choose the FTP server to test on.
#
# Example:
#     export GIT_FTP_ROOT='localhost/git-ftp-tests'
#     export GIT_FTP_USER='git-ftp-test'
#     export GIT_FTP_PASSWD='s3cr3t'
#     ./git-ftp-test.sh
#
# You can choose test cases as well:
#     export TEST_CASES='test_displays_usage test_prints_version'
#     ./git-ftp-test.sh
#
# Or you can write it in one line:
#     TEST_CASES='test_displays_usage' GIT_FTP_PASSWD='s3cr3t' ./git-ftp-test.sh

suite() {
	for testcase in ${TEST_CASES}; do
		suite_addTest "$testcase"
	done
}

oneTimeSetUp() {
	cd "$TESTDIR/../"

	GIT_FTP_CMD="$(pwd)/git-ftp"
	: ${GIT_FTP_USER=ftp}
	: ${GIT_FTP_PASSWD=}
	: ${GIT_FTP_ROOT=localhost}

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

	GIT_FTP_URL="$GIT_FTP_ROOT/$GIT_PROJECT_NAME"

	CURL_URL="ftp://$GIT_FTP_USER:$GIT_FTP_PASSWD@$GIT_FTP_URL"

	[ -n "$GIT_FTP_USER" ] && GIT_FTP_USER_ARG="-u $GIT_FTP_USER"
	[ -n "$GIT_FTP_PASSWD" ] && GIT_FTP_PASSWD_ARG="-p $GIT_FTP_PASSWD"
	GIT_FTP="$GIT_FTP_CMD $GIT_FTP_USER_ARG $GIT_FTP_PASSWD_ARG $GIT_FTP_URL"

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
	assertEquals = "git-ftp version 1.0.2"  "$version"
}

test_inits() {
	init=$($GIT_FTP init)
	assertEquals 0 $?
	assertTrue 'file does not exist' "remote_file_exists 'test 1.txt'"
	assertTrue 'file differs' "remote_file_equals 'test 1.txt'"
}

test_init_fails() {
	init=$($GIT_FTP_CMD -v -u wrong_user -p wrong_passwd $GIT_FTP_URL init 2>&1)
	assertEquals 5 $?
	error_count=$(echo "$init" | grep -F 'Access denied' | wc -l)
	assertEquals 1 $error_count
}

test_inits_and_pushes() {
	cd $GIT_PROJECT_PATH

	# this should pass
	init=$($GIT_FTP init)
	rtrn=$?
	assertEquals 0 $rtrn

	# this should fail
	init2=$($GIT_FTP init 2>&1)
	rtrn=$?
	assertEquals 2 $rtrn
	assertEquals "fatal: Commit found, use 'git ftp push' to sync. Exiting..." "$init2"

	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1

	# this should pass
	push=$($GIT_FTP push)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_init_more() {
	cd $GIT_PROJECT_PATH

	# Generate a number of files exceeding the upload buffer
	long_prefix='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
	long_file_list=''
	for i in `seq 50`; do
		long_file_list="$long_file_list $long_prefix$i"
	done
	touch $long_file_list
	git add .
	git commit -m 'Some more files.' > /dev/null

	init=$($GIT_FTP init)
	assertEquals 0 $?
	assertTrue 'file does not exist' "remote_file_exists '${long_prefix}50'"

	# Counting the number of uploads to estimate correct buffering
	upload_count=$(echo "$init" | grep -Fx 'Uploading ...' | wc -l)
	assertTrue "[ $upload_count -gt 1 ]"
}

test_delete_more() {
	cd $GIT_PROJECT_PATH

	# Generate a number of files exceeding the upload buffer
	long_prefix='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
	long_file_list=''
	for i in `seq 50`; do
		long_file_list="$long_file_list $long_prefix$i"
	done
	touch $long_file_list
	git add .
	git commit -m 'Some more files.' > /dev/null

	init=$($GIT_FTP init)
	assertEquals 0 $?

	# Delete a number of files exceeding the upload buffer
	git rm $long_file_list > /dev/null
	git commit -m 'Deleting some more files.' > /dev/null

	push=$($GIT_FTP push)
	assertEquals 0 $?

	# Counting the number of deletes to estimate correct buffering
	delete_count=$(echo "$push" | grep -Fx 'Deleting ...' | wc -l)
	assertTrue "[ $delete_count -gt 1 ]"
	assertFalse 'file does exist' "remote_file_exists '${long_prefix}50'"
}

# this test takes a couple of minutes (revealing a performance issue)
disabled_test_init_heaps() {
	cd $GIT_PROJECT_PATH

	# Generate a large number of files which fails to upload on some systems
	touch `seq 3955`
	git add .
	git commit -m 'A lot of files.' > /dev/null

	$GIT_FTP init> /dev/null
	assertEquals 0 $?
	assertTrue 'file does not exist' "remote_file_exists '3955'"
}

test_pushes_and_fails() {
	cd $GIT_PROJECT_PATH
	push="$($GIT_FTP push 2>&1)"
	rtrn=$?
	assertEquals "fatal: Could not get last commit. Network down? Wrong URL? Use 'git ftp init' for the initial push., exiting..." "$push"
	assertEquals 5 $rtrn
}

test_push_unknown_commit() {
	$GIT_FTP init > /dev/null
	echo '000000000' | curl -s -T - $CURL_URL/.git-ftp.log
	push="$($GIT_FTP push 0>&- 2>&1)"
	assertEquals 0 $?
	assertContains 'Unknown SHA1 object' "$push"
	assertContains 'Do you want to ignore' "$push"
}

test_push_nothing() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	push=$($GIT_FTP push --dry-run)
	assertEquals 0 $?
	assertTrue "$push" "echo \"$push\" | grep 'There are 1 files to sync:'"
	echo 'test 1.txt' >> .git-ftp-ignore
	push=$($GIT_FTP push)
	assertEquals 0 $?
	firstline=$(echo "$push" | head -n 1)
	assertEquals 'There are no files to sync.' "$firstline"
}

test_push_added() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	# add a file
	file='newfile.txt'
	echo "1" > "./$file"
	git add $file
	git commit -m "change" > /dev/null 2>&1
	push=$($GIT_FTP push)
	assertEquals 0 $? || echo "Push: $push"
	assertEquals "1" "$(curl -s $CURL_URL/$file)"
}

test_push_twice() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	push=$($GIT_FTP push)
	assertEquals 0 $? || echo "First push: $push"
	push=$($GIT_FTP push)
	assertEquals 0 $? || echo "Second push: $push"
	assertTrue "$push" "echo \"$push\" | grep 'Everything up-to-date.'"
}

test_push_unknown_sha1() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	# change remote SHA1
	echo '000000000' | curl -T - $CURL_URL/.git-ftp.log 2> /dev/null
	push=$(echo 'N' | $GIT_FTP push)
	assertEquals 0 $?
	echo "$push" | grep 'Unknown SHA1 object' > /dev/null
	assertFalse ' test 1.txt uploaded' "remote_file_equals 'test 1.txt'"
}

test_push_unknown_sha1_Y() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	# change remote SHA1
	echo '000000000' | curl -T - $CURL_URL/.git-ftp.log 2> /dev/null
	push=$(echo 'Y' | $GIT_FTP push)
	assertEquals 0 $?
	echo "$push" | grep 'Unknown SHA1 object' > /dev/null
	assertEquals 0 $?
	assertTrue ' test 1.txt uploaded' "remote_file_equals 'test 1.txt'"
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
	[ -z "$GIT_FTP_USER" ] && startSkipping
	cd $GIT_PROJECT_PATH
	git config git-ftp.user johndoe
	git config git-ftp.password $GIT_FTP_PASSWD
	git config git-ftp.url $GIT_FTP_URL

	init=$($GIT_FTP_CMD init $GIT_FTP_USER_ARG)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_defaults_uses_password_by_cli() {
	[ -z "$GIT_FTP_PASSWD" ] && startSkipping
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password wrongpasswd
	git config git-ftp.url $GIT_FTP_URL

	init=$($GIT_FTP_CMD init $GIT_FTP_PASSWD_ARG)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_deployedsha1file_rename() {
	local file='git-ftp.txt'
	git config git-ftp.deployedsha1file "$file"
	init=$($GIT_FTP init)
	assertEquals 0 $?
	assertTrue " '$file' does not exist" "remote_file_exists '$file'"
	assertFalse " '.git-ftp.log' does exist" "remote_file_exists '.git-ftp.log'"
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

test_invalid_scope_name() {
	out=$($GIT_FTP_CMD init -s invalid:scope 2>&1)
	assertEquals 2 $?
	assertEquals 'fatal: Invalid scope name.' "$out"

	out=$($GIT_FTP_CMD add-scope invalid:scope 2>&1)
	assertEquals 2 $?
	assertEquals 'fatal: Invalid scope name.' "$out"
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

	git config git-ftp.testing.url ''

	init=$($GIT_FTP_CMD init -s testing 2>/dev/null)
	rtrn=$?
	assertEquals 3 $rtrn
}

test_scopes_uses_password_by_cli() {
	cd $GIT_PROJECT_PATH
	git config git-ftp.user $GIT_FTP_USER
	git config git-ftp.password wrongpasswd
	git config git-ftp.url $GIT_FTP_URL

	git config git-ftp.testing.password wrongpasswdtoo

	init=$($GIT_FTP_CMD init -s testing $GIT_FTP_PASSWD_ARG)
	rtrn=$?
	assertEquals 0 $rtrn
}

test_delete() {
	cd $GIT_PROJECT_PATH

	init=$($GIT_FTP init)

	assertTrue 'test failed: file does not exist' "remote_file_exists 'test 1.txt'"

	git rm "test 1.txt" > /dev/null 2>&1
	git commit -a -m "delete file" > /dev/null 2>&1

	push=$($GIT_FTP push)
	rtrn=$?
	assertEquals 0 $rtrn

	assertFalse 'test failed: file still exists' "remote_file_exists 'test 1.txt'"
	assertTrue 'test failed: file does not exist' "remote_file_exists 'dir 1/test 1.txt'"

	git rm -r "dir 1" > /dev/null 2>&1
	git commit -a -m "delete dir" > /dev/null 2>&1

	push=$($GIT_FTP push)

	assertFalse 'test failed: dir and file still exists' "remote_file_exists 'dir 1/test 1.txt'"
# See https://github.com/git-ftp/git-ftp/issues/168
#	assertFalse 'test failed: dir still exists' "remote_file_exists 'dir 1/'"
}

test_ignore_single_file() {
	cd $GIT_PROJECT_PATH
	echo "test 1\.txt" > .git-ftp-ignore

	init=$($GIT_FTP init)

	assertFalse 'test failed: file was not ignored' "remote_file_exists 'test 1.txt'"
}

test_ignore_single_file_force_unknown_commit() {
	init=$($GIT_FTP init)
	local file='ignored.txt'
	touch $file
	echo $file > .git-ftp-ignore
	git add .
	git commit -m 'added new file that should be ignored' -q
	echo '000000000' | curl -s -T - $CURL_URL/.git-ftp.log
	push=$($GIT_FTP push -f)
	assertFalse 'test failed: file was not ignored' "remote_file_exists '$file'"
}

test_ignore_dir() {
	cd $GIT_PROJECT_PATH
	echo "dir 1/.*" > .git-ftp-ignore

	init=$($GIT_FTP init)

	assertFalse 'test failed: dir was not ignored' "remote_file_exists 'dir 1/test 1.txt'"
	assertTrue 'test failed: wrong dir was ignored' "remote_file_exists 'dir 2/test 2.txt'"
}

test_ignore_pattern() {
	cd $GIT_PROJECT_PATH
	echo "test" > .git-ftp-ignore

	init=$($GIT_FTP init)

	for i in 1 2 3 4 5
	do
		assertFalse 'test failed: was not ignored' "remote_file_exists 'test $i.txt'"
	done;
}

disabled_test_ignore_pattern_single() {
	cd $GIT_PROJECT_PATH
	echo 'test' > 'test'
	echo "^test$" > .git-ftp-ignore
	git add .
	git commit -m 'adding file that should not be uploaded' > /dev/null

	init=$($GIT_FTP init)

	assertFalse 'test failed: was not ignored' "remote_file_exists 'test'"
	for i in 1 2 3 4 5
	do
		assertTrue 'test failed: was ignored' "remote_file_exists 'test $i.txt'"
	done;
}

# TODO: make this test fail an the previous test work
test_ignore_pattern_single_dirty() {
	echo 'test' > 'test'
	echo '^. test$' > .git-ftp-ignore
	git add .
	git commit -m 'adding file that should not be uploaded' > /dev/null

	init=$($GIT_FTP init)

	assertFalse 'test failed: was not ignored' "remote_file_exists 'test'"
	for i in 1 2 3 4 5
	do
		assertTrue 'test failed: was ignored' "remote_file_exists 'test $i.txt'"
	done;
}

test_ignore_wildcard_files() {
	cd $GIT_PROJECT_PATH
	echo "test.*\.txt" > .git-ftp-ignore

	init=$($GIT_FTP init)

	for i in 1 2 3 4 5
	do
		assertFalse 'test failed: was not ignored' "remote_file_exists 'test $i.txt'"
	done;
}

test_include_init() {
	cd $GIT_PROJECT_PATH
	echo 'unversioned' > unversioned.txt
	echo 'unversioned.txt' >> .gitignore
	echo 'unversioned.txt:test 1.txt' > .git-ftp-include
	echo 'new content' >> 'test 1.txt'
	git add .
	git commit -m 'unversioned file unversioned.txt should be uploaded with test 1.txt' > /dev/null
	init=$($GIT_FTP init)
	assertTrue 'unversioned.txt was not uploaded' "remote_file_exists 'unversioned.txt'"
}

test_include_directory() {
	mkdir unversioned
	touch unversioned/file.txt
	echo 'unversioned/:test 1.txt' > .git-ftp-include
	mkdir unversioned-not-included
	touch unversioned-not-included/file.txt
	init=$($GIT_FTP init)
	assertTrue 'unversioned/file.txt was not uploaded' "remote_file_exists 'unversioned/file.txt'"
	assertFalse 'unversioned-not-included/file.txt was uploaded' "remote_file_exists 'unversioned-not-included/file.txt'"
}

test_include_whitespace_init() {
	cd $GIT_PROJECT_PATH
	echo 'unversioned' > unversioned.txt
	echo 'unversioned.txt' >> .gitignore
	echo 'unversioned.txt:test X.txt' > .git-ftp-include
	git add .
	git commit -m 'unversioned file unversioned.txt should not be uploaded. test X.txt does not exist.' > /dev/null
	init=$($GIT_FTP init)
	assertFalse 'unversioned.txt was uploaded' "remote_file_exists 'unversioned.txt'"
}

test_include_push() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	echo 'unversioned' > unversioned.txt
	echo 'unversioned.txt' >> .gitignore
	echo 'unversioned.txt:test 1.txt' > .git-ftp-include
	echo 'new content' >> 'test 1.txt'
	git add .
	git commit -m 'unversioned file unversioned.txt should be uploaded with test 1.txt' > /dev/null
	push=$($GIT_FTP push)
	assertTrue 'unversioned.txt was not uploaded' "remote_file_exists 'unversioned.txt'"
}

test_include_ignore_init() {
	cd $GIT_PROJECT_PATH
	echo 'htaccess' > .htaccess
	echo 'htaccess.prod' > .htaccess.prod
	echo '.htaccess:.htaccess.prod' > .git-ftp-include
	echo '.htaccess.prod' > .gitignore
	git add .
	git commit -m 'htaccess setup' > /dev/null
	init=$($GIT_FTP init)
	assertTrue ' .htaccess was ignored' "remote_file_exists '.htaccess'"
	assertFalse ' .htaccess.prod was uploaded' "remote_file_exists '.htaccess.prod'"
}

test_include_ignore_push() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	echo 'htaccess' > .htaccess
	echo 'htaccess.prod' > .htaccess.prod
	echo '.htaccess:.htaccess.prod' > .git-ftp-include
	echo '.htaccess.prod' > .gitignore
	git add .
	git commit -m 'htaccess setup' > /dev/null
	push=$($GIT_FTP push)
	assertTrue ' .htaccess was ignored' "remote_file_exists '.htaccess'"
	assertFalse ' .htaccess.prod was uploaded' "remote_file_exists '.htaccess.prod'"
}

test_include_ftp_ignore_init() {
	cd $GIT_PROJECT_PATH
	echo 'htaccess' > .htaccess
	echo 'htaccess.prod' > .htaccess.prod
	echo '.htaccess:.htaccess.prod' > .git-ftp-include
	echo '.htaccess.prod' > .git-ftp-ignore
	git add .
	git commit -m 'htaccess setup' > /dev/null
	init=$($GIT_FTP init)
	assertTrue ' .htaccess was ignored' "remote_file_exists '.htaccess'"
	assertFalse ' .htaccess.prod was uploaded' "remote_file_exists '.htaccess.prod'"
}

test_include_ftp_ignore_push() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP init)
	echo 'htaccess' > .htaccess
	echo 'htaccess.prod' > .htaccess.prod
	echo '.htaccess:.htaccess.prod' > .git-ftp-include
	echo '.htaccess.prod' > .git-ftp-ignore
	git add .
	git commit -m 'htaccess setup' > /dev/null
	push=$($GIT_FTP push)
	assertTrue ' .htaccess was ignored' "remote_file_exists '.htaccess'"
	assertFalse ' .htaccess.prod was uploaded' "remote_file_exists '.htaccess.prod'"
}

# addresses issue #41
test_include_similar() {
	cd $GIT_PROJECT_PATH
	echo 'unversioned' > foo.html
	echo '/foo.html' >> .gitignore
	echo 'foo.html:templates/foo.html' > .git-ftp-include
	mkdir templates
	echo 'new content' >> 'templates/foo.html'
	git add .
	git commit -m 'unversioned file foo.html should be uploaded with templates/foo.html' > /dev/null
	init=$($GIT_FTP init)
	assertTrue 'foo.html was not uploaded' "remote_file_exists 'foo.html'"
	assertTrue 'templates/foo.html was not uploaded' "remote_file_exists 'templates/foo.html'"
}

test_hidden_file_only() {
	cd $GIT_PROJECT_PATH
	echo "test" > .htaccess
	git add . > /dev/null 2>&1
	git commit -a -m "init" > /dev/null 2>&1
	init=$($GIT_FTP init)
	assertTrue 'test failed: .htaccess not uploaded' "remote_file_exists '.htaccess'"
}


test_file_with_nonchar() {
	cd $GIT_PROJECT_PATH
	echo "test" > ./#4253-Release Contest.md
	git add . > /dev/null 2>&1
	git commit -a -m "init" > /dev/null 2>&1

	init=$($GIT_FTP init)
	assertTrue 'test failed: #4253-Release Contest.md not uploaded' "remote_file_exists '#4253-Release Contest.md'"

	git rm './#4253-Release Contest.md' > /dev/null 2>&1
	git commit -a -m "delete" > /dev/null 2>&1

	push=$($GIT_FTP push)
	assertFalse 'test failed: #4253-Release Contest.md still exists in '$CURL_URL "remote_file_exists '\#4253-Release Contest.md'"
}

test_syncroot() {
	cd $GIT_PROJECT_PATH
	syncroot='foo bar'
	mkdir "$syncroot" && echo "test" > "$syncroot/syncroot.txt"
	git add . > /dev/null 2>&1
	git commit -a -m "syncroot test" > /dev/null 2>&1
	init=$($GIT_FTP init --syncroot "$syncroot")
	assertTrue 'test failed: syncroot.txt not there as expected' "remote_file_exists 'syncroot.txt'"
}

disabled_test_file_named_dash() {
	cd $GIT_PROJECT_PATH
	echo "foobar" > -
	assertTrue 'test failed: file named - not there as expected' "[ -f '$GIT_PROJECT_PATH/-' ]"
	git add . > /dev/null 2>&1
	git commit -a -m "file named - test" > /dev/null 2>&1
	init=$($GIT_FTP init)
	rtrn=$?
	assertEquals 0 $rtrn
}

remote_file_exists() {
	curl "$CURL_URL/$1" --head > /dev/null
}

remote_file_equals() {
	curl -s "$CURL_URL/$1" | diff - "$1" > /dev/null
}

assertContains() {
	assertTrue "Could not find expression: $1\nTested: $2" "echo \"$2\" | grep '$1'"
}

# load and run shUnit2
TESTDIR=$(dirname $0)
. $TESTDIR/shunit2-2.1.6/src/shunit2
