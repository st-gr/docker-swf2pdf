#!/bin/bash
###########################################
## convert flash .swf files into .pdf
## ./swf2pdf.sh page0*.swf
###########################################
usage() {
  echo "Usage: $0 [-t] [-r dpi] [-o outputfile] [folder/files*]"
  echo "       -t = convert to pdf with searchable text"
  echo "       -r = set resolution to dpi value, default=200"
  echo "       -o = specify output filename for the pdf, default dirname.pdf"
  echo "       folder/files = SWF files to convert"
  1>&2;
  exit 1;
}

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    usage
fi

#outfile=
converter=gfx2gfx
resdpi=200

while true; do
    case $1 in
      -r) resdpi=200
            shift
            case $1 in
              *[!0-9]* | "") ;;
              *) resdpi=$1; shift ;;
            esac ;;
      -o) outfile=
            shift
            outfile=$1; shift ;;
      -t) converter=gfx2gfx-text
            shift ;;
      # ... Other options ...
      -*) usage
          exit 2;;
      *) break ;;
    esac
done

START=$(date +%s.%N)

declare -a ARGS
last_var=""
for var in "$@"; do
    # remove arguments to leave only the list of files
    if [ "$var" = '-t' ] || [ "$var" = '-o' ] || [ "$last_var" = '-o' ] || [ "$var" = '-r' ] || [ "$last_var" = '-r' ]; then
      echo $var
        last_var=$var
        continue
    fi
    last_var=$var
    ARGS[${#ARGS[@]}]="$var"
done

folder=$(dirname "$ARGS");

echo swf2pdf - using converter $converter, $resdpi dpi and folder $folder

arrfiles=(${ARGS[@]})
maxperrun=25
swf_merges=15
# 10*25 = 250 pages
count_arr=$((${#arrfiles[@]}))
echo "$count_arr file(s) will be processed .."

now=$(date +"%m_%d_%Y")

part=1
com_swf="combined_$now-$part.swf"

echo "Combine .swf files into one $com_swf .."

arr_swf_merge=()

for f in ${ARGS[@]}
do
  filenum=$((filenum+1))
  ctr=$((ctr+1))
  if [[ "$ctr" -eq 1 ]]; then
    #echo "New .swf $f to $com_swf"
    echo -ne "Page $filenum merge $f into $com_swf\r"
    cp $f $com_swf
    arr_swf_merge+=($com_swf)
  elif [[ "$ctr" -eq maxperrun ]]; then
    #echo "$ctr merge $f to $com_swf"
    echo -ne "Page $filenum merge $f into $com_swf\r"
    swfcombine --cat $com_swf $f  -o $com_swf
    part=$((part+1))
    ctr=0
    com_swf="combined_$now-$part.swf"
  else
    #echo "$ctr merge $f to $com_swf"
    echo -ne "Page $filenum merge $f into $com_swf\r"
    swfcombine --cat $com_swf $f  -o $com_swf
  fi
done

echo -ne "\n"

count_swf=$((${#arr_swf_merge[@]}))
filenum=0
ctr=0
part=1

arr_pdf_merge=()

com_swf="combined_$now-M-$part.swf"
echo "Merging $count_swf .. into $com_swf"

for ((n=0;n<count_swf;n++))
do
  f=${arr_swf_merge[n]}
  ctr=$((ctr+1))
  filenum=$((filenum+1))
  if [[ "$ctr" -eq 1 ]]; then
    #echo "New .swf $f to $com_swf"
    echo -ne "$filenum merge $f into $com_swf\r"
    cp $f $com_swf
    arr_pdf_merge+=($com_swf)
  elif [[ "$ctr" -eq swf_merges ]]; then
    #echo "$ctr merge $f to $com_swf"
    echo -ne "$filenum merge $f into $com_swf\r"
    swfcombine --cat $com_swf $f  -o $com_swf
    part=$((part+1))
    ctr=0
    com_swf="combined_$now-M-$part.swf"
  else
    #echo "$ctr merge $f to $com_swf"
    echo -ne "$filenum merge $f into $com_swf\r"
    swfcombine --cat $com_swf $f  -o $com_swf
  fi
done

echo -ne "\n"

# delete temporary files
echo "deleting parts - ${arr_swf_merge[@]}"
rm ${arr_swf_merge[@]}

# create pdf
com_pdf="combined_$now.pdf"
echo "Convert combined .swf file into .pdf $com_pdf  .."

count_pdf=$((${#arr_pdf_merge[@]}))
for ((n=0;n<count_pdf;n++))
do
  f=${arr_pdf_merge[n]}
  com_pdf="combined_$now-$n.pdf"
  $converter $f -r $resdpi -o $com_pdf
done

END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo Time to convert $count_arr files to pdf $DIFF seconds

# move the files to work folder
mv combined_$now*.pdf $folder/.
rm combined_$now*.swf
cd $folder
if [ -z ${outfile+x} ]; then outfile=${PWD##*/}.pdf; fi
rm $outfile 2> /dev/null
mv combined_$now*.pdf $outfile
echo "File $outfile in folder $folder ."
