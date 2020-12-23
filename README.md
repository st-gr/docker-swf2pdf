# swf2pdf
A debian buster based docker image to convert Adobe shockwave SWF to PDF.
## TL;DR
Good luck!
## How to build
The build takes a long time and will download approximately 1.3 GB of files.
It compiles the out of maintenance SWFTOOLS utility.  
SWFTOOLS relies on PDFlib-light which is not available any more.  So, if you were lucky as I then you secured a local copy :)

That is why there is the `src` folder.
If it contains the following files then no attempt will be made to download them:
- `PDFlib-Lite-7.0.5p3.tar.gz`
  - this library is used by gfx2gfx to create a PDF.  It is not available any more.
- `swftools-0.9.2.tar.gz`
  - this is the last/latest version of SWFTOOLS without the gfx2gfx command line tool which we however need to convert SWF to PDF.  That is why there are two additional versions used as follows:
- `gfx2gfx-pdftext.tar.gz`
  - this one converts SWF into PDF with searchable content, but less accurate.
- `swftools.tar.gz`
  - this converts the SWF into a print quality PDF, but no searchable text.

The `fonts` folder is used during the build phase to copy TTF fonts required by you into the runtime image.

The `scripts` folder contains the `swf2pdf.sh` script that executes the SWF to PDF conversion from within the runtime container.  It makes use of `swfcombine` to merge multiple SWF into one file and then two versions of `gfx2gfx` for the PDF generation.

>Note: The dockerfile contains some scary BASE64 encoded inline file(s).  I had to do this as I could not get the commands to successfully build the source when called from within the dockerfile.  Please convert the BASE64 string to a tar.gz file and validate that there is no magic there.

The build is tested under Linux kernel 4.19.0-13-amd64 and  docker version 20.10.1, build 831ebea .

Steps to download and build:
1. First clone the repo:
   >`git clone https://github.com/st-gr/docker-swf2pdf`
2. change the directory to the folder where you cloned the repo to, e. g.
   >`cd docker-swf2pdf`
3. Start the build
   >`docker build -t st-gr/swf2pdf .`
4. Wait.  If everything goes well you have a new docker image with the tagname you chose, e. g. st-gr/swf2pdf, validate with:
   > `docker image list`

You will find an additional docker image named `<none>` and the size of about 1.25 GB.  It is the build image of the multistage build.  You can delete it by using its ID which you retrieved from the previously executed `docker image list` command, e. g.
> `docker image rm -f 46b4c4c5d90c`
(Your ID will be different!)

The build might fail if the source packages mentioned above were changed as I patch some sources on the fly; namely, `swftools/src/gfx2gfx.c` and `gfx2gfx-pdftext/src/gfx2gfx.c`.
## How to use
For the examples below our local folder with the SWF files is in the user profile under `Documents/myswfs`.

The folder contains Adobe flash files named `page0001.swf` to `page 0nnn.swf`.

### Create a PDF print version of the SWF files use
>`docker run --rm -it -v ~/Documents/myswfs:/home/swf/work st-gr/swf2pdf ./swf2pdf.sh work/myswfs/page0*.swf`

This docker command will run the script `swf2pdf.sh` and map the volume path to `/home/swf/work` in the docker container.  The container will be removed (`--rm`) after the container completed the execution.

### Create a searchale PDF text version of the SWF files
We are going to pass the `-t` option for text output to the script.
We are also using the `-r` option to change the dpi to 300 from the default 200 dpi and finally we are going to change the output filename with the `-o` option.

>`docker run --rm -it -v ~/Documents/myswfs:/home/swf/work st-gr/swf2pdf ./swf2pdf.sh -t -r 300 -o pdftext.pdf work/myswfs/page0*.swf`

The generated PDF contains searchable text at the cost of precision.  The PDF file will be smaller compared to the print version.

### Output
The single SWF files will be merged into one PDF named after the folder.  In our example `myswfs.pdf` inside the same folder as the single SWF files.

## Wish list
If there is a future version then it should make use of a more lightweight docker base image for the runtime, e. g. `busybox:glibc`.

Also some layer optimization should take place to reduce the size of the runtime.

The local fonts folder should be mounted read-only and the font cache in the container updated before the script starts.  However, depending on how many fonts you have this could take a while.

Replace the inline BASE64 file with a working dockerfile embedded version.
