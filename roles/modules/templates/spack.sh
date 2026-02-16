# Spack environment setup for all users

# Requires that the following be set on the modules.yaml file of spack (<spack_dir>/etc/spack/defaults/modules.yaml):
# modules:
#  ...
#  default:
#    ...
#    enable: ["lmod"]

export LMOD_QUIET=1
export SPACK_ROOT=/opt/ohpc/pub/apps/spack/{{ spack_version }}
