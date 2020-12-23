#!/bin/bash

cd gfx2gfx-pdftext

# Apply patch to add a progressbar to the output
patch -p1 -f -i - <<EOF
--- a/src/gfx2gfx.c	2016-03-13 01:08:14.000000000 +0100
+++ b/src/gfx2gfx.c	2016-03-13 01:09:13.000000000 +0100
@@ -177,6 +177,19 @@
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
@@ -282,6 +295,12 @@
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

echo "gfx2gfx-pdftext is patched with progress indicator."
