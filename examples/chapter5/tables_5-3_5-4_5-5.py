### UNFINISHED ###


import warnings
warnings.filterwarnings("ignore")

import numpy as np
from sklearn.linear_model import LinearRegression, LassoCV
import scipy as sp
from sklearn.cross_decomposition import PLSRegression
import matplotlib.pyplot as plt
import pandas as pd
from tqdm import tqdm

from lib.ch5_misc_utils import *


def sim_fun(i, p, r, dx, dy, N, M, simul_vers=1):
    assert 1 <= simul_vers <= 3, f"simul_vers must be 1, 2, or 3. Got {simul_vers = }"

    np.random.seed(5)

    # Envelopes model parameters

    trueG_temp = np.random.uniform(low=0, high=1, size=(p, dx))

    trueG, _, _ = np.linalg.svd(trueG_temp, full_matrices=False)

    trueG0, _ = np.linalg.qr(trueG, mode="complete")

    trueG0 = np.delete(trueG0, slice(0, dx), 1)
    
    trueH_temp = np.random.uniform(low=0, high=1, size=(r, dy))

    trueH, _, _ = np.linalg.svd(trueH_temp, full_matrices=False)

    trueH0, _ = np.linalg.qr(trueH, mode="complete")

    trueH0 = np.delete(trueH0, slice(0, dy), 1)

    Eta = np.random.uniform(low=0, high=1, size=(dx, dy))

    if simul_vers == 1:
        # Case where two block go crazy and simul pls is better than simulenv at n=57 for case 1,2
        Omega = 500 * np.eye(dx)  # material variation in X
        Phi = 0.05 * np.eye(dy)  # material variation of Y|X
        Omega0 = np.eye(p-dx)  # immaterial variation in X
        Phi0 = 10 * np.eye(r-dy) # immaterial variation of Y|X

    elif simul_vers == 2:
        # case where simultaneous env is better than pls, but two block is the best
        Omega = 1 * np.eye(dx)  # material variation in X
        Phi = 0.1 * np.eye(dy)  # material variation of Y|X
        Omega0 = np.eye(p-dx)  # immaterial variation in X
        Phi0 = 10 * np.eye(r-dy) # immaterial variation of Y|X
    else:
        # case where simultaneous env is better than pls, and two block is not the best
        Omega = 50 * np.eye(dx)  # material variation in X
        Phi = 0.01 * np.eye(dy)  # material variation of Y|X
        Omega0 = np.eye(p-dx)  # immaterial variation in X
        Phi0 = 10 * np.eye(r-dy) # immaterial variation of Y|X


    # Regression coefficient and covariance matrices
    
    beta = trueH @ Eta.T @ trueG.T
    sigmaXY = trueG @ Omega @ Eta @ trueH.T
    sigmaX = trueG @ Omega @ trueG.T + trueG0 @ Omega0 @ trueG0.T
    sigmaY = trueH @ (Phi + Eta.T @ Omega @ Eta) @ trueH.T + trueH0 @ Phi0 @ trueH0.T
    sigmaC = np.vstack((np.hstack((sigmaX, sigmaXY)), np.hstack((sigmaXY.T, sigmaY)))) 
    sigmaD = sp.linalg.block_diag(sigmaX, sigmaY)

    d_twoblock_pop = cal_d_twoblock_fun(SigmaX=sigmaX, SigmaY=sigmaY, SigmaXY=sigmaXY, mytol=1e-3)

    if i == 0:
        print(f"The dimension of population two block PLS is {d_twoblock_pop}")

    np.random.seed(i)

    datavec = np.random.multivariate_normal(np.zeros((p+r,)), sigmaC, size=N+M)

    X = datavec[:, :p]
    Y = datavec[:, p:(p+r)]

    Xtrain = X[:N]  # Extract training features
    Ytrain = Y[:N]  # Extract training labels

    Xtest = X[N:]  # Extract test features. The original paper only calculates thye in sample MSE.
    Ytest = Y[N:]

    if_Xscale = False
    if_Yscale = False

    d_pls = dx

    predMSE2_twoblock_test = None
    predMSE1_twoblock_test = None
    betaMSE_twoblock = None
    
    predMSE2_pls_test = None
    predMSE1_pls_test = None
    betaMSE_pls = None

    predMSE2_simul_pls_test = None
    predMSE1_simul_pls_test = None
    betaMSE_simul_pls = None

    if (max(r,dx,dy,d_twoblock_pop) <= N):
        d_pls1 = np.ones((r,2))
        d_pls1[:, 0] = dx

        refit_result = refit_entire_training_and_get_testMSE_fun(
            Xtrain, Ytrain, Xtest, Ytest, d=d_twoblock_pop, d1=dx, d2=dy,
            d_pls=[dx, r], d_pls1=d_pls1,
            if_Xscale=if_Xscale, if_Yscale=if_Yscale
        )


sim_fun(i=0, p=50, r=4, dx=10, dy=3, N=1000, M=1000, simul_vers=1)