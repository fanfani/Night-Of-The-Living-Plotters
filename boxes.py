#!/usr/bin/env python

"""

ABOUT

python reconstruction of historical plotter art 

- "Boxes" by William Kolomyjec, 1975
http://dada.compart-bremen.de/item/artwork/938


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

# boxes setup
w = 17 # width (how many squares - es. 17)
h = 11 # height (how many squares - es. 11)
s = 20 # square size  (es. 20)

b = w*h # number of boxes

# draw two rectangle frames around the boxes area
plotter.write(shapes.rectangle(scy, scx)) # outer border (W: landscape!!)
#~ plotter.write(shapes.rectangle((w+1)*s, (h+1)*s)) # inner frame

# some entropy
r = random.uniform(-0.03, 0.03)

# main loop 
for i in xrange(1,w):
	for j in xrange(1,h):
		
		# here comes the box :-)
		box = shapes.square(s)
		
		# experiments with a different shape
		#~ box = shapes.cross(s,s)

		# simple algo to increase rotation towards the middle of the grid
		# borrowed from http://recodeproject.com/artwork/v2n3boxes-i
		if(w % 2 == 0):	  iw = w/2 - abs(i - w/2)
		else: iw = w/2 - 0.5 - abs(i - w/2 - 0.5)
			   
		if(h % 2 == 0): jh = h/2 - 0.5 - abs(j - h/2 + 0.5);
		else: jh = h/2 - abs(j - h/2)

		rt = iw * jh

		# box position
		curr_cx = - w*s/2 + i*s ;	curr_cy = - h*s/2 + j*s
		transforms.center_at(box, [curr_cx, curr_cy])
		
		# outer boxes should not be rotated
		if i == 1 or i == w-1 or j == 1 or j == h-1: rt = 0

		# get some more entropy
		rp = random.uniform(-0.5, 0.5) # used to reduce rt to a lower value. TODO: fine-tune for nb > 200
		rzx = random.randint(-1,1) ; rzy = random.randint(-1,1) # either "-1", "0" or "1": pivot xy directions
		rs = random.randrange(-1, 2, 2) # either "-1" or "1": rotate clockwise or counterclockwise
		
		# rotate the box of rs*rt*r around the point (curr_cx + rzx*rt*rp, curr_cy + rzy*rt*rp)
		transforms.rotate(box, rs*rt*r, pivot=(curr_cx + rzx*rt*rp, curr_cy + rzy*rt*rp))

		# experiments with noise
		#~ transforms.noise(box, int(rt/5)+1)
			
		# draw the damn box	
		plotter.write(box)


# artist signature :-) ...it's an original piece of art by VP-6803P. No shit.
plotter.write(hpgl.PU([((w+1)*s/2 - s,-(h+1)*s/2 - s/2)]))
plotter.write(hpgl.DT(terminator='*'))
plotter.write(hpgl.LB('VP-6803P*'))

# get ready for a new masterpiece.
plotter.select_pen(0)
plotter.write(hpgl.IN())

# next line of code is for software viewing. Use with virtual plotter
# HPGL and EPS output files are saved in ~/.chiplotle/output/
io.view(plotter)
