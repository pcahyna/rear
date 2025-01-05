datadir ?= /usr/share
# Dirs that will get packed as .tar.gz and installed instead of being installed
# as they are. Handy for shipping files that need special attributes not
# preserved by Git, as well as symlinks (to avoid pitfalls when replacing
# directories by synlinks during package upgrade with some package managers,
# https://docs.fedoraproject.org/en-US/packaging-guidelines/Directory_Replacement/ )
# Since the archives afre created merely by packing what is in the source tree,
# using this feature for special attributes would need more special handling
# (like --mode= or --owner arguments to tar).
# Creating the archives dynamically from the source tree avoids having binary files
# (.tar.gz) in the source tree.
archivedirs = GNU/Linux Debian/default
# Names of the archive dirs when copied to the install destination.
# We do not want them there.
destarchivedirs := $(addprefix $(DESTDIR)$(datadir)/rear/skel/,$(archivedirs))
# Names of the archives containing parts of the rescue image skeleton.
# We build the archives dynamically during build by packing the archive dirs.
archives := $(addsuffix .tar.gz,$(archivedirs))

%.tar.gz : %
	tar -czf $@ -C $< .

# rm of the Makefile is a dirty hack to avoid having the Makefile in the installation
# destination while being able to install via a simple copy of the entire directory
# in the main Makefile. Ditto for removing $(destarchivedirs).
# (.gitignore is being treated the same way in the main Makefile.)
install: $(archives)
	-rm -rf $(destarchivedirs)
	-rm -f $(DESTDIR)$(datadir)/rear/skel/Makefile
	for a in $^; do \
		install -t $(DESTDIR)$(datadir)/rear/skel/$$(dirname $$a) $$a ; \
	done
