'''
Created on Dec 20, 2016

See the following link for more information
on the solver's output:
https://en.wikibooks.org/wiki/GLPK/Terminal_output

@author: andrewandrepowell2
'''

import os, glpk
import numpy as np, itertools as it
from matplotlib import pyplot as pp

def plot_grid():
    pp.grid(b=True, which='major', color='k', linestyle='-', alpha=0.75)
    pp.grid(b=True, which='minor', color='k', linestyle='--', alpha=0.5)
    pp.minorticks_on()
    
def create_col( lp, bounds, kind ):
    curr_col = len( lp.cols )
    lp.cols.add(1)
    lp.cols[-1].bounds = bounds
    lp.cols[-1].kind = kind
    return curr_col

def create_row( lp, bounds, kind ):
    curr_row = len( lp.rows )
    lp.rows.add(1)
    lp.rows[-1].bounds = bounds
    lp.rows[-1].kind = kind
    return curr_row

def add_term( mat, row, col, scalar ):
    mat.append( (row,col,scalar) )

if __name__ == '__main__':
    
    # Define the constants for the script.
    FILE_LOC = '../acquire_data'
    FILE_NCLAP = 3
    FILE_NTRIAL = 0
    FILE_NAME = 'nclap_' + repr( FILE_NCLAP ) + '_ntrial_' + repr( FILE_NTRIAL ) + '.npz'
    FILE_FULL_PATH = os.path.join( FILE_LOC, FILE_NAME )
    OPT_SAMPLES_DTYPE = np.dtype( np.float64 )
    OPT_SAMPLES_PER_ENERGY_SAMPLE = 16
    OPT_LAG = OPT_SAMPLES_PER_ENERGY_SAMPLE-1
    
    # Define some of the parameters for optimization.
    delta_n = OPT_SAMPLES_PER_ENERGY_SAMPLE
    delta_n_L = OPT_LAG
    S_K = FILE_NCLAP
    
    # Load file as data.
    with np.load( FILE_FULL_PATH ) as npz_obj:
        x_n = npz_obj[ 'arr_0' ]
    x_n = x_n.astype( OPT_SAMPLES_DTYPE, copy=False )
    
    # Define more parameters.
    S_N = len( x_n )
    S_M = np.floor( S_N/(delta_n-delta_n_L) ).astype( np.int64 )
    
    # Generate the energy signal.
    x_n = np.append( x_n, np.zeros( delta_n ) )
    e_m = np.array( [ np.sum( np.square( 
        x_n[ m*(delta_n-delta_n_L):m*(delta_n-delta_n_L)+delta_n ] ) ) 
                     for m in range( S_M ) ] )
    e_m = e_m[0:120]
    
    # Display plots.
    pp.figure()
    pp.plot( x_n )
    pp.title( 'signal' )
    plot_grid()
    pp.figure()
    pp.plot( e_m )
    pp.title( 'energy signal' )
    plot_grid()
    pp.show()
    
    # Create the milp object 
    lp = glpk.LPX()
    print( 'Configuring model...')
    
    # Create corresponding sets
    T = ['H','L']
    B = ['LB','UB']
    M = range( S_M )
    K = range( S_K )
    max_e_m = np.max( e_m )
    mat = []
    
    # Create variables ( i.e. the columns ).
    delta_m_k = {}
    for k in K: 
        delta_m_k[k] = create_col( lp, (0,S_M/2-1), int )
        
    delta_m_t = {}
    delta_m_t['H'] = create_col( lp, 2, int )
    delta_m_t['L'] = create_col( lp, 4, int )
        
    delta_m_t_k = {}
    for (t,k) in it.product(T,K):
        delta_m_t_k[(t,k)] = create_col( lp, (0,S_M/4-1), int )
        
    m_t_b_k = {}
    for (t,b,k) in it.product(T,B,K):
        m_t_b_k[(t,b,k)] = create_col( lp, (0,S_M-1), float )
    m_t_b_k[('L','UB',-1)] = create_col( lp, 0, float )
    
    alpha_t_b_k_m = {}
    beta_t_b_k_m = {}
    for (t,b,k,m) in it.product(T,B,K,M):
        alpha_t_b_k_m[(t,b,k,m)] = create_col( lp, (1.5-S_M,S_M-0.5), float )
        beta_t_b_k_m[(t,b,k,m)] = create_col( lp, (0,1), bool )
        
    sigma_t_k_m = {}
    for (t,k,m) in it.product(T,K,M):
        sigma_t_k_m[(t,k,m)] = create_col( lp, (0,1), bool )
            
    e_t = {}
    for t in T:
        e_t[t] = create_col( lp, (0,max_e_m), float )
        
    # Create system of linear equations (SLE) representing the bounds.
    for k in K:
         
        row = create_row( lp, 0, float )
        add_term( mat, row, m_t_b_k[('L','UB',k-1)], 1 )
        add_term( mat, row, delta_m_k[k], 1 ) 
        add_term( mat, row, m_t_b_k[('H','LB',k)], -1 )
         
        row = create_row( lp, 0, float )
        add_term( mat, row, m_t_b_k[('H','LB',k)],1 )
        add_term( mat, row, delta_m_t['H'], 1 )
        add_term( mat, row, delta_m_t_k[('H',k)], 1 )
        add_term( mat, row, m_t_b_k[('H','UB',k)], -1 )
         
        row = create_row( lp, 0, float )
        add_term( mat, row, m_t_b_k[('H','UB',k)], 1 )
        add_term( mat, row, delta_m_t_k[('L',k)], 1 )
        add_term( mat, row, m_t_b_k[('L','LB',k)], -1 )
         
        row = create_row( lp, 0, float )
        add_term( mat, row, m_t_b_k[('L','LB',k)], 1 )
        add_term( mat, row, delta_m_t['L'], 1 )
        add_term( mat, row, m_t_b_k[('L','UB',k)], -1 )
         
    # Create SLEs representing if-then constraints.
    for (t,k,m) in it.product(T,K,M):
             
        row = create_row( lp, -m-0.5, float )
        add_term( mat, row, m_t_b_k[(t,'LB',k)], -1 )
        add_term( mat, row, alpha_t_b_k_m[(t,'LB',k,m)], -1 )
             
        row = create_row( lp, m-0.5, float )
        add_term( mat, row, m_t_b_k[(t,'UB',k)], 1 )
        add_term( mat, row, alpha_t_b_k_m[(t,'UB',k,m)], -1 )
 
    for (t,b,k,m) in it.product(T,B,K,M):
            
        row = create_row( lp, (0,None), float )
        add_term( mat, row, beta_t_b_k_m[(t,b,k,m)], (S_M-0.5) )
        add_term( mat, row, alpha_t_b_k_m[(t,b,k,m)], -1 )
            
        row = create_row( lp, (None,-(1.5-S_M)), float )
        add_term( mat, row, beta_t_b_k_m[(t,b,k,m)], -(1.5-S_M) )
        add_term( mat, row, alpha_t_b_k_m[(t,b,k,m)], -1 )
         
    # Create SLEs representing the logical AND constraints.
    for (t,k,m) in it.product(T,K,M):
         
        row_0 = create_row( lp, (None,len(B)-1), float )
        add_term( mat, row_0, sigma_t_k_m[(t,k,m)], -1 )
         
        for b in B:
             
            row_1 = create_row( lp, (0,None), float )
            add_term( mat, row_0, beta_t_b_k_m[(t,b,k,m)], 1 )
            add_term( mat, row_1, beta_t_b_k_m[(t,b,k,m)], 1 )
            add_term( mat, row_1, sigma_t_k_m[(t,k,m)],-1 )
        
    # Create SLEs representing thresholding constraints.
    for (k,m) in it.product(K,M):
        
        row = create_row( lp, (None,e_m[m]+max_e_m), float )
        add_term( mat, row, e_t['H'], 1 )
        add_term( mat, row, sigma_t_k_m[('H',k,m)], max_e_m )
        
        row = create_row( lp, (None,-e_m[m]+max_e_m), float )
        add_term( mat, row, e_t['L'], -1 )
        add_term( mat, row, sigma_t_k_m[('L',k,m)], max_e_m )
        
    row = create_row( lp, (None,0), float )
    add_term( mat, row, e_t['L'], 1 )
    add_term( mat, row, e_t['H'], -1 )
        
    # Configure final settings with solver.
    lp.matrix = mat
    lp.obj[e_t['H']] = 1.0
    lp.obj[e_t['L']] = -1.0
    lp.obj.maximize = True
    
    # Determine relaxed solution
    print( 'Solving for relaxed solution...')
    lp.simplex()
    print( 'Optimization Status: ' + lp.status )
    assert( lp.status=='opt' )
    
    # Determine MILP solution.
    print( 'Solving with "Cut and Branch" solver...')
    lp.intopt()
    print( 'Optimization Status: ' + lp.status )
    assert( lp.status=='opt' )
    
    print( 'obj_val: ' + repr( lp.obj.value ) )
                
    for t in T:
        print( 'e_' + t + ': ' + repr( lp.cols[e_t[t]].value ) )
        print( 'delta_m_' + t + ': ' + repr( lp.cols[delta_m_t[t]].value ) )
    print( 'm_L_UB_-1: ' + repr( lp.cols[m_t_b_k[('L','UB',-1)]].value ) )
    
    for (k,t,b) in it.product(K,T,B):
        print( 'm_' + t + '_' + b + '_' + repr(k) + 
               ': ' + repr( lp.cols[m_t_b_k[(t,b,k)]].value ) )
    for k in K:
        print( 'delta_m_' + repr(k) + ': ' + repr( lp.cols[delta_m_k[k]].value ) )  
        for t in T:
            print( 'delta_m_' + t + '_' + repr(k) + ': ' + repr( lp.cols[delta_m_t_k[(t,k)]].value ) ) 
    
    pp.figure()
    pp.plot( e_m )
    pp.title( 'energy signal' )
    plot_grid()
    pp.show()
        
        
        
        
        
        
        
    