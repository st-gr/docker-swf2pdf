#!/bin/bash

# Git is required here to download sources
# Remove folder if exist
rm -rf ./swftools
#git clone --depth=1 git://github.com/matthiaskramm/swftools ./swftools
tar -xvsf swftools.tar.gz
cd swftools

# Apply patch by @m-p-y
patch -p1 -f -i - <<EOF
diff -ur a/Makefile.in b/Makefile.in
--- a/Makefile.in	2016-03-13 01:08:14.000000000 +0100
+++ b/Makefile.in	2016-03-13 01:09:13.000000000 +0100
@@ -1,3 +1,4 @@
+vpath = src
 top_builddir = ..
 srcdir = @srcdir@
 top_srcdir = @top_srcdir@
diff -ur a/src/gfx2gfx.c b/src/gfx2gfx.c
--- a/src/gfx2gfx.c	2016-03-13 01:08:14.000000000 +0100
+++ b/src/gfx2gfx.c	2016-03-13 01:09:13.000000000 +0100
@@ -83,6 +83,11 @@
 	maxdpi = val;
 	return 1;
     }
+	else if (!strcmp(name, "r"))
+    {
+           maxdpi = val;
+               return 1;
+    }
     else if (name[0]=='p')
     {
 	do {
@@ -173,6 +178,19 @@
 {
 }

+/* BEGIN sgr add progress bar */
+#define PBSTR "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
+#define PBWIDTH 60
+
+void printProgress(double percentage) {
+    int val = (int) (percentage * 100);
+    int lpad = (int) (percentage * PBWIDTH);
+    int rpad = PBWIDTH - lpad;
+    printf("\r%3d%% [%.*s%*s]", val, lpad, PBSTR, rpad, "");
+    fflush(stdout);
+}
+/* END sgr add progress bar */
+
 int main(int argn, char *argv[])
 {
     processargs(argn, argv);
@@ -278,6 +296,12 @@
         int pagenr;
         for(pagenr = 1; pagenr <= doc->num_pages; pagenr++)
         {
+/* BEGIN sgr progressbar */
+            if(loglevel >= 3) {
+                printProgress((double)pagenr / (double)doc->num_pages);
+                if(pagenr == doc->num_pages) printf("\n");
+            }
+/* END sgr progressbar */
             if(is_in_range(pagenr, pagerange)) {
                 gfxpage_t* page = doc->getpage(doc, pagenr);
                 out->startpage(out, page->width, page->height);
EOF

ldconfig /usr/local/lib
./configure
make
cd lib
make
cd ../src
make gfx2gfx
echo "gfx2gfx bin should be compiled in $(pwd)"
