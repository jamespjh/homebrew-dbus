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
  def patches
    DATA
  end
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
__END__  
diff --git a/include/dbus-c++/dispatcher.h b/include/dbus-c++/dispatcher.h
index b5b5536..e95402d 100644
--- a/include/dbus-c++/dispatcher.h
+++ b/include/dbus-c++/dispatcher.h
@@ -25,10 +25,15 @@
 #ifndef __DBUSXX_DISPATCHER_H
 #define __DBUSXX_DISPATCHER_H
 
+#ifdef HAVE_CONFIG_H
+#include <config.h>
+#endif
+
 #include "api.h"
 #include "connection.h"
 #include "eventloop.h"
 
+
 namespace DBus
 {

diff --git a/include/dbus-c++/types.h b/include/dbus-c++/types.h
index 044e72b..24bbfa4 100644
--- a/include/dbus-c++/types.h
+++ b/include/dbus-c++/types.h
@@ -316,7 +316,7 @@ struct type< Struct<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14,
   }
 };
 
-} /* namespace DBus */
+
 
 inline DBus::MessageIter &operator << (DBus::MessageIter &iter, const DBus::Invalid &)
 {
@@ -645,6 +646,8 @@ inline DBus::MessageIter &operator >> (DBus::MessageIter &iter, DBus::Struct<T1,
 }
 
 extern DXXAPI DBus::MessageIter &operator >> (DBus::MessageIter &iter, DBus::Variant &val);
-
+//Moved due to 
+//http://clang.llvm.org/compatibility.html#dep_lookup
+} /* namespace DBus */
 #endif//__DBUSXX_TYPES_H
 diff --git a/src/eventloop-integration.cpp b/src/eventloop-integration.cpp
 index 0cc65c3..1c9fb57 100644
 --- a/src/eventloop-integration.cpp
 +++ b/src/eventloop-integration.cpp
 @@ -23,7 +23,7 @@

  #ifdef HAVE_CONFIG_H
  #include <config.h>
 -#endif
 +#endif //HAVE_CONFIG_H

  /* Project */
  #include <dbus-c++/eventloop-integration.h>
 @@ -38,6 +38,9 @@
  #include <cassert>
  #include <sys/poll.h>
  #include <fcntl.h>
 +#ifdef HAVE_UNISTD_H
 +#include <unistd.h>
 +#endif //HAVE_UNISTD_H

  using namespace DBus;
  using namespace std;
diff --git a/include/dbus-c++/pipe.h b/include/dbus-c++/pipe.h
index 999f042..41d3629 100644
--- a/include/dbus-c++/pipe.h
+++ b/include/dbus-c++/pipe.h
@@ -29,6 +29,9 @@
 
 /* STD */
 #include <cstdlib>
+#ifdef HAVE_UNISTD_H
+#include <unistd.h>
+#endif //HAVE_UNISTD_H
 
 namespace DBus
 {
diff --git a/src/types.cpp b/src/types.cpp
index d414a3e..9b64fd5 100644
--- a/src/types.cpp
+++ b/src/types.cpp
@@ -75,6 +75,8 @@ const Signature Variant::signature() const
   return signature;
 }
 
+namespace DBus {
+
 MessageIter &operator << (MessageIter &iter, const Variant &val)
 {
   const Signature sig = val.signature();
@@ -103,4 +105,5 @@ MessageIter &operator >> (MessageIter &iter, Variant &val)
 
   return ++iter;
 }
+}
 
diff --git a/test/functional/Test1/TestApp.cpp b/test/functional/Test1/TestApp.cpp
index 0dcaac5..5564495 100644
--- a/test/functional/Test1/TestApp.cpp
+++ b/test/functional/Test1/TestApp.cpp
@@ -9,6 +9,11 @@
 #include "TestApp.h"
 #include "TestAppIntro.h"
 
+#ifdef __MACH__
+#include <mach/clock.h>
+#include <mach/mach.h>
+#endif
+
 using namespace std;
 
 DBus::BusDispatcher dispatcher;
@@ -70,8 +75,17 @@ void *TestApp::testThreadRunner(void *arg)
     mTestToDBusPipe->write(testString.c_str(), testString.length() + 1);
 
     struct timespec abstime;
-
-    clock_gettime(CLOCK_REALTIME, &abstime);
+    #ifdef __MACH__ // OS X does not have clock_gettime, use clock_get_time
+      clock_serv_t cclock;
+      mach_timespec_t mts;
+      host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
+      clock_get_time(cclock, &mts);
+      mach_port_deallocate(mach_task_self(), cclock);
+      abstime.tv_sec = mts.tv_sec;
+      abstime.tv_nsec = mts.tv_nsec;
+    #else
+      clock_gettime(CLOCK_REALTIME, &abstime);
+    #endif
     abstime.tv_sec += 1;
 
     pthread_mutex_lock(&clientMutex);