'''
Created on Dec 2, 2016

@author: andrewandrepowell2
'''

import numpy, itertools, os, glpk
from matplotlib import pyplot

if __name__ == '__main__':
    
    # Define the constants for the script.
    FILE_LOC = '../acquire_data'
    FILE_NCLAP = 3
    FILE_NTRIAL = 1
    FILE_NAME = 'nclap_' + repr( FILE_NCLAP ) + '_ntrial_' + repr( FILE_NTRIAL ) + '.npz'
    FILE_FULL_PATH = os.path.join( FILE_LOC, FILE_NAME )
    OPT_SAMPLES_DTYPE = numpy.dtype( numpy.float64 )
    OPT_SAMPLES_PER_ENERGY_SAMPLE = 4
    AUDIO_GET_SIGNAL_GRAB_TRIG = 2048
    AUDIO_GET_SIGNAL_CLOCK = 100e6
    AUDIO_SAMPLE_RATE = AUDIO_GET_SIGNAL_CLOCK/AUDIO_GET_SIGNAL_GRAB_TRIG
    
    # Define parameters for optimization.
    delta_n = OPT_SAMPLES_PER_ENERGY_SAMPLE
    S_K = FILE_NCLAP

    # Load file as data.
    with numpy.load( FILE_FULL_PATH ) as npz_obj:
        x_n = npz_obj[ 'arr_0' ]
    x_n = x_n.astype( OPT_SAMPLES_DTYPE, copy=False )
        
    S_M = len( x_n ) / delta_n;
    e_m = numpy.array( [ numpy.sum( numpy.square( x_n[ 0+n*delta_n : delta_n+n*delta_n ] ) ) \
                                   for n in range( S_M ) ] )
    
    # Generate and display the plot.
    pyplot.figure()
    pyplot.plot( x_n )
    pyplot.title( 'samples' )
    pyplot.minorticks_on()
    pyplot.grid(b=True, which='major', color='k', linestyle='-', alpha=0.75)
    pyplot.grid(b=True, which='minor', color='k', linestyle='--', alpha=0.5)
    
    pyplot.figure()
    pyplot.plot( e_m )
    pyplot.title( 'energy_samples' )
    pyplot.minorticks_on()
    pyplot.grid(b=True, which='major', color='k', linestyle='-', alpha=0.75)
    pyplot.grid(b=True, which='minor', color='k', linestyle='--', alpha=0.5)
    pyplot.show()
      
    # Create milp object.
    lp = glpk.LPX()
    
    if True:
        T = ['H','L']
        B = ['LB','UB']
        M = range( S_M )
        K = range( S_K )
        max_e_m = numpy.max( e_m )
        mat = []
        obj = []
        
    if True:          
        
        delta_m_k = {}
        for k in K:
            delta_m_k[k] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].bounds = 0,S_M/2-1
            lp.cols[-1].kind = int # relaxed int
        
        delta_m_t = {}
        for t in T:
            delta_m_t[t] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].kind = int # relaxed int
        lp.cols[delta_m_t['H']].bounds = 1 # 0,4
        lp.cols[delta_m_t['L']].bounds = 2,4 # 0,4
        
            
        delta_m_t_k = {}
        for (t,k) in itertools.product(T,K):
            delta_m_t_k[(t,k)] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].bounds = 0,S_M/4-1
            lp.cols[-1].kind = int # relaxed int
            
        m_t_b_k = {}
        for (t,b,k) in itertools.product(T,B,K):
            m_t_b_k[(t,b,k)] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].bounds = 0,S_M-1
            lp.cols[-1].kind = float
            
        m_t_b_k[('L','UB',-1)] = len(lp.cols)
        lp.cols.add(1)
        lp.cols[-1].bounds = 0
        lp.cols[-1].kind = float # relaxed int
        
        alpha_t_b_k_m = {}
        beta_t_b_k_m = {}
        for (t,b,k,m) in itertools.product(T,B,K,M):
            alpha_t_b_k_m[(t,b,k,m)] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].bounds = 1.5-S_M,S_M-0.5
            lp.cols[-1].kind = float
            beta_t_b_k_m[(t,b,k,m)] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].bounds = 0,1
            lp.cols[-1].kind = bool # relaxed bool
            
        sigma_t_k_m = {}
        for (t,k,m) in itertools.product(T,K,M):
            sigma_t_k_m[(t,k,m)] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].bounds = 0,1
            lp.cols[-1].kind = bool # relaxed bool
            
        e_t = {}
        for t in T:
            e_t[t] = len(lp.cols)
            lp.cols.add(1)
            lp.cols[-1].bounds = 0,max_e_m
            lp.cols[-1].kind = float
        
    if True:
        
        for k in K:
                 
            mat.append((len(lp.rows),m_t_b_k[('L','UB',k-1)],1))
            mat.append((len(lp.rows),delta_m_k[k],1)) 
            mat.append((len(lp.rows),m_t_b_k[('H','LB',k)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = 0
            lp.rows[-1].kind = float
                 
            mat.append((len(lp.rows),m_t_b_k[('H','LB',k)],1))
            mat.append((len(lp.rows),delta_m_t['H'],1))
            mat.append((len(lp.rows),delta_m_t_k[('H',k)],1))
            mat.append((len(lp.rows),m_t_b_k[('H','UB',k)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = 0
            lp.rows[-1].kind = float
                 
            mat.append((len(lp.rows),m_t_b_k[('H','UB',k)],1))
            mat.append((len(lp.rows),delta_m_t_k[('L',k)],1))
            mat.append((len(lp.rows),m_t_b_k[('L','LB',k)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = 0
            lp.rows[-1].kind = float
                 
            mat.append((len(lp.rows),m_t_b_k[('L','LB',k)],1))
            mat.append((len(lp.rows),delta_m_t['L'],1))
            mat.append((len(lp.rows),m_t_b_k[('L','UB',k)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = 0
            lp.rows[-1].kind = float
             
        for (t,k,m) in itertools.product(T,K,M):
                
            mat.append((len(lp.rows),m_t_b_k[(t,'LB',k)],-1))
            mat.append((len(lp.rows),alpha_t_b_k_m[(t,'LB',k,m)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = -m-0.5
            lp.rows[-1].kind = float
                
            mat.append((len(lp.rows),m_t_b_k[(t,'UB',k)],1))
            mat.append((len(lp.rows),alpha_t_b_k_m[(t,'UB',k,m)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = m-0.5
            lp.rows[-1].kind = float
             
         
        for (t,b,k,m) in itertools.product(T,B,K,M):
               
            mat.append((len(lp.rows),beta_t_b_k_m[(t,b,k,m)],(S_M-0.5)))
            mat.append((len(lp.rows),alpha_t_b_k_m[(t,b,k,m)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = 0,None
            lp.rows[-1].kind = float
             
            mat.append((len(lp.rows),beta_t_b_k_m[(t,b,k,m)],-(1.5-S_M)))
            mat.append((len(lp.rows),alpha_t_b_k_m[(t,b,k,m)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = None,-(1.5-S_M)
            lp.rows[-1].kind = float
             
        for (t,k,m) in itertools.product(T,K,M):
              
            curr_row = len(lp.rows)
            mat.append((curr_row,sigma_t_k_m[(t,k,m)],-1))
            lp.rows.add(1)
            lp.rows[-1].bounds = None,len(B)-1
            lp.rows[-1].kind = float
              
            for b in B:
                  
                mat.append((curr_row,beta_t_b_k_m[(t,b,k,m)],1))
                 
                mat.append((len(lp.rows),beta_t_b_k_m[(t,b,k,m)],1))
                mat.append((len(lp.rows),sigma_t_k_m[(t,k,m)],-1))
                lp.rows.add(1)
                lp.rows[-1].bounds = 0,None
                lp.rows[-1].kind = float
                 
         
        for (k,m) in itertools.product(K,M):
             
            mat.append((len(lp.rows),e_t['H'],1))
            mat.append((len(lp.rows),sigma_t_k_m[('H',k,m)],max_e_m))
            lp.rows.add(1)
            lp.rows[-1].bounds = None,e_m[m]+max_e_m
            lp.rows[-1].kind = float
             
            mat.append((len(lp.rows),e_t['L'],-1))
            mat.append((len(lp.rows),sigma_t_k_m[('L',k,m)],max_e_m))
            lp.rows.add(1)
            lp.rows[-1].bounds = None,-e_m[m]+max_e_m
            lp.rows[-1].kind = float
            
        mat.append((len(lp.rows),e_t['L'],1))
        mat.append((len(lp.rows),e_t['H'],-1))
        lp.rows.add(1)
        lp.rows[-1].bounds = None,0
        lp.rows[-1].kind = float
        
    if True:
        
        lp.matrix = mat
        lp.obj[e_t['H']] = 1.0
        lp.obj[e_t['L']] = -1.0
        lp.obj.maximize = True
        
        print( 'Determining relaxed solution' )
        
        solver_status = lp.simplex()

        if lp.status!='opt': 
            print( 'No relaxed solution' )
            print( 'Optimization Status: ' + lp.status )
            print( 'Solver Status: ' + solver_status )
        else:
            print( 'Relaxed solution found' )
            
            print( 'obj_val: ' + repr( lp.obj.value ) )
            
            for t in T:
                
                print( 'e_' + t + ': ' + repr( lp.cols[e_t[t]].value ) )
                print( 'delta_m_' + t + ': ' + repr( lp.cols[delta_m_t[t]].value ) )
            
            for (k,t,b) in itertools.product(K,T,B):
                  
                print( 'm_' + t + '_' + b + '_' + repr(k) + 
                       ': ' + repr( lp.cols[m_t_b_k[(t,b,k)]].value ) )
#                 for m in M:
#                     print( 'alpha_' + t + '_' + b + '_' + repr(k) + '_' + repr(m) +
#                            ': ' + repr( lp.cols[alpha_t_b_k_m[(t,b,k,m)]].value ) )
#                     print( 'beta_' + t + '_' + b + '_' + repr(k) + '_' + repr(m) +
#                            ': ' + repr( lp.cols[beta_t_b_k_m[(t,b,k,m)]].value ) )
#             for (t,k,m) in itertools.product(T,K,M):
#                 print( 'sigma_' + t + '_' + repr(k) + '_' + repr(m) + ': ' + 
#                        repr( lp.cols[sigma_t_k_m[(t,k,m)]].value ) )
#                 for b in B:
#                     print( 'beta_' + t + '_' + b + '_' + repr(k) + '_' + repr(m) + ': ' + 
#                            repr( lp.cols[beta_t_b_k_m[(t,b,k,m)]].value ) )
             
            print( 'Applying "Cut and Branch" solver' )
                
            solver_status = lp.intopt()
            
            if lp.status!='opt':
                
                print( 'No solution found' )
                print( 'Optimization Status: ' + lp.status )
                print( 'Solver Status: ' + solver_status )
                
            else:
                
                print( 'Solution found' )
                print( 'obj_val: ' + repr( lp.obj.value ) )
                
                for t in T:
                    print( 'e_' + t + ': ' + repr( lp.cols[e_t[t]].value ) )
                    print( 'delta_m_' + t + ': ' + repr( lp.cols[delta_m_t[t]].value ) )
                    
                print( 'm_L_UB_-1: ' + repr( lp.cols[m_t_b_k[('L','UB',-1)]].value ) )
                
                for (k,t,b) in itertools.product(K,T,B):
                    print( 'm_' + t + '_' + b + '_' + repr(k) + 
                           ': ' + repr( lp.cols[m_t_b_k[(t,b,k)]].value ) )
                for k in K:
                    print( 'delta_m_' + repr(k) + ': ' + repr( lp.cols[delta_m_k[k]].value ) )  
                    for t in T:
                        print( 'delta_m_' + t + '_' + repr(k) + ': ' + repr( lp.cols[delta_m_t_k[(t,k)]].value ) ) 
#                     for m in M:
#                         print( 'alpha_' + t + '_' + b + '_' + repr(k) + '_' + repr(m) +
#                                ': ' + repr( lp.cols[alpha_t_b_k_m[(t,b,k,m)]].value ) )

                # Acquire max delta_m_k
                max_delta_m_k = 0
                for k in K[1:]:
                    if max_delta_m_k<lp.cols[delta_m_k[k]].value:
                        max_delta_m_k = lp.cols[delta_m_k[k]].value
                        
                print( 'max_delta_m_k: ' + repr( max_delta_m_k ) )
                  
                # Acquire max delta_m_t_k  
                max_delta_m_t_k = {'H':0,'L':0}
                for (t,k) in itertools.product(T,K):
                    if max_delta_m_t_k[t]<lp.cols[delta_m_t_k[(t,k)]].value:
                        max_delta_m_t_k[t] = lp.cols[delta_m_t_k[(t,k)]].value
                        
                for t in T:
                    print( 'max_delta_m_' + t + '_k: ' + repr(max_delta_m_t_k[t]) )
                    
        
                # Plot energy samples, but with the borders.
                pyplot.figure()
                pyplot.plot( e_m )
                pyplot.title( 'energy_samples' )
                pyplot.minorticks_on()
                pyplot.grid(b=True, which='major', color='k', linestyle='-', alpha=0.75)
                pyplot.grid(b=True, which='minor', color='k', linestyle='--', alpha=0.5)
                pyplot.show()
     
     
     
     
    