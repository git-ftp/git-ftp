# INSTALL

You can find instructions for:

- [Linux/Unix based systems using make](#linuxunix-based-systems-using-make)
- [Debian, Ubuntu and others using apt](#debian-ubuntu-and-others-using-apt)
- [ArchLinux](#archlinux-aur-unofficial)
- [Mac OS X](#mac-os-x)
- [Windows](#windows)


## Linux/Unix based systems using make

Note: Make sure Git and cURL are installed.

This should work on Mac OS X, Debian, Ubuntu, Fedora, RedHat, etc.

The easiest way is to use Git for installing:

```sh
git clone https://github.com/git-ftp/git-ftp.git
cd git-ftp

# choose the newest release
tag="$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)"

# checkout the latest tag
git checkout "$tag"
sudo make install
```

Updating using git:

```sh
git fetch
git checkout "$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)"
sudo make install
```


## Debian, Ubuntu and others using apt

At least Debian and Ubuntu provide git-ftp in their main repositories.

```sh
sudo apt-get install git-ftp
```

If you would like the newest release maintained by Git-ftp,
you can add the PPA:

```sh
sudo -s
add-apt-repository ppa:git-ftp/ppa

# On Debian, you need to modify the sources list to use the same PPA
source /etc/*-release
if [ "$ID" = "debian" ]; then
    dist="$(echo /etc/apt/sources.list.d/git-ftp-ppa-*.list | sed 's/^.*ppa-\(.*\)\.list$/\1/')"
    sed -i.backup "s/$dist/precise/g" /etc/apt/sources.list.d/git-ftp-ppa-*.list
fi

apt-get update
```


## ArchLinux (AUR: unofficial)

See https://aur.archlinux.org/packages/?O=0&C=0&SeB=nd&K=git-ftp&SB=v&SO=d&PP=50&do_Search=Go


## Mac OS X

Using homebrew:

```sh
brew install git
brew install curl --with-ssl --with-libssh2
brew install git-ftp
```

## Windows

There are at least two ways to install git-ftp on Windows.

- Using cygwin
- Using msysgit (recommended)

### cygwin

Install cygwin and install the package 'curl'.

### msysgit

Install msysgit. It comes with 'curl' installed by default, however it doesn't support SFTP by default.
In order to use SFTP, download curl for Windows with SFTP support on the [curl website]( http://curl.haxx.se/download.html). Win32 2000/XP MSI or Win64 2000/XP x86_64 MSI is recommended. Then in your msysgit installation folder, remove bin/curl.exe. This will allow for all calls to curl to fall back from Git's curl to the one you just installed that also supports SFTP.

After this, open git bash (or cygwin bash for cygwin only):

```bash
curl https://raw.githubusercontent.com/git-ftp/git-ftp/develop/git-ftp > /bin/git-ftp
chmod +x /bin/git-ftp
```

*Note: the /bin/ directory is a alias, and if you use msysgit this is the same as C:\Program Files (x86)\Git\bin\*

### msysgit with installed cygwin

If you have both msysgit and cygwin installed on Windows and want to use msysgit for git commands, you may get an error "No such file or directory" for a path starting "/cygdrive/"; e.g.:

    creating `/cygdrive/c/TEMP/git-ftp-m7GH/delete_tmp': No such file or directory

The problem is that git-ftp use commands from both cygwin and msysgit folders, but cygwin is by default configured to start paths with "/cygdrive" prefix while msysgit starts paths with "/". To fix the problem, open file "<cygwin>\etc\fstab" (e.g. "c:\cygwin\etc\fstab") and change parameter "/cygwin/" to "/"; e.g.:

    # This is default:
    none /cygdrive/ cygdrive binary,posix=0,user 0 0

change to:

    # This is default:
    none / cygdrive binary,posix=0,user 0 0

After this, close all console windows and try again.
