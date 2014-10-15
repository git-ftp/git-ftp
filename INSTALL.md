INSTALL
=======

Stable on Linux/Unix based systems using make
---------------------------------------------

Note: Make sure Git and cURL are installed.

This should work on Mac OS X, Debian, Ubuntu, Fedora, RedHat, etc.

The easiest way is to use Git for installing:

	$ git clone https://github.com/git-ftp/git-ftp.git
	$ cd git-ftp
	$ git tag # see available tags
	$ git checkout <tag> # checkout the latest tag by replacing <tag>
	$ sudo make install

Updating using git

	$ git pull
	$ git tag # see available tags
	$ git checkout <tag> # checkout the latest tag by replacing <tag>
	$ sudo make install


Debian official
---------------
See http://packages.qa.debian.org/g/git-ftp.html


Ubuntu official
---------------
See https://launchpad.net/ubuntu/+source/git-ftp


Ubuntu PPA (Personal Package Archive) repository
------------------------------------------------
Adding PPA on Ubuntu

	$ sudo -s
	# add-apt-repository ppa:resmo/git-ftp
	# aptitude update
	# aptitude install git-ftp

Note: Usually updated after every release (tag).


ArchLinux (AUR: unofficial)
---------------------------
See https://aur.archlinux.org/packages/?O=0&C=0&SeB=nd&K=git-ftp&SB=v&SO=d&PP=50&do_Search=Go 


Mac OS X
--------
Using homebrew:

	# brew install git
	# brew install curl --with-ssl --with-ssh
	# brew install git-ftp

Windows
-------
There are at least two ways to install git-ftp on Windows.

 * Using cygwin
 * Using msysgit (recommended)

### cygwin

Install cygwin and install the package 'curl'.

### msysgit

Install msysgit. It comes with 'curl' installed by default, however it doesn't support SFTP by default.
In order to use SFTP, download curl for Windows with SFTP support on the [curl website]( http://curl.haxx.se/download.html). Win32 2000/XP MSI or Win64 2000/XP x86_64 MSI is recommended. Then in your msysgit installation folder, remove bin/curl.exe. This will allow for all calls to curl to fall back from Git's curl to the one you just installed that also supports SFTP.

After this, open git bash (or cygwin bash for cygwin only):

	$ cd ~
	$ git clone https://github.com/git-ftp/git-ftp
	$ cd git-ftp && chmod +x git-ftp
	$ cd /bin
	$ ln -s ~/git-ftp/git-ftp

*Note: the /bin/ directory is a alias, and if you use msysgit this is the same as C:\Program Files (x86)\Git\bin\*


Upstream using symlinking
-------------------------

This usually works on Linux based systems, but not on Mac OS X without extending $PATH.

Note: Make sure Git and cURL is installed.

This is a easy way to have more then one git-ftp installed

	$ mkdir -p ~/develop/git-ftp.git
	$ cd ~/develop/git-ftp.git
	$ git clone https://github.com/git-ftp/git-ftp.git .
	$ chmod +x git-ftp
	$ mkdir ~/bin && cd ~/bin/
	$ ln -s ~/develop/git-ftp.git/git-ftp git-ftp.dev

After this you can use 'git ftp.dev' or 'git-ftp.dev'

Update to the latest version is simple as:

	$ cd ~/develop/git-ftp.git
	$ git pull
