INSTALL
=======

Ubuntu PPA (Personal Package Archive) Repository
------------------------------------------------
Adding on Ubuntu 10.04 (Lucid)

	$ sudo -s
	# add-apt-repository ppa:resmo/git-ftp
	# aptitude update
	# aptitude install git-ftp

Note: Usually updated after every release (tag).

Windows
-------
There are at least two ways to install git-ftp on Windows.

 * Using cygwin only
 * Using cygwin and msysgit (recommended)

First install cygwin and install the package 'curl'.
If you like to use cygwin only, install package 'git',
otherwise install msysgit.

After this, open git bash (or cygwin bash for cygwin only):

	$ git clone http://github.com/resmo/git-ftp git-ftp.git
	$ cd git-ftp.git && chmod +x git-ftp
	$ cd /bin/
	$ ln -s ~/git-ftp.git/git-ftp git-ftp

Note: Option -p without argument is showing password while entering.


Upstream using git
-------------------
Make sure git and curl is installed.

	# aptitude install git-core curl

The easiest way is to use git for installing:

	$ mkdir -p ~/dev/git-ftp.git
	$ cd ~/dev/git-ftp.git
	$ git clone http://github.com/resmo/git-ftp.git .
	$ chmod +x git-ftp
	$ mkdir ~/bin && cd ~/bin/
	$ ln -s ~/dev/git-ftp.git/git-ftp git-ftp

After this you can use 'git ftp' or 'git-ftp'

Update to the latest version is simple as:

	$ cd ~/dev/git-ftp.git
	$ git pull
