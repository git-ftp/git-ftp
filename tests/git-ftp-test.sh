#!/bin/sh

oneTimeSetUp() {
	cd "$TESTDIR/../"

	GIT_FTP_CMD="$(pwd)/git-ftp"
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
	assertEquals = "git-ftp version 1.1.0-develop"  "$version"
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

test_push_nothing() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	push=$($GIT_FTP_CMD push --dry-run -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $?
	oneline=$(echo $push)
	assertTrue "$push" "echo \"$push\" | grep 'There are 1 files to sync:'"
	echo 'test 1.txt' >> .git-ftp-ignore
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $?
	firstline=$(echo "$push" | head -n 1)
	assertEquals 'There are no files to sync.' "$firstline"
}

test_push_added() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	# add a file
	file='newfile.txt'
	echo "1" > "./$file"
	git add $file
	git commit -m "change" > /dev/null 2>&1
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $? || echo "Push: $push"
	assertEquals "1" "$(curl -s $CURL_URL/$file)"
}

test_push_twice() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $? || echo "First push: $push"
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $? || echo "Second push: $push"
	assertTrue "$push" "echo \"$push\" | grep 'Everything up-to-date.'"
}

test_push_unknown_sha1() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	# change remote SHA1
	echo '000000000' | curl -T - $CURL_URL/.git-ftp.log 2> /dev/null
	push=$(echo 'N' | $GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $?
	echo "$push" | grep 'Unknown SHA1 object' > /dev/null
	assertFalse ' test 1.txt uploaded' "remote_file_equals 'test 1.txt'"
}

test_push_unknown_sha1_Y() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	# make some changes
	echo "1" >> "./test 1.txt"
	git commit -a -m "change" > /dev/null 2>&1
	# change remote SHA1
	echo '000000000' | curl -T - $CURL_URL/.git-ftp.log 2> /dev/null
	push=$(echo 'Y' | $GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
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
	rtrn=$?
	assertEquals 0 $rtrn

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

	assertFalse 'test failed: file was not ignored' "remote_file_exists 'test 1.txt'"
}

test_ignore_dir() {
	cd $GIT_PROJECT_PATH
	echo "dir 1/.*" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: dir was not ignored' "remote_file_exists 'dir 1/test 1.txt'"
	assertTrue 'test failed: wrong dir was ignored' "remote_file_exists 'dir 2/test 2.txt'"
}

test_ignore_pattern() {
	cd $GIT_PROJECT_PATH
	echo "test" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	for i in 1 2 3 4 5
	do
		assertFalse 'test failed: was not ignored' "remote_file_exists 'test $i.txt'"
	done;
}

test_ignore_pattern_single() {
	cd $GIT_PROJECT_PATH
	echo 'test' > 'test'
	echo "^test$" > .git-ftp-ignore

	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)

	assertFalse 'test failed: was not ignored' "remote_file_exists 'test'"
	for i in 1 2 3 4 5
	do
		assertTrue 'test failed: was ignored' "remote_file_exists 'test $i.txt'"
	done;
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

test_include_init() {
	cd $GIT_PROJECT_PATH
	echo 'unversioned' > unversioned.txt
	echo 'unversioned.txt' >> .gitignore
	echo 'unversioned.txt:test 1.txt' > .git-ftp-include
	echo 'new content' >> 'test 1.txt'
	git add .
	git commit -m 'unversioned file unversioned.txt should be uploaded with test 1.txt' > /dev/null
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertTrue 'unversioned.txt was not uploaded' "remote_file_exists 'unversioned.txt'"
}

test_include_whitespace_init() {
	cd $GIT_PROJECT_PATH
	echo 'unversioned' > unversioned.txt
	echo 'unversioned.txt' >> .gitignore
	echo 'unversioned.txt:test X.txt' > .git-ftp-include
	git add .
	git commit -m 'unversioned file unversioned.txt should not be uploaded. test X.txt does not exist.' > /dev/null
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertFalse 'unversioned.txt was uploaded' "remote_file_exists 'unversioned.txt'"
}

test_include_push() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	echo 'unversioned' > unversioned.txt
	echo 'unversioned.txt' >> .gitignore
	echo 'unversioned.txt:test 1.txt' > .git-ftp-include
	echo 'new content' >> 'test 1.txt'
	git add .
	git commit -m 'unversioned file unversioned.txt should be uploaded with test 1.txt' > /dev/null
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
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
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertTrue ' .htaccess was ignored' "remote_file_exists '.htaccess'"
	assertFalse ' .htaccess.prod was uploaded' "remote_file_exists '.htaccess.prod'"
}

test_include_ignore_push() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	echo 'htaccess' > .htaccess
	echo 'htaccess.prod' > .htaccess.prod
	echo '.htaccess:.htaccess.prod' > .git-ftp-include
	echo '.htaccess.prod' > .gitignore
	git add .
	git commit -m 'htaccess setup' > /dev/null
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
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
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertTrue ' .htaccess was ignored' "remote_file_exists '.htaccess'"
	assertFalse ' .htaccess.prod was uploaded' "remote_file_exists '.htaccess.prod'"
}

test_include_ftp_ignore_push() {
	cd $GIT_PROJECT_PATH
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	echo 'htaccess' > .htaccess
	echo 'htaccess.prod' > .htaccess.prod
	echo '.htaccess:.htaccess.prod' > .git-ftp-include
	echo '.htaccess.prod' > .git-ftp-ignore
	git add .
	git commit -m 'htaccess setup' > /dev/null
	push=$($GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
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
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertTrue 'foo.html was not uploaded' "remote_file_exists 'foo.html'"
	assertTrue 'templates/foo.html was not uploaded' "remote_file_exists 'templates/foo.html'"
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

test_download() {
	cd $GIT_PROJECT_PATH
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	echo 'foreign content' > external.txt
	curl -T external.txt $CURL_URL/ 2> /dev/null
	rtrn=$?
	assertEquals 0 $rtrn
	rm external.txt
	$GIT_FTP_CMD download -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	rtrn=$?
	assertEquals 0 $rtrn
	assertTrue ' external file not downloaded' "[ -r 'external.txt' ]"
}

test_download_syncroot() {
	cd $GIT_PROJECT_PATH
	mkdir foobar && echo "test" > foobar/syncroot.txt
	git add . > /dev/null 2>&1
	git commit -a -m "syncroot test" > /dev/null 2>&1
	init=$($GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD --syncroot foobar $GIT_FTP_URL)
	echo 'foreign content' > external.txt
	curl -T external.txt $CURL_URL/ 2> /dev/null
	rm external.txt
	$GIT_FTP_CMD download -u $GIT_FTP_USER -p $GIT_FTP_PASSWD --syncroot foobar/ $GIT_FTP_URL > /dev/null 2>&1
	rtrn=$?
	assertEquals 0 $rtrn
	assertFalse ' external file downloaded to git root' "[ -r 'external.txt' ]"
	assertTrue ' external file not downloaded to syncroot' "[ -r 'foobar/external.txt' ]"
}

test_pull() {
	cd $GIT_PROJECT_PATH
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	echo 'foreign content' > external.txt
	curl -T external.txt $CURL_URL/ 2> /dev/null
	rm external.txt
	echo 'own content' > internal.txt
	git add . > /dev/null 2>&1
	git commit -a -m "local modification" > /dev/null 2>&1
	$GIT_FTP_CMD pull -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	rtrn=$?
	assertEquals 0 $rtrn
	assertTrue ' external file not downloaded' "[ -r 'external.txt' ]"
}

test_pull_branch() {
	cd $GIT_PROJECT_PATH
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	echo 'foreign content' > external.txt
	curl -T external.txt $CURL_URL/ 2> /dev/null
	rm external.txt
	echo 'own content' > internal.txt
	git add . > /dev/null 2>&1
	git commit -a -m "local modification" > /dev/null 2>&1
	git checkout -b deploy-branch > /dev/null 2>&1
	echo '1' > version.txt
	git add -A .
	git commit -m 'branch modification' > /dev/null 2>&1
	$GIT_FTP_CMD pull -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	rtrn=$?
	assertEquals 0 $rtrn
	assertTrue ' external file not downloaded' "[ -r 'external.txt' ]"
	assertTrue ' version.txt of deploy-branch not found' "[ -r 'version.txt' ]"
	assertEquals '## deploy-branch' "$(git status -sb)"
}

test_pull_no_commit() {
	cd $GIT_PROJECT_PATH
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	echo 'foreign content' > external.txt
	curl -T external.txt $CURL_URL/ 2> /dev/null
	rm external.txt
	echo 'own content' > internal.txt
	git add . > /dev/null 2>&1
	git commit -a -m "local modification" > /dev/null 2>&1
	LOCAL_SHA1=$(git log -n 1 --pretty=format:%H)
	$GIT_FTP_CMD pull --no-commit -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	rtrn=$?
	assertEquals 0 $rtrn
	assertTrue ' external file not downloaded' "[ -r 'external.txt' ]"
	assertEquals $LOCAL_SHA1 $(git log -n 1 --pretty=format:%H)
}

test_push_pull_push() {
	cd $GIT_PROJECT_PATH
	echo "1\n2\n3" > numbers.txt
	git add .
	git commit -m 'three line file' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1\n1.5\n2\n3" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "1\n2\n2.5\n3" > numbers.txt
	git commit -a -m 'added 2.5' > /dev/null
	# push should fail: out of sync
	$GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	assertEquals 10 $?
	# pull should merge changes
	$GIT_FTP_CMD pull -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	echo "1\n1.5\n2\n2.5\n3" | diff numbers.txt -
	assertEquals 0 $?
	# now push should pass
	$GIT_FTP_CMD push -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	assertEquals 0 $?
}

test_push_ignore_remote_changes() {
	cd $GIT_PROJECT_PATH
	echo "123" > numbers.txt
	git add .
	git commit -m 'three numbers' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1234" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "0123" > numbers.txt
	git commit -a -m 'added zero' > /dev/null
	$GIT_FTP_CMD push --ignore-remote-changes -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	assertEquals 0 $?
	assertEquals "0123" "$(curl -s $CURL_URL/numbers.txt)"
}

test_push_ignore_remote_changes_force() {
	cd $GIT_PROJECT_PATH
	echo "123" > numbers.txt
	git add .
	git commit -m 'three numbers' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1234" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "0123" > numbers.txt
	git commit -a -m 'added zero' > /dev/null
	$GIT_FTP_CMD push -f -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null 2>&1
	assertEquals 0 $?
	assertEquals "0123" "$(curl -s $CURL_URL/numbers.txt)"
}

test_push_interactive_skip() {
	cd $GIT_PROJECT_PATH
	echo "123" > numbers.txt
	git add .
	git commit -m 'three numbers' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1234" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "0123" > numbers.txt
	git commit -a -m 'added zero' > /dev/null
	# push should ask when interactive
	push=$(echo 'S' | $GIT_FTP_CMD push --interactive -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $?
	assertEquals "0123" "$(cat numbers.txt)"
	assertEquals "1234" "$(curl -s $CURL_URL/numbers.txt)"
}

test_push_interactive_skip_similar() {
	cd $GIT_PROJECT_PATH
	echo "123" > numbers.txt
	echo "456" > numbers_txt
	git add .
	git commit -m 'six numbers' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1234" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "0123" > numbers.txt
	echo "4567" > numbers_txt
	git commit -a -m 'added zero' > /dev/null
	# push should ask when interactive
	push=$(echo 'S' | $GIT_FTP_CMD push --interactive -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals 0 $?
	assertEquals "0123" "$(cat numbers.txt)"
	assertEquals "1234" "$(curl -s $CURL_URL/numbers.txt)"
	assertEquals "4567" "$(curl -s $CURL_URL/numbers_txt)"
}

test_push_interactive_overwrite() {
	cd $GIT_PROJECT_PATH
	echo "123" > numbers.txt
	git add .
	git commit -m 'three numbers' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1234" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "0123" > numbers.txt
	git commit -a -m 'added zero' > /dev/null
	# push should ask when interactive
	push=$(echo 'O' | $GIT_FTP_CMD push --interactive -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals "0123" "$(cat numbers.txt)"
	assertEquals "0123" "$(curl -s $CURL_URL/numbers.txt)"
}

test_push_interactive_download() {
	cd $GIT_PROJECT_PATH
	echo "123" > numbers.txt
	git add .
	git commit -m 'three numbers' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1234" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "0123" > numbers.txt
	git commit -a -m 'added zero' > /dev/null
	# push should ask when interactive
	push=$(echo 'D' | $GIT_FTP_CMD push --interactive -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals "1234" "$(cat numbers.txt)"
	assertEquals "1234" "$(curl -s $CURL_URL/numbers.txt)"
}

test_push_interactive_never() {
	cd $GIT_PROJECT_PATH
	echo "123" > numbers.txt
	git add .
	git commit -m 'three numbers' > /dev/null
	$GIT_FTP_CMD init -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL > /dev/null
	sleep 1 # otherwise the timestamp will be the same
	echo "1234" > numbers.txt
	curl -T numbers.txt $CURL_URL/ 2> /dev/null
	echo "0123" > numbers.txt
	git commit -a -m 'added zero' > /dev/null
	# push should ask when interactive
	push=$(echo 'N' | $GIT_FTP_CMD push --interactive -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals "0123" "$(cat numbers.txt)"
	assertEquals "1234" "$(curl -s $CURL_URL/numbers.txt)"
	# change again and verify it doesn't get uploaded
	echo "01234" > numbers.txt
	git commit -a -m 'added four' > /dev/null
	push=$(echo 'O' | $GIT_FTP_CMD push --interactive -u $GIT_FTP_USER -p $GIT_FTP_PASSWD $GIT_FTP_URL)
	assertEquals "01234" "$(cat numbers.txt)"
	assertEquals "1234" "$(curl -s $CURL_URL/numbers.txt)"
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
	curl "$CURL_URL/$1" --head > /dev/null
}

remote_file_equals() {
	curl -s "$CURL_URL/$1" | diff - "$1" > /dev/null
}

# load and run shUnit2
TESTDIR=$(dirname $0)
. $TESTDIR/shunit2-2.1.6/src/shunit2
