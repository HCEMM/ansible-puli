help([[
Miniconda3 (Python 3.12)
System-wide installation.

Usage:
  module load miniconda3
  conda create -n myenv python=3.12
  conda activate myenv
]])

whatis("Name: Miniconda3")
whatis("Version: 24.7.1")
whatis("Category: Python")
whatis("Keywords: python, conda")
whatis("URL: https://docs.conda.io")

local root = "/opt/miniconda3"

-- Core paths
prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("PATH", pathJoin(root, "condabin"))

-- Conda config
setenv("CONDA_ROOT", root)
setenv("CONDA_ENVS_PATH", pathJoin(os.getenv("HOME"), ".conda", "envs"))
setenv("CONDA_PKGS_DIRS", pathJoin(os.getenv("HOME"), ".conda", "pkgs"))

-- Tell users what to do (don’t force shell hacks)
if mode() == "load" then
    LmodMessage("Run: source $CONDA_ROOT/etc/profile.d/conda.sh")
end