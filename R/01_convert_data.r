### For general methods.

convert.data <- function(X, method.own.X = c("spmdr", "common", "single"),
    rank.own.X = .SPMD.CT$rank.source, comm = .SPMD.CT$comm){
  COMM.SIZE <- spmd.comm.size(comm)
  COMM.RANK <- spmd.comm.rank(comm)

  # Assign X to .pmclustEnv
  if(is.ddmatrix(X)){
    # For a ddmatrix.

    .pmclustEnv$X.spmd <- as.spmd(X, comm = comm)
  } else{
    # for a spmd matrix.

    if(method.own.X[1] == "spmdr"){
      # For spmd row-major

      p <- ncol(X)
      p.all <- spmd.allgather.integer(p, integer(COMM.SIZE), comm = comm)
      if(any(p.all != p)){
        comm.stop("X should have the same # of columns.")
      }

      .pmclustEnv$X.spmd <- X
    } else if(method.own.X[1] == "common"){
      # X is common in all ranks.

      N <- nrow(X)
      N.all <- spmd.allgather.integer(N, integer(COMM.SIZE), comm = comm)
      if(any(N.all != N)){
        comm.stop("X should have the same # of rows.")
      }

      p <- ncol(X)
      p.all <- spmd.allgather.integer(p, integer(COMM.SIZE), comm = comm)
      if(any(p.all != p)){
        comm.stop("X should have the same # of columns.")
      }

      jid <- get.jid(nrow(X))
      .pmclustEnv$X.spmd <- X[jid,]
    } else if(method.own.X[1] == "single"){
      # X only exist in a single rank, 0 by default.

      p <- -1
      if(COMM.RANK == rank.own.X){
        if(is.matrix(X)){
          p <- ncol(X)
        }
      }

      p <- spmd.bcast.integer(p, rank.source = rank.own.X, comm = comm)
      if(p == -1){
        comm.stop("X should be a matrix in rank 0.")
      } else{
        if(COMM.RANK != rank.own.X){
          X <- matrix(0, nrow = 0, ncol = p)
        }
      }

      .pmclustEnv$X.spmd <- load.balance(X)
    } else{
      comm.stop("method.own.X is not found.")
    }
  }

  invisible()
} # End of convert.data().