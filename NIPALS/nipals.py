import numpy as np

class nipals:
    """
        Orthogonal weights: :math:`W^T_q W_q = I_q`

        Envelope connection: :math:`\mathrm{span}(W_q) = \mathcal{E}_{\Sigma_X}(\mathcal{B})`, the :math:`\Sigma_X`-envelope of :math:`\mathcal{B} \mathrel{\\vcenter{:}}= \mathrm{span}(\\beta)`.

        Score matrix :math:`S_d`: These are traditional computational intermediaries,
        although they are not needed in the computation of :math:`\hat{\\beta}_{\mathrm{npls}}`.

        Algorithm :math:`\mathbb{N}`: This is an instance of Algorithm :math:`\mathbb{N}` discussed in §1.5.3.

        PLS1 v. PLS2: Algorithm is applicable for PLS1 or PLS2 fits; See §3.8.
    """
    def __init__(self):
        self.q = None
        self.W = None
        self.beta = None

    def fit(self, X, Y, q, version='sample'):
        """    
            Fit this model to the training data `X`, `Y` using `q` dimensions. 

            :param X: Predictor of shape (`n_samples`, `p_features`)
            :type X: array-like
            :param Y: Response of shape (`n_samples`, `r_features`)
            :type Y: array-like
            :param q: Value between `1` and `p_features`. The number of projections used.
            :type q: int
            :param version: either 'sample' or 'population', defaults to 'sample'
            :type version: str
            :return: Nothing.
        """ 
        if (version != 'sample' or version != 'population'):
            raise ValueError(f"version must be 'sample' or 'population', not {version}.")
        
        if (len(X.shape) != 2 or len(Y.shape) != 2):
            raise ValueError(f"X and Y must be 2 dimensional array-like. Current dimensions: {len(X.shape)} and {len(Y.shape)}.")
        
        if (X.shape[0] != Y.shape[0]):
            raise ValueError(f"X and Y must have the same first dimension. Current shapes: {X.shape} and {Y.shape}.")
        
        self.q = int(q)

        if (self.q < 1 or self.q > X.shape[1]):
            raise ValueError(f"q should be 1 and X's second dimension. Currently {q} and {X.shape[1]}.")
        

        if (version == 'sample'):
            curX = X
            curY = Y
            n = X.shape[0]

            weights = None
            scores = None
            xloads = None
            yloads = None

            xloadsmat = np.zeros(0)
            yloadsmat = np.zeros(0)
            scoresmat = np.zeros(0)
            self.W = np.zeros(0)

            for _ in range(self.q):
                # Compute sample covariance matrix
                sample_cov = (1/n) * curX.T @ curY
                
                # Get eigenvectors
                _, evecs = np.linalg.eigh(sample_cov)
                # largest normalized eigenvector is the weight
                weights = evecs[::-1][:, 0]

                # Compute scores
                scores = curX @ weights

                # Compute X and Y loadings
                xloads = (curX.T @ scores) / (scores.T @ scores)
                yloads = (curY.T @ scores) / (scores.T @ scores)

                # Deflation for X and Y
                curX = curX - (scores @ xloads.T)
                curY = curY - (scores @ yloads.T)

                # Concatenate onto matrices
                self.W = np.concatenate((self.W, weights), axis=1)
                xloadsmat = np.concatenate((xloadsmat, xloads), axis=1)
                yloadsmat = np.concatenate((yloadsmat, yloads), axis=1)
                scoresmat = np.concatenate((scoresmat, scores), axis=1)

            # Compute regression coefficients
            self.beta = self.W @ np.linalg.inv(xloadsmat.T @ self.W) @ yloadsmat.T

        else:
            ...
            XY_cov = np.cov(X.T @ Y)
            _, eigvecs = np.linalg.eigh(XY_cov @ XY_cov.T)
            weights = eigvecs[::-1][0]
            self.W = weights
            X_cov = np.cov(X)

            for d in range(self.q):
                

                P = self.W @ np.linalg.inv(self.W.T @ X_cov @ self.W) @ self.W.T @ X_cov

                Q = np.eye(P.shape[0], P.shape[1]) - P

                # Stopping condition
                if (np.abs(Q.T @ XY_cov) <= 1e-10):
                    self.q = d
                    break
                
                # Compute weights
                _, eigvecs = np.linalg.eigh(Q.T @ XY_cov @ XY_cov.T @ Q)
                weights = eigvecs[::-1][0]
                
                # Append
                self.W = np.concatenate((self.W, weights), axis=1)

            # Compute regression coefficients
            self.beta = self.W @ np.linalg.inv(self.W.T @ X_cov @ self.W) @ self.W.T @ XY_cov


    def transform(self, X):
        """
            Transform data using the NIPALS algorithm. Must run :meth:`NIPALS.nipals.nipals.fit` before running this function.

            :param X: Predictor of shape (`n_samples`, `p_features`)
            :type X: array-like
            :return: The :math:`W` and :math:`\\beta` transformed data, respectively.
            :rtype: tuple(array-like, array-like)
        """

        if (self.q is None or self.W is None or self.beta is None):
            raise Exception("You must run `fit` before running this function.")
        
        return self.W.T @ X, self.beta.T @ X

