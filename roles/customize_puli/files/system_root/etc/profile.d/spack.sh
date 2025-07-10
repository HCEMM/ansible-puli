# Spack environment setup for all users

# Requires that the following be set on the modules.yaml file of spack (<spack_dir>/etc/spack/defaults/modules.yaml):
# modules:
#  ...
#  default:
#    ...
#    enable: ["lmod"]

export LMOD_QUIET=1
module use /opt/spack/share/spack/lmod/linux-rocky9-x86_64/Core/
unset LMOD_QUIET