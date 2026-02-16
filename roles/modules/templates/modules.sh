module use {{ modules_custom_location }}                                    # custom modules (e.g., Miniconda3)
module use /opt/ohpc/pub/apps/spack/0.23.1/share/spack/lmod/gcc/14.2.0      # Spack modules for gcc 14.2.0, which is the compiler we use for Spack packages
module use /opt/ohpc/pub/moduledeps/spack                                   # OpenHPC overlay
module use /opt/ohpc/pub/apps/spack/0.23.1/share/spack/lmod/Core            # Spack modules
module use /opt/ohpc/pub/modulefiles                                        # OpenHPC modules (cmake, gnu14, MPI)