require 'formula'

class DbusCxx <Formula
  head 'git://gitorious.org/dbus-cplusplus/mainline.git'
  homepage 'http://git-wt-commit.rubyforge.org/'
  # Don't clean the empty directories that D-Bus needs
  skip_clean "etc/dbus-1/session.d"
  skip_clean "etc/dbus-1/system.d"
  skip_clean "var/run/dbus"

  depends_on 'd-bus'
  depends_on :automake
  depends_on :autoconf
  depends_on :libtool
  depends_on "glib"
  depends_on "pkg-config"
 # depends_on 'libpthread'
  def install
    # Fix the TMPDIR to one D-Bus doesn't reject due to odd symbols
    ENV["TMPDIR"] = "/tmp"
    inreplace 'bootstrap', 'libtool', 'glibtool'
    inreplace 'examples/echo/echo-server.cpp', 'HOST_NAME_MAX', "_POSIX_HOST_NAME_MAX"
    inreplace 'src/eventloop.cpp', 'PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP', 'PTHREAD_RECURSIVE_MUTEX_INITIALIZER'
    system "autoreconf -sif"
    system "./configure", "--disable-ecore", "--prefix=#{prefix}", "--disable-doxygen-docs"
    # Need to add <unistd.h> to get unix headers
    # and need to apply the patch from https://code.google.com/p/chromium/issues/detail?id=217426
    system "make install"

    # Generate D-Bus's UUID for this machine
    #system "#{bin}/dbus-uuidgen", "--ensure=#{prefix}/var/lib/dbus/machine-id"
  end
end
  
