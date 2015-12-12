SHELL=/bin/sh

# files that need mode 644
MAN_FILE=git-ftp.1
HTML_FILE=html/git-ftp.html

all:
	@echo "usage: make man"
	@echo "       make clean"
man:
	pandoc -s \
		-w man git-ftp.1.md \
		-o  $(MAN_FILE)
man-ronn:
	ronn --roff --pipe \
		git-ftp.1.md \
		> $(MAN_FILE)
html:
	pandoc -s -S --toc \
		-c git-ftp.css git-ftp.1.md \
		-o $(HTML_FILE)
clean:
	rm -f $(MAN_FILE)
	rm -f $(HTML_FILE)
