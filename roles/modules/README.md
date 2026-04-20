## Spack tips

To install a package against our chosen gcc compiler
```
ml spack      # root doesn't have this by default, all users do
spack install tree %gcc@14.2.0
spack module lmod refresh -y              # regenerate the modules, creates for the new tool
```

`spack spec r-deseq2@1.40.0 ^r@4.3.3` shows the dependencies to be installed and already installed.

## Why can't Spack install my R package?

If getting something like
```
==> r-deseq2: Executing phase: 'install'
==> Error: ProcessError: Command exited with status 1:
    '/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-4.3.3-7plawxr7tfwiujtdwuivetscpv27wfav/bin/R' '--vanilla' 'CMD' 'INSTALL' '--library=/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-deseq2-1.40.0-shagzyra7s55yuhqgb767flmjaxbht6r/rlib/R/library' '/tmp/root/spack-stage/spack-stage-r-deseq2-1.40.0-shagzyra7s55yuhqgb767flmjaxbht6r/spack-src'

2 errors found in build log:
     60    /opt/ohpc/pub/apps/spack/0.23.1/lib/spack/env/gcc/g++ -std=gnu++17 -I"/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-4.3.3-7plawxr7tfwiujtdwuivetscpv27wfav/rl
           ib/R/include" -DNDEBUG  -I'/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-rcpp-1.0.13-kjglahn3eeskagia6t5wt2yxn7rbax5k/rlib/R/library/Rcpp/include' -I'/opt/oh
           pc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-rcpparmadillo-14.0.0-1-dkalcobietfisdo5io23dksqzeq45dwy/rlib/R/library/RcppArmadillo/include' -I/usr/local/include    
           -fpic  -g -O2  -c RcppExports.cpp -o RcppExports.o
     61    /opt/ohpc/pub/apps/spack/0.23.1/lib/spack/env/gcc/g++ -std=gnu++17 -shared -L/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-4.3.3-7plawxr7tfwiujtdwuivetscpv27
           wfav/rlib/R/lib -Wl,-rpath,/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-4.3.3-7plawxr7tfwiujtdwuivetscpv27wfav/rlib/R/lib -o DESeq2.so DESeq2.o RcppExports.
           o -L/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/openblas-0.3.28-siuz2dgh5wneamxl5wt5yjl52vy5x3zk/lib -lopenblas -L/opt/ohpc/pub/apps/spack/local/linux-almali
           nux9-zen3/gcc-14.2.0/openblas-0.3.28-siuz2dgh5wneamxl5wt5yjl52vy5x3zk/lib -lopenblas -lgfortran -lm -lquadmath -L/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/
           r-4.3.3-7plawxr7tfwiujtdwuivetscpv27wfav/rlib/R/lib -lR
     62    installing to /opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-deseq2-1.40.0-shagzyra7s55yuhqgb767flmjaxbht6r/rlib/R/library/00LOCK-spack-src/00new/DESeq2/libs
     63    ** R
     64    ** inst
     65    ** byte-compile and prepare package for lazy loading
  >> 66    Error : in method for 'dispersionFunction<-' with signature 'object="DESeqDataSet",value="function"':  arguments ('value') after '...' in the generic must appear in the method, 
           in the same place at the end of the argument list
  >> 67    Error: unable to load R code in package 'DESeq2'
     68    Execution halted
     69    ERROR: lazy loading failed for package 'DESeq2'
     70    * removing '/opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-14.2.0/r-deseq2-1.40.0-shagzyra7s55yuhqgb767flmjaxbht6r/rlib/R/library/DESeq2'
```
Means Bioconductor is not playing ball with Spack. Like [here](https://github.com/spack/spack/issues/49333). 

[This](https://github.com/spack/spack/commit/1b24dfb8bafe86fbff47a9751b199e2707e3c23e#diff-100b68317ab04956110b4cdbe88d236f162fdfad3ef5c686ef689a4ca177766c) is a possible solution, by removing all R packages, and installing `r-summarizedexperiment@1.1.6` and `r-biocgenerics@0.7.5`. Will need to test it later.