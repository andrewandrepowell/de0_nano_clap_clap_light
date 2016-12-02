'''
Created on Dec 2, 2016

@author: andrewandrepowell2
'''

import numpy, sounddevice, itertools, os
from matplotlib import pyplot

if __name__ == '__main__':
    
    # Define the constants for the script.
    FILE_LOC = '../acquire_data'
    FILE_NCLAP = 2
    FILE_NTRIAL = 0
    FILE_NAME = 'nclap_' + repr( FILE_NCLAP ) + '_ntrial_' + repr( FILE_NTRIAL ) + '.npz'
    FILE_FULL_PATH = os.path.join( FILE_LOC, FILE_NAME )
    OPT_SAMPLES_PER_ENERGY_SAMPLE = 32
    OPT_SAMPLES_DTYPE = numpy.dtype( numpy.float64 )
    AUDIO_GET_SIGNAL_GRAB_TRIG = 2048
    AUDIO_GET_SIGNAL_CLOCK = 100e6
    AUDIO_SAMPLE_RATE = AUDIO_GET_SIGNAL_CLOCK/AUDIO_GET_SIGNAL_GRAB_TRIG
    pass

    # Load file as data.
    with numpy.load( FILE_FULL_PATH ) as npz_obj:
        samples = npz_obj[ 'arr_0' ]
    samples = samples.astype( OPT_SAMPLES_DTYPE, copy=False )
        
    spes = OPT_SAMPLES_PER_ENERGY_SAMPLE
    tes = len( samples ) / spes;
    energy_samples = numpy.array( [ numpy.sum( numpy.square( samples[ 0+n*spes : spes+n*spes ] ) ) for n in range( tes ) ] )
    
    # Generate and display the plot.
    pyplot.figure()
    pyplot.plot( samples )
    pyplot.title( 'samples' )
    
    pyplot.figure()
    pyplot.plot( energy_samples )
    pyplot.title( 'energy_samples' )
    pyplot.show()