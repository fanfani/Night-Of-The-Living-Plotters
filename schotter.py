#!/usr/bin/env python

"""

ABOUT

python reconstruction of historical plotter art 

- "Schotter" by Georg Nees, 1965(?)
http://www.medienkunstnetz.de/works/schotter/

borrowing some code from http://www.artsnova.com/Nees_Schotter_Tutorial.html

original artwork seems to follow a more complex approach:

"Image 38 ["Schotter"] is produced by invoking the SERIE procedure [...]. The non-parametric procedure QUAD serves to generate the elementary figure which is reproduced multiple times in the composition process controlled by SERIE. QUAD is located in lines 4 through 15 of the generator. This procedure draws squares with sides of constant length but at random locations and different angles. From lines 9 and 10, it can be seen that the position of a single square is influenced by random generator J1, and the angle placement by J2. The successively increasing variation between the relative coordinates P and Q, and the angle position PSI of a given square, is controlled by the counter index I, which is invoked by each call from QUAD (see line 14)." -Georg Nees


INSTALLATION

REQUIRES PYTHON, PYSERIAL, NUMPY, HP2XX AND CHIPLOTLE
install everything on debian wheezy in two handy steps:

1) apt-get install python python-serial python-numpy python-setuptools hp2xx
2) easy_install -U chiplotle && mkdir ~/.chiplotle


CHIPLOTLE DOCS

chiplotle documentation: http://music.columbia.edu/cmc/chiplotle/manual/


LEGAL STUFF

:copyright:
    VP-6803P (astio@ciotoni.net)
:license:
    GNU Lesser General Public License, Version 3
    (http://www.gnu.org/copyleft/lesser.html)

"""

from chiplotle import *
from chiplotle.tools.plottertools import instantiate_virtual_plotter
import math
import random

# select the first plotter configured in chiplotle
#~ plotter = instantiate_plotters()[0] # real hardware plotter

# hint: change to a virtual plotter, useful for testing and debug
plotter =  instantiate_virtual_plotter(type="HP7550A") # virtual plotter

# global scaling values
scx = 296 ; scy = 420 # (A3 size: 297 x 420)
plotter.write(hpgl.SC([(-scx/2,scx/2),(-scy/2,scy/2)]))

# pick up the first pen
plotter.select_pen(1)

# schotter setup
w = 22 # width (how many squares - es. 22)
h = 12 # height (how many squares - es. 12)
s = 15 # square size  (es. 15)

rs = 0.015 # random step (rotation increment in degrees)
dp = 2.25 # dampen (soften random effect for position)
rsum = 0 # dummy initial value for rsum

# draw two rectangle frames around the boxes area
plotter.write(shapes.rectangle(scy, scx)) # outer border (W: landscape!!)
#~ plotter.write(shapes.rectangle((w+1)*s, (h+1)*s)) # inner frame

# main loop 
for i in xrange(1,w):
	
	rsum += i*rs # add to the random value
	
	for j in xrange(1,h):
		
		rv = random.uniform(-rsum, rsum)
		
		# here comes the box :-)
		box = shapes.square(s)
		
		# box position
		curr_cx = - w*s/2 + i*s + rv*dp ;	curr_cy = - h*s/2 + j*s + rv*dp
		transforms.center_at(box, [curr_cx, curr_cy])
						
		# rotate the box of rv degrees around its center
		transforms.rotate(box, rv, pivot=(curr_cx, curr_cy))

		# draw the damn box	
		plotter.write(box)


# artist signature :-) ...it's an original piece of art by VP-6803P. No shit.
plotter.write(hpgl.PU([(-(w+1)*s/2 + s,-(h+1)*s/2 - s/2)]))
plotter.write(hpgl.DT(terminator='*'))
plotter.write(hpgl.LB('VP-6803P*'))

# get ready for a new masterpiece.
plotter.select_pen(0)
plotter.write(hpgl.IN())

# next line of code is for software viewing. Use with virtual plotter
# HPGL and EPS output files are saved in ~/.chiplotle/output/
io.view(plotter)
