#!/bin/bash

# plotraits.sh - a bash script for automatic portrait generation.
#
# Goes all the way from a raster image to a ready-to-plot hpgl file.
# It also supports direct portrait generation from webcam input. How cool is that?

# REQUIRES PYTHON, PYSERIAL, NUMPY, HP2XX, CHIPLOTLE,
# MPLAYER, GSTREAMER (deprecated), IMAGEMAGICK, AUTOTRACE AND PSTOEDIT
# install everything on debian squeeze in three handy steps:
#
# 1) apt-get install python python-serial python-numpy python-setuptools
# 2) apt-get install mplayer gstreamer-tools imagemagick autotrace pstoedit
# 3) easy_install -U chiplotle && mkdir ~/.chiplotle
#
# chiplotle documentation: http://music.columbia.edu/cmc/chiplotle/manual/
#
# Copyright: VP-6803P (astio@ciotoni.net)
# License: GNU Lesser General Public License, Version 3 (http://www.gnu.org/copyleft/lesser.html)
#
# ...Art is dead! Long live the plotters!

# SOFTWARE DEPENDENCIES:
# ----------------------
#GST="/usr/bin/gst-launch-0.10" # Gstreamer (http://gstreamer.freedesktop.org)
# GSTREAMER IS DEPRECATED! USE MPLAYER (DEFAULT)
MPL="/usr/bin/mplayer" # MPlayer (http://www.mplayerhq.hu)
CVT="/usr/bin/convert" # Imagemagick (http://www.imagemagick.org)
ATR="/usr/bin/autotrace" # Autotrace (http://autotrace.sourceforge.net)
PTE="/usr/bin/pstoedit" # Pstoedit (http://www.pstoedit.net)
PLT="/usr/local/bin/plot_hpgl_file.py" # Chiplotle (http://music.columbia.edu/cmc/chiplotle)

# MOST RELEVANT PARAMETERS YOU MAY WANT TO CUSTOMIZE:
# ---------------------------------------------------
CVTNORM="" # set to "-normalize" if you want your original image being contrast normalized
CVTSHARP=0.1 # sharpen original image if needed (reasonable values probably range between 0.1 and 4.0) - 0.0 means "do not sharpen"
CVTPCTEDGES=80 # percent edge detection threshold - Warning: high values will result in *A LOT* of lines!
CVTRESIZE=1280 # resize the original raster image - combine with $PTESCALE to fit target sheet (default is good for landscape A4)
PTESCALE=2 # scale the resulting vector - combine with $CVTRESIZE to fit target sheet (default is good for landscape A4)
ARTIST="VP-6803P" # artist's name - you should use your plotter model here. Cause he's the Maestro! :)

# USAGE:
# ------
usage() {
        echo >&2 ""
        echo >&2 "USAGE:"
        echo >&2 ""
        echo >&2 "$0 inputfile"
        echo >&2 "(to convert and plot a given image file)"
        echo >&2 ""
        echo >&2 "$0 /dev/video"
        echo >&2 "(to plot a snapshot from video input - ie. a webcam)"
        echo >&2 ""
}

# ERROR HANDLING:
# ---------------
errmsg() {
        echo ""
        echo $1
        usage
        exit 1
}

if [ $# -eq 0 ] ; then errmsg "ERROR ---> Missing argument <---" ; exit 0 ; fi
if [ $# -gt 1 ] ; then errmsg "ERROR ---> Too many arguments <---" ; exit 0 ; fi
#which $GST > /dev/null || errmsg "ERROR ---> $GST : missing executable <---"
# GSTREAMER IS DEPRECATED! USE MPLAYER (DEFAULT)
which $MPL > /dev/null || errmsg "ERROR ---> $GST : missing executable <---"
which $CVT > /dev/null || errmsg "ERROR ---> $CVT : missing executable <---"
which $ATR > /dev/null || errmsg "ERROR ---> $ATR : missing executable <---"
which $PTE > /dev/null || errmsg "ERROR ---> $PTE : missing executable <---"
which $PLT > /dev/null || errmsg "ERROR ---> $PLT : missing executable <---"

# INPUT HANDLING:
# ---------------
echo $1 | grep "/dev/video" > /dev/null
if [ $? -eq 0 ] ; then
	# input is a snapshot from video device
	FBASE=$(date +%Y%d%m_%H%M%S)
	
	# GSTREAMER (change "v4l2src" to "v4lsrc" in the line below if using an old v4l interface)
	# FEXT="jpg"
	#$GST v4l2src num-buffers=1 ! jpegenc ! filesink location=$FBASE.$FEXT
	# GSTREAMER IS DEPRECATED! USE MPLAYER (DEFAULT)
	
	# MPLAYER (press "s" to save snapshot, then "q" to let the script to continue and plot)
	FEXT="png"
	echo "press s to save snapshot and q to plot"
	$MPL -quiet -vf screenshot tv:// &> /dev/null
	LASTPIC=$(ls shot*.png | tail -1)
	mv $LASTPIC $FBASE.$FEXT
	rm -f shot*.png
	
else
	# input is image specified from commandline
	FBASE=$( echo $1 | cut -d '.' -f 1)
	FEXT=$( echo $1 | cut -d '.' -f 2)
fi

# IMAGE PROCESSING:
# -----------------
# invert colors, sharpen image and normalize if needed (used for better edge detection)
$CVT $FBASE.$FEXT -negate $CVTNORM -sharpen 0x$CVTSHARP -resize $CVTRESIZEx$CVTRESIZE negated_$FBASE.png || errmsg "ERROR ---> $1 is not an image nor a valid video device <---"
# detect relevant edges - a short/modified version of Fred's "cartoon" script
# check out all the other cool Fred's Imagemagick scripts at http://www.fmwconcepts.com/imagemagick/
dx="-1,0,1,-1,0,1,-1,0,1" # x derivative filters
dy="1,1,1,0,0,0,-1,-1,-1" # y derivative filters
$CVT -quiet -regard-warnings negated_$FBASE.png -colorspace RGB +repage repaged_negated_$FBASE.png
$CVT \( repaged_negated_$FBASE.png -colorspace gray -median 2 \) \
		\( -clone 0 -bias 50% -convolve "$dx" -solarize 50% \) \
		\( -clone 0 -bias 50% -convolve "$dy" -solarize 50% \) \
		\( -clone 1 -clone 1 -compose multiply -composite -gamma 2 \) \
		\( -clone 2 -clone 2 -compose multiply -composite -gamma 2 \) \
		-delete 0-2 -compose plus -composite -threshold ${CVTPCTEDGES}% cartoon_repaged_negated_$FBASE.png

# RASTER TO VECTOR CONVERSION:
# ----------------------------
# convert raster image to postscript vector
$ATR cartoon_repaged_negated_$FBASE.png --centerline --output-file cartoon_repaged_negated_$FBASE.eps
# convert postscript to hpgl and scale image to fit an A4 paper sheet
$PTE -q -xscale $PTESCALE -yscale $PTESCALE -f hpgl cartoon_repaged_negated_$FBASE.eps cartoon_repaged_negated_$FBASE.hpgl

# EDIT HPGL FILE:
# ---------------
# "clean" generated hpgl file
sed -i '1d' cartoon_repaged_negated_$FBASE.hpgl
sed -i -e 's/IN;SC;PU;PU;SP1;LT;VS10/IN;SC 0,26624,0,16640;SP1/g' cartoon_repaged_negated_$FBASE.hpgl
sed -i -e 's/PW1;//g' -e's/PW2;//g' -e 's/PG1;//g' -e 's/EC1;//g' -e 's/EC;//g' cartoon_repaged_negated_$FBASE.hpgl
sed -i '$d' cartoon_repaged_negated_$FBASE.hpgl
sed -i -e 's/PU;SP;OE//g' -e 's/^$//g' cartoon_repaged_negated_$FBASE.hpgl
# shuffle lines
head -1 cartoon_repaged_negated_$FBASE.hpgl > shuffled_cartoon_repaged_negated_$FBASE.hpgl
tail -n +2 cartoon_repaged_negated_$FBASE.hpgl | sort -r >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
# artist's sign
YEAR=$(date +%Y)
echo "SC -210,210,-148,148;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
echo "PU120,-120;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
echo "DT*,1;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
echo "LB-$FBASE*;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
echo "PU120,-110;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
echo "LB-$ARTIST*;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
echo "PU120,-100;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
echo "LB-$YEAR*;" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl
# put pen down an re-initialize plotter
echo "SP0;IN" >> shuffled_cartoon_repaged_negated_$FBASE.hpgl

# CLEANUP TEMPORARY FILES:
# ------------------------
# remove unneeded "intermediate" files (uncomment if you wish to keep some of them)
rm negated_$FBASE.png
rm repaged_negated_$FBASE.png
rm cartoon_repaged_negated_$FBASE.png
# rm cartoon_repaged_negated_$FBASE.eps # you should keep at least this one as a preview of the plotted drawing

# PLOT:
# -----
# send hpgl file to plotter with chiplotle "plot_hpgl_file.py" utility
$PLT shuffled_cartoon_repaged_negated_$FBASE.hpgl
# keep (uncomment to remove) hpgl file for later use
# rm shuffled_cartoon_repaged_negated_$FBASE.hpgl
