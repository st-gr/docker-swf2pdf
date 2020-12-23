# Dockerimage with SWFTOOLS to convert flash swf files to pdf using gfx2gfx
# cd docker-swf2pdf
# docker build -t st0gr/swf2pdf:latest .
#
# Usage:
# ======
# to create a print version of the swf to pdf use
# docker run --rm -it -v ~/Documents/myswfs:/home/swf/work st0gr/swf2pdf ./swf2pdf.sh work/myswfs/page0*.swf
#
# to create a text version of the swf to pdf use (less accurate, but searchable)
# docker run --rm -it -v ~/Documents/myswfs:/home/swf/work st0gr/swf2pdf ./swf2pdf.sh -t work/myswfs/page0*.swf

FROM debian:buster AS swf-builder

LABEL version="1.0"
LABEL maintainer="https://github.com/st-gr"
LABEL description="Build image for swf2pdf"

ARG buildPath=/root/swf
ARG libPath=/usr/local/lib
ARG binPath=/usr/local/bin

WORKDIR $buildPath

# use local folder of downloaded 3rd party software
COPY src/*.tar.gz ${buildPath}/

# set -ex stop at error (e) and show output (x)
RUN set -ex && \
        apt-get update && \
        apt-get install -y \
        # build tools like gcc
        build-essential \
        # to get source
        wget \
        git \
        # to compile swftools
        zlib1g-dev \
        libjpeg-dev \
        libpng-dev \
        libgif-dev \
        libfreetype6-dev \
        libfontconfig-dev \
        libfftw3-dev \
        libzzip-dev \
        libpoppler-dev \
        # for TTF fonts call fc-cache -f -v to renew fonts cache for fonts in /usr/local/share/fonts
        fontconfig

RUN set -eux; \
        # check if 3rd party software is available, otherwise download it
        ! [ -f PDFlib-Lite-7.0.5p3.tar.gz ] && wget https://web.archive.org/web/20121002191453if_/http://www.pdflib.com/binaries/PDFlib/705/PDFlib-Lite-7.0.5p3.tar.gz || : && \
        ! [ -f swftools-0.9.2.tar.gz ] && wget http://www.swftools.org/swftools-0.9.2.tar.gz || : && \
        ! [ -f gfx2gfx-pdftext.tar.gz ] && git clone https://yingtongli.me/git/gfx2gfx-pdftext && tar -czvf gfx2gfx-pdftext.tar.gz gfx2gfx-pdftext || : && \
        ! [ -f swftools.tar.gz ] && git clone --depth=1 git://github.com/matthiaskramm/swftools ./swftools && tar -czvf swftools.tar.gz swftools || :

# download and build PDFlib Lite 7.0.5 from web.archive.org as the newer version is not
# free anymore
RUN set -ex && \
        cd ${buildPath} && \
        # use local copy during test phase of dockerfile
        #wget https://web.archive.org/web/20121002191453if_/http://www.pdflib.com/binaries/PDFlib/705/PDFlib-Lite-7.0.5p3.tar.gz && \
        tar -xf PDFlib-Lite-7.0.5p3.tar.gz && \
        cd PDFlib-Lite-7.0.5p3 && \
        ./configure && \
        make && \
        make install

# build gfx2gfx = swf to pdf with font to glyph conversion
# make use of slightly modified script from https://gist.github.com/mems/5301297
RUN set -ex && \
        cd ${buildPath} && \
        echo \
H4sIAA8X4l8AA+2WWW/cNhCA/Wr+ism6RlbWScv2+sga2yBumoemQRqgD65haCVKIqIrpLS26/q/\
d6jDe7huUTRoUYAfYEszHJJzkdo8+MxseRPXZZlJO4lv9/HPkenWV8RDJoeH6kknh97qU+FPfLpF\
/cnEO6C+d+RvefSQUn8LvK/pxHM0sg4EwJasWRwUz9v91fj/lJ0X7pwX7jyQKSE78JbXwCUI9qXh\
gkWQMsGgLiEqb4qsDCKQZSNCJtH0I8vLBYO4zCImgMfAbrmsicjBFjE47tBUZCfBRcOsLBjYdsSq\
Op1SQN2p6+L/tJk7YZm7eVDXKQ/kZxHk+ePk1XVUnezbhYxhUDmocpJfSRg9qlQQ31ZVdgdVUIcp\
zO9gltuVfUc62a4o2DHYHGx49erix+9IxGOUGwGB+wMehphnzOEFzFclYtv2+vj2vkePbM+3qQ8e\
PfWOT+mB4w2A6VHPI6Zprq+zOevklPpPZs1mYFPLB5NaBzCbEXOBrqcwBSlCgsWorucNz6KIC9Q5\
DlH6Tph1b7POaqleSrPVcFHlDic+REfX5D7kNd3fCPpP5z0b9rFvHYGJ/ylVkcN2HtxGFccYFkF2\
hrJgdSMKoPiueCDmNsskU+03fiFrEebVuAhyZsFIjAyDmMrqvnv0rC+5OqJYbmB2G7Taxz3U2pfe\
1XT6snppdGP36FZU4qOt26SNgE6OLXrShoDDD4SY7h68vnj77j3IBFMfRVCJMhFMSphjW++5xNyJ\
sEvwjHx4/dOnjzD67R8wWl3t53dvPn0PR1gY7KSSq515UX/otx9HZTPPGFQMj3VRBwkzhnyhlcoR\
ZmqMrwaMlzawB1gy42xpmFV4OfyxZe/CqrXorAfn7HZ6P966F49Hv4hdP9rdhctdZ0/u7smrkaXc\
sVpbq0uT1a6ExR4Nq8dx1sh0LGuMq1bKhzb3F+/fPJ950vqUB7xQ7kMgksKCMFWj+L64vDLaMnbO\
lXj7SVTLcWenLHAfVfx9rDoWf//kyKL7bfEH1LIVZqMQZ0tlXIpxp8RU0LPeAF5N8bYN7fOiya+V\
Sg4jpmksJ99vtNQQ1BDTak/zeJyVScYWLIPzKfjGxomAx7Q/dkXfFkbvkwuDYt014+kBUrsNUW1G\
YiyLW4w2564XaiOezR24vObFtQiKhPW7WW2WWo1hDOVaBW8iZXFd77WW0DuXsFqJGF9o9Yk2zp7O\
xm6yz9VPhc4axc7aPr/hUZ0OQsp4kqq+U18WkkVhWcQ8AbeRws3KMMjcjM+J43b6RjCS49dBfcCU\
fnh3HHV/tiL0lyhhYVrCqJcAv9kg07LJIpgzwO9nhR+YCPsMvhlXN5ExIv/1DwuNRqPRaDQajUaj\
0Wg0Go1Go9FoNBqNRqPR/Kv8Dlek9vAAKAAA\
        | base64 --decode | tar zxf - && \
        ./make-swftools-gfx2gfx.sh

# download and build swftools
RUN set -ex && \
        cd ${buildPath} && \
        # wget http://www.swftools.org/swftools-0.9.2.tar.gz && \
        tar xzvf swftools-0.9.2.tar.gz && \
        cd swftools-0.9.2/lib && \
        # adding these lines will prevent a compiler error
        sed -i '1 s/^/#include <stdbool.h>\n#define TRUE true\n#define FALSE false\n/' jpeg.c && \
        # replacing these function calls will prevent a syntax error
        cd ../src && \
        sed -i 's/DGifOpenFileName(\([a-z]*\)/DGifOpenFileName(\1,NULL/' gif2swf.c && \
        sed -i 's/DGifCloseFile(gft)/DGifCloseFile(gft,NULL)/g' gif2swf.c && \
        sed -i 's/PrintGifError();/\/\/PrintGifError();/g' gif2swf.c && \
        # prevent rm: invalid option -- 'o' in Makefile
        cd ../swfs && \
        sed -i 's/rm -f $(pkgdatadir)\/swfs\/default_viewer.swf -o -L $(pkgdatadir)\/swfs\/default_viewer.swf/rm -f $(pkgdatadir)\/swfs\/default_viewer.swf/g' Makefile.in && \
        sed -i 's/rm -f $(pkgdatadir)\/swfs\/default_loader.swf -o -L $(pkgdatadir)\/swfs\/default_loader.swf/rm -f $(pkgdatadir)\/swfs\/default_loader.swf/g' Makefile.in && \
        cd .. && \
        # https://lists.gnu.org/archive/html/swftools-common/2009-11/msg00083.html
        ldconfig /usr/local/lib && \
        ./configure && \
        make && \
        make install

# download and build gfx2gfx = swf to pdf with text, but no fonts
RUN set -ex && \
        cd ${buildPath} && \
        #git clone https://yingtongli.me/git/gfx2gfx-pdftext && \
        tar xzvf gfx2gfx-pdftext.tar.gz && \
        # patch gfx2gfx.c with additional progress indicator
        echo \
H4sIAJOd4l8AA+2UW0/bMBTH+7p8irOgSkkTt0kvBChUHYJtvDC0Ie2BoSpNnIuUJVHsFibGd5+d\
y1qCOh6YNE06P6lKffK3zzXOXe5FhN0FPMsSRsLgfih+JPcDTu95n0Wd12MJnMlEPm1nYm0/JcPx\
2OnYI8exJvbEccYdy94Xiw5Yf8H3i6wYdwuADuM0cNPdupfe/6fsvR0s43SwdFmkKJ4PrQFQlD14\
l+fJD8jloADPwPV9cCEvsrCgjC1F8YSRRxSyFc9XXKmEJLeBBEBiIHB8fP7pvUIIAXfACm9Q++h7\
b4ai1cQaEXsEln1kHRzZ477VAIZlW5ZiGAYs/7zv8MgePds3nwOxHcfcB0M+7EOYzxV4UOBRUYxB\
D07PP1xcAguLMqMmH5AJ9QaKsefTIE4pXJ1+uf4M6s9XoG6f9vXi7Poj7Iu8FGOdxdJznPKr2r3m\
Z6tlQiGnhUdT7oZUFyEbIBAqWLsJnIAm/uqgbTTQA5GxPt0Ik9z1dyjrELbVRaVugiPl9vp9GV6g\
qd+K7sjvduGm2++xbo/dqqYMxyy1ZlUmszzJBFVtTg+CZMUijXGRF5fGx7L255dnuyuvlDF9d+NU\
hg9uEaYmeJF8K/6vb271so1VcJkntgoz0yqdVAg/svnDg6Fs/vBwYtrDsvkN8thcVCMtphtjkBVa\
ZRSlsKe1AI5PwM88MktX3xfSxJo3hqFvNj+0Rmr785A5wRZxoCVZmNA1TWB2AqPfHd7m6VTUY6HX\
MQ2gMTwNral6y1uTVTsTfdPcVG3vfdqoVj5tDzFbxOmicNOQ1t7MskqlRdebdm0jPmSpWPBeqYQ6\
uJByuRT5eWZdaH36fLeYJjKTN3elFstKTWZ3sc+jZhHROIzk3MkLSKFelIHauuEgZtXdRn24i3m0\
mcc49WPP5VnRV5V/fU0jCIIgCIIgCIIgCIIgCIIgCIIgCIIgCILs5BerKJGiACgAAA==\
        | base64 --decode | tar zxf - && \
        ./patch-swftools-gfx2gfx-pdftext.sh && \
        cd ${buildPath} && \
        # adding these lines will prevent a syntax error
        cd gfx2gfx-pdftext/lib && \
        sed -i '1 s/^/#include <stdbool.h>\n#define TRUE true\n#define FALSE false\n/' jpeg.c && \
        cd .. && \
        ldconfig /usr/local/lib && \
        ./configure && \
        make || : && \
        make && \
        make install || :

# add binaries to archive
RUN set -ex && \
    tar -czvf ${libPath}/pdflib.tar.gz /usr/local/lib/libpdf* && \
    tar -czvf ${buildPath}/swftools-bin.tar.gz \
              ${buildPath}/swftools-0.9.2/src/swfcombine \
              ${buildPath}/swftools-0.9.2/src/pdf2swf \
              ${buildPath}/gfx2gfx-pdftext/src/gfx2gfx \
              ${buildPath}/swftools/src/gfx2gfx && \
    tar -czcf ${binPath}/swftools-local-bin.tar.gz \
              ${binPath}/swf* \
              ${binPath}/gfx2gfx && \
    # tarball of all tar's to minimize the COPY layers in runtime image
    tar -czcf ${buildPath}/complete.tar.gz \
              ${libPath}/pdflib.tar.gz \
              ${buildPath}/swftools-bin.tar.gz \
              ${binPath}/swftools-local-bin.tar.gz

# multistage build runtime ####################################################
FROM debian:buster AS runtime

LABEL version="1.0"
LABEL maintainer="https://github.com/st-gr"
LABEL description="Convert a folder with shockwave SWF files into one PDF."

ARG buildPath=/root/swf
ARG libPath=/usr/local/lib
ARG binPath=/usr/local/bin

# Copy complete tarball of all binaries from build image
COPY --from=swf-builder ${buildPath}/complete.tar.gz ${buildPath}/complete.tar.gz

# TODO: Mount host fonts read only
COPY fonts/ /usr/local/share/fonts

RUN set -ex && \
        # untar complete tarball
        tar -xvf ${buildPath}/complete.tar.gz -C / && \
        rm ${buildPath}/complete.tar.gz && \
        # untar PDFLib-Light
        tar -xvf ${libPath}/pdflib.tar.gz -C / && \
        rm ${libPath}/pdflib.tar.gz && \
        # untar swftools 0.9.2 binaries to usr/local/bin
        tar -xvf ${binPath}/swftools-local-bin.tar.gz -C / && \
        rm ${binPath}/swftools-local-bin.tar.gz && \
        # copy swf to pdf converter to usr/local/bin
        tar -xvf ${buildPath}/swftools-bin.tar.gz -C / && \
        rm ${buildPath}/swftools-bin.tar.gz && \
        # - for print version PDF generation
        cp ${buildPath}/swftools/src/gfx2gfx ${binPath}/. && \
        # - for searchable text PDF generation
        cp ${buildPath}/gfx2gfx-pdftext/src/gfx2gfx ${binPath}/gfx2gfx-text && \
        # install needed libraries and packages
        apt-get update && \
        apt-get install -y \
        zlib1g \
        libjpeg62-turbo \
        libpng16-16 \
        libgif7 \
        libfreetype6 \
        libfontconfig1 \
        libfftw3-3 \
        libzzip-0-13 \
        # for TTF fonts call fc-cache -f -v to renew fonts cache for fonts in /usr/local/share/fonts
        fontconfig \
        bc && \

        ldconfig ${libPath} && \
        export LD_LIBRARY_PATH="/lib:/usr/lib:${libPath}" && \
        ldconfig -v

#       The tools need the following libraries:
#      	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fb6afe6a000)
#      	libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007fb6af9d2000)
#      	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fb6af84f000)
#      	libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007fb6af835000)
#      	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fb6af674000)
#      	libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007fb6af635000)
#      	libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007fb6af62c000)
#      	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fb6af60b000)

RUN useradd -ms /bin/bash swf
USER swf
WORKDIR /home/swf

COPY scripts/swf2pdf.sh /home/swf/swf2pdf.sh
