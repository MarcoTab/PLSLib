envMU <- function(M, U, u, initial = NULL) {

  dimM <- dim(M)
  dimU <- dim(U)
  r <- dimM[1]
  
  if (dimM[1] != dimM[2] & dimU[1] != dimU[2]) stop("M and U should be square matrices.")
  if (dimM[1] != dimU[1]) stop("M and U should have the same dimension.")
  if (qr(M)$rank < r) stop("M should be positive definite.")
  if (u > r & u < 0) stop("u should be between 0 and r.")
  

	if (u == 0) {
	
		Gammahat <- NULL
		Gamma0hat <- diag(r)
		MU <- M + U
		tmp.MU <- eigen(MU)
		objfun <- sum(log(tmp.MU$values))
		
	} else if (u == r) {
	  
	  Gammahat <- diag(r)
	  Gamma0hat <- NULL
	  tmp.M <- eigen(M)
	  objfun <- sum(log(tmp.M$values))
	  
	} else if (u == 1) {
	  
	  maxiter = 100
	  ftol = 1e-3
	  
      if (!is.null(initial)) {
          MU <- M + U
          tmp.MU <- eigen(MU)
          invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / tmp.MU$values, '*') %*% t(tmp.MU$vectors)
          init <- initial
          eig1 <- eigen(t(init) %*% M %*% init)
          eig2 <- eigen(t(init) %*% invMU %*% init)
          obj1 <- sum(log(eig1$values)) + sum(log(eig2$values))
      } else {
          MU <- M + U
          tmp.MU <- eigen(MU)
          invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / tmp.MU$values, '*') %*% t(tmp.MU$vectors)
          invMU2 <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / sqrt(tmp.MU$values), '*') %*% t(tmp.MU$vectors)
	  
          midmatrix <- U
          startv <- function(a) t(a) %*% midmatrix %*% a
          tmp2.MU <- apply(tmp.MU$vectors, 2, startv)
          tmp3.MU <- sort(tmp2.MU, decreasing = TRUE, index.return = TRUE)
          init <- as.matrix(tmp.MU$vectors[, tmp3.MU$ix[1]])
	  
	  #		if (qr(MU)$rank == r) {
          eig1 <- eigen(t(init) %*% M %*% init)
          eig2 <- eigen(t(init) %*% invMU %*% init)
          obj1 <- sum(log(eig1$values)) + sum(log(eig2$values))
	  
          midmatrix <- invMU2 %*% tcrossprod(U, invMU2)
          tmp2.MU <- apply(tmp.MU$vectors, 2, startv)
          tmp3.MU <- sort(tmp2.MU, decreasing = TRUE, index.return = TRUE)
          init.MU <- as.matrix(tmp.MU$vectors[, tmp3.MU$ix[1]])
          e1 <- eigen(t(init.MU) %*% M %*% init.MU)
          e2 <- eigen(t(init.MU) %*% invMU %*% init.MU)
          obj2 <- sum(log(e1$values)) + sum(log(e2$values))
          if (obj2 < obj1) {
              init <- init.MU
              obj1 <- obj2
          }
	  
	  #			if (qr(M)$rank == r) {
          tmp.M <- eigen(M)
          midmatrix <- U
          tmp2.M <- apply(tmp.M$vectors, 2, startv)
          tmp3.M <- sort(tmp2.M, decreasing = TRUE, index.return = TRUE)
          init.M <- as.matrix(tmp.M$vectors[, tmp3.M$ix[1]])
          e1 <- eigen(t(init.M) %*% M %*% init.M)
          e2 <- eigen(t(init.M) %*% invMU %*% init.M)
          obj3 <- sum(log(e1$values)) + sum(log(e2$values))
          if (obj3 < obj1) {
              init <- init.M
              obj1 <- obj3
          }
	  
          invM2 <- sweep(tmp.M$vectors, MARGIN = 2, 1 / sqrt(tmp.M$values), '*') %*% t(tmp.M$vectors)
          midmatrix <- invM2 %*% tcrossprod(U, invM2)
          tmp2.M <- apply(tmp.M$vectors, 2, startv)
          tmp3.M <- sort(tmp2.M, decreasing = TRUE, index.return = TRUE)
          init.M <- as.matrix(tmp.M$vectors[, tmp3.M$ix[1]])
	  
          e1 <- eigen(t(init.M) %*% M %*% init.M)
          e2 <- eigen(t(init.M) %*% invMU %*% init.M)
          obj4 <- sum(log(e1$values)) + sum(log(e2$values))
          if (obj4 < obj1) {
            init <- init.M
            obj1 <- obj4
          }
      }
      
	  GEidx <- GE(init)
	  Ginit <- init %*% solve(init[GEidx[1], ])
	  
	  i <- 1
	  while (i < maxiter) {
	    
	    fobj <- function(x) {
	      T1 <- crossprod(x, x)
	      T2 <- crossprod(x, M) %*% x
	      T3 <- crossprod(x, invMU) %*% x
	      -2 * log(T1) + log(T2) + log(T3)
	    }
	    
	    gobj <- function(x) {
	      W1 <- crossprod(x, x)
	      T1 <- x / as.vector(W1)
	      W2 <- crossprod(x, M) %*% x
	      T2 <- M %*% x / as.vector(W2)
	      W3 <- crossprod(x, invMU) %*% x
	      T3 <- invMU %*% x / as.vector(W3)
	      -2 * T1 + T2 + T3
	    }
	    
	    res <- stats::optim(Ginit, fobj, gobj, method = "BFGS")
	    g <- as.matrix(res$par)
	    a <- qr(g)
	    Gammahat <- qr.Q(a)
	    e1 <- eigen(t(Gammahat) %*% M %*% Gammahat)
	    e2 <- eigen(t(Gammahat) %*% invMU %*% Gammahat)				
	    obj5 <- sum(log(e1$values)) + sum(log(e2$values))	
	    if (abs(obj1 - obj5) < ftol * abs(obj1)) {
	      break
	    } else {
	      obj1 <- obj5
	      i <- i + 1
	    }
	  }
	  Gamma0hat <- qr.Q(a, complete = TRUE)[, (u+1):r]
	  objfun <- obj5 + sum(log(tmp.MU$values))
    Gammahat <- as.matrix(Gammahat)
    Gamma0hat <- as.matrix(Gamma0hat)
	  
	} else if (u == r - 1 & u != 1) {
	
	  maxiter = 100
	  ftol = 1e-3
      
      if (!is.null(initial)) {
          MU <- M + U
          tmp.MU <- eigen(MU)
          invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / tmp.MU$values, '*') %*% t(tmp.MU$vectors)
          init <- initial
          eig1 <- eigen(t(init) %*% M %*% init)
          eig2 <- eigen(t(init) %*% invMU %*% init)
          obj1 <- sum(log(eig1$values)) + sum(log(eig2$values))
      } else {
	  MU <- M + U
	  tmp.MU <- eigen(MU)
	  invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / tmp.MU$values, '*') %*% t(tmp.MU$vectors)
	  invMU2 <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / sqrt(tmp.MU$values), '*') %*% t(tmp.MU$vectors)
	  
	  midmatrix <- U
	  startv <- function(a) t(a) %*% midmatrix %*% a
	  tmp2.MU <- apply(tmp.MU$vectors, 2, startv)
	  tmp3.MU <- sort(tmp2.MU, decreasing = TRUE, index.return = TRUE)
	  init <- as.matrix(tmp.MU$vectors[, tmp3.MU$ix[1:u]]) 
	  
#	  if (qr(MU)$rank == r) {
	    eig1 <- eigen(t(init) %*% M %*% init)
	    eig2 <- eigen(t(init) %*% invMU %*% init)
	    obj1 <- sum(log(eig1$values)) + sum(log(eig2$values))
	    
	    midmatrix <- invMU2 %*% tcrossprod(U, invMU2) 
	    tmp2.MU <- apply(tmp.MU$vectors, 2, startv)
	    tmp3.MU <- sort(tmp2.MU, decreasing = TRUE, index.return = TRUE)
	    init.MU <- as.matrix(tmp.MU$vectors[, tmp3.MU$ix[1:u]])
	    e1 <- eigen(t(init.MU) %*% M %*% init.MU)
	    e2 <- eigen(t(init.MU) %*% invMU %*% init.MU)
	    obj2 <- sum(log(e1$values)) + sum(log(e2$values))		
	    if (obj2 < obj1) {
	      init <- init.MU
	      obj1 <- obj2
	    }
	    
#	    if (qr(M)$rank == r) {
	      tmp.M <- eigen(M)
	      midmatrix <- U
	      tmp2.M <- apply(tmp.M$vectors, 2, startv)
	      tmp3.M <- sort(tmp2.M, decreasing = TRUE, index.return = TRUE)	
	      init.M <- as.matrix(tmp.M$vectors[, tmp3.M$ix[1:u]])
	      e1 <- eigen(t(init.M) %*% M %*% init.M)
	      e2 <- eigen(t(init.M) %*% invMU %*% init.M)
	      obj3 <- sum(log(e1$values)) + sum(log(e2$values))			
	      if (obj3 < obj1) {
	        init <- init.M
	        obj1 <- obj3
	      }
	      
	      invM2 <- sweep(tmp.M$vectors, MARGIN = 2, 1 / sqrt(tmp.M$values), '*') %*% t(tmp.M$vectors)
	      midmatrix <- invM2 %*% tcrossprod(U, invM2) 
	      tmp2.M <- apply(tmp.M$vectors, 2, startv)
	      tmp3.M <- sort(tmp2.M, decreasing = TRUE, index.return = TRUE)
	      init.M <- as.matrix(tmp.M$vectors[, tmp3.M$ix[1:u]])				
	      
	      e1 <- eigen(t(init.M) %*% M %*% init.M)
	      e2 <- eigen(t(init.M) %*% invMU %*% init.M)			
	      obj4 <- sum(log(e1$values)) + sum(log(e2$values))			
	      if (obj4 < obj1) {
	        init <- init.M
	        obj1 <- obj4
	      }
      }
#	    }
#	  }
	  
	  GEidx <- GE(init)
	  Ginit <- init %*% solve(init[GEidx[1:u], ])		
	  
	  j <- GEidx[r]
	  
	  g <- as.matrix(Ginit[j, ])
	  t2 <- crossprod(Ginit[-j, ], as.matrix(M[-j, j])) / M[j, j]
	  t3 <- crossprod(Ginit[-j, ], as.matrix(invMU[-j, j])) / invMU[j, j]
	  
	  GUGt2 <- g + t2
	  GUG <- crossprod(Ginit, (M %*% Ginit)) - tcrossprod(GUGt2, GUGt2) * M[j, j]
	  
	  GVGt2 <- g + t3
	  GVG <- crossprod(Ginit, (invMU %*% Ginit)) - tcrossprod(GVGt2, GVGt2) * invMU[j, j] 
	  
	  invC1 <- chol2inv(chol(GUG))
	  invC2 <- chol2inv(chol(GVG))
	  
	  fobj <- function(x) {
	    tmp2 <- x + t2
	    tmp3 <- x + t3
	    T2 <- invC1 %*% tmp2	
	    T3 <- invC2 %*% tmp3
	    -2 * log(1 + sum(x^2)) + log(1 + M[j, j] * crossprod(tmp2, T2)) + log(1 + invMU[j, j] * crossprod(tmp3, T3))
	  }
	  
	  gobj <- function(x) {
	    tmp2 <- x + t2
	    tmp3 <- x + t3
	    T2 <- invC1 %*% tmp2	
	    T3 <- invC2 %*% tmp3
	    -4 	* x %*% solve(1 + sum(x^2)) + 2 * T2 / as.numeric(1 / M[j, j] + crossprod(tmp2, T2)) + 2 * T3 / as.numeric(1 / invMU[j, j] + crossprod(tmp3, T3))	
	  }
	  
	  i <- 1
	  while (i < maxiter) {
	    
	    res <- stats::optim(Ginit[j,], fobj, gobj, method = "BFGS")
	    Ginit[j, ] <- res$par
	    
	    a <- qr(Ginit)
	    Gammahat <- qr.Q(a)
	    e1 <- eigen(t(Gammahat) %*% M %*% Gammahat)
	    e2 <- eigen(t(Gammahat) %*% invMU %*% Gammahat)				
	    obj5 <- sum(log(e1$values)) + sum(log(e2$values))	
	    if (abs(obj1 - obj5) < ftol * abs(obj1)) {
	      break
	    } else {
	      obj1 <- obj5
	      i <- i + 1
	    }
	  }
	  
	  Gamma0hat <- qr.Q(a, complete = TRUE)[, (u+1):r, drop = FALSE]
	  objfun <- obj5 + sum(log(tmp.MU$values))
      Gammahat <- as.matrix(Gammahat)
      Gamma0hat <- as.matrix(Gamma0hat)
		
	} else {

		maxiter = 100
		ftol = 1e-3
        
        if (!is.null(initial)) {
            MU <- M + U
            tmp.MU <- eigen(MU)
            invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / tmp.MU$values, '*') %*% t(tmp.MU$vectors)
            init <- initial
            eig1 <- eigen(t(init) %*% M %*% init)
            eig2 <- eigen(t(init) %*% invMU %*% init)
            obj1 <- sum(log(eig1$values)) + sum(log(eig2$values))
        } else {
		MU <- M + U
		tmp.MU <- eigen(MU)
		invMU <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / tmp.MU$values, '*') %*% t(tmp.MU$vectors)
        invMU2 <- sweep(tmp.MU$vectors, MARGIN = 2, 1 / sqrt(tmp.MU$values), '*') %*% t(tmp.MU$vectors)
		
        midmatrix <- U
        startv <- function(a) t(a) %*% midmatrix %*% a
		tmp2.MU <- apply(tmp.MU$vectors, 2, startv)
		tmp3.MU <- sort(tmp2.MU, decreasing = TRUE, index.return = TRUE)
		init <- as.matrix(tmp.MU$vectors[, tmp3.MU$ix[1:u]]) 
			
#		if (qr(MU)$rank == r) {
			eig1 <- eigen(t(init) %*% M %*% init)
			eig2 <- eigen(t(init) %*% invMU %*% init)
			obj1 <- sum(log(eig1$values)) + sum(log(eig2$values))
			
			midmatrix <- invMU2 %*% tcrossprod(U, invMU2) 
			tmp2.MU <- apply(tmp.MU$vectors, 2, startv)
			tmp3.MU <- sort(tmp2.MU, decreasing = TRUE, index.return = TRUE)
			init.MU <- as.matrix(tmp.MU$vectors[, tmp3.MU$ix[1:u]])
			e1 <- eigen(t(init.MU) %*% M %*% init.MU)
			e2 <- eigen(t(init.MU) %*% invMU %*% init.MU)
			obj2 <- sum(log(e1$values)) + sum(log(e2$values))		
			if (obj2 < obj1) {
				init <- init.MU
				obj1 <- obj2
			}
			
#			if (qr(M)$rank == r) {
				tmp.M <- eigen(M)
				midmatrix <- U
				tmp2.M <- apply(tmp.M$vectors, 2, startv)
				tmp3.M <- sort(tmp2.M, decreasing = TRUE, index.return = TRUE)	
				init.M <- as.matrix(tmp.M$vectors[, tmp3.M$ix[1:u]])
				e1 <- eigen(t(init.M) %*% M %*% init.M)
				e2 <- eigen(t(init.M) %*% invMU %*% init.M)
				obj3 <- sum(log(e1$values)) + sum(log(e2$values))			
				if (obj3 < obj1) {
					init <- init.M
					obj1 <- obj3
				}
				
				invM2 <- sweep(tmp.M$vectors, MARGIN = 2, 1 / sqrt(tmp.M$values), '*') %*% t(tmp.M$vectors)
				midmatrix <- invM2 %*% tcrossprod(U, invM2) 
				tmp2.M <- apply(tmp.M$vectors, 2, startv)
				tmp3.M <- sort(tmp2.M, decreasing = TRUE, index.return = TRUE)
				init.M <- as.matrix(tmp.M$vectors[, tmp3.M$ix[1:u]])				

				e1 <- eigen(t(init.M) %*% M %*% init.M)
				e2 <- eigen(t(init.M) %*% invMU %*% init.M)			
				obj4 <- sum(log(e1$values)) + sum(log(e2$values))			
				if (obj4 < obj1) {
					init <- init.M
					obj1 <- obj4
				}
        }
#			}
#		}
		
		GEidx <- GE(init)
		Ginit <- init %*% solve(init[GEidx[1:u], ])


		GUG <- crossprod(Ginit, (M %*% Ginit))	
		GVG <- crossprod(Ginit, (invMU %*% Ginit))		

		
		t4 <- crossprod(Ginit[GEidx[(u+1):r],], Ginit[GEidx[(u+1):r], ]) + diag(u)
		i <- 1
		while (i < maxiter) {
			
			for (j in GEidx[(u+1):r]) {
				g <- as.matrix(Ginit[j, ])
				t2 <- crossprod(Ginit[-j, ], as.matrix(M[-j, j])) / M[j, j]
				t3 <- crossprod(Ginit[-j, ], as.matrix(invMU[-j, j])) / invMU[j, j]
				
				GUGt2 <- g + t2
				GUG <- GUG - tcrossprod(GUGt2, GUGt2) * M[j, j]
				
				GVGt2 <- g + t3
				GVG <- GVG - tcrossprod(GVGt2, GVGt2) * invMU[j, j] 
				
				t4 <- t4 - tcrossprod(g, g)
				invC1 <- chol2inv(chol(GUG))
				invC2 <- chol2inv(chol(GVG))
				invt4 <- chol2inv(chol(t4))				
										
				fobj <- function(x) {
					tmp2 <- x + t2
					tmp3 <- x + t3
					T1 <- invt4 %*% x
					T2 <- invC1 %*% tmp2	
					T3 <- invC2 %*% tmp3
					-2 * log(1 + x %*% T1) + log(1 + M[j, j] * crossprod(tmp2, T2)) + log(1 + invMU[j, j] * crossprod(tmp3, T3))
				}
			
				gobj <- function(x) {
					tmp2 <- x + t2
					tmp3 <- x + t3
					T1 <- invt4 %*% x
					T2 <- invC1 %*% tmp2	
					T3 <- invC2 %*% tmp3
					-4 	* T1 / as.numeric(1 + x %*% T1) + 2 * T2 / as.numeric(1 / M[j, j] + crossprod(tmp2, T2)) + 2 * T3 / as.numeric(1 / invMU[j, j] + crossprod(tmp3, T3))	
				}
			
				res <- stats::optim(Ginit[j,], fobj, gobj, method = "BFGS")
				Ginit[j, ] <- res$par
				g <- as.matrix(Ginit[j, ])
				t4 <- t4 + tcrossprod(g, g)
				GUGt2 <- g + t2
				GUG <- GUG + tcrossprod(GUGt2, GUGt2) * M[j, j]
				
				GVGt2 <- g + t3
				GVG <- GVG + tcrossprod(GVGt2, GVGt2) * invMU[j, j] 
				
				
			}
			a <- qr(Ginit)
			Gammahat <- qr.Q(a)
			e1 <- eigen(t(Gammahat) %*% M %*% Gammahat)
			e2 <- eigen(t(Gammahat) %*% invMU %*% Gammahat)				
			obj5 <- sum(log(e1$values)) + sum(log(e2$values))	
			if (abs(obj1 - obj5) < ftol * abs(obj1)) {
				break
			} else {
				obj1 <- obj5
				i <- i + 1
			}
		}

		Gamma0hat <- qr.Q(a, complete = TRUE)[, (u+1):r]
		objfun <- obj5 + sum(log(tmp.MU$values))
    Gammahat <- as.matrix(Gammahat)
    Gamma0hat <- as.matrix(Gamma0hat)
		
	}
	return(list(Gammahat = Gammahat, Gamma0hat = Gamma0hat, objfun = objfun))
}
