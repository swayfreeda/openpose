#!/bin/bash
#
# Install python packages
#

DIR="$( builtin cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source $DIR/load_config.sh
cd "$REPO_DIR"

echo "Install Python packages..."

set -e

echo "Upgrading versiontools..."
pip install --upgrade versiontools

#apt-get install wget

#echo "Installing newest pip (>= 1.5) locally..."
#mkdir -p opt/pip
#cd opt/pip
#wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py -O get-pip.py
#python get-pip.py
#cd "$REPO_DIR"

echo "Installing setup packages (locally)..."
pip install --upgrade setuptools
pip install --upgrade distribute
pip install --upgrade versiontools

_install_python_packages() {
	echo "Installing python packages (locally) in a particular order..."
	for f in $(ls -1 $DIR/install/requirements-python-*.txt | sort); do
		pip install $PIP_OPTS -r $f
	done
}

_install_python_packages

# Install specific boto version from source (pip version was too in 2012).
# There was a bug in communicating with Amazon that was fixed and un-fixed
# repeatedly; the main repo seems unreliable.  This grabs a specific git commit
# that definitely has the fix.
echo ""
echo "Uninstalling old version of boto (to replace with the newest version)"
set +e
pip uninstall --no-input -y boto
set -e
[[ -d opt/boto ]] || git clone git://github.com/boto/boto.git opt/boto
cd opt/boto
git fetch --all
# checkout version with mturk bugfix
git reset --hard 8e1b6b81dbc70f1bd752b4331f2010357b640ee9
python setup.py install
cd "$REPO_DIR"

# install a custom patch of django-queued-storage from source (my own fork of
# the main repo).
echo ""
echo "Installing custom django-queued-storage"
set +e
pip uninstall --no-input -y django-queued-storage
set -e
[[ -d opt/django-queued-storage ]] || git clone git://github.com/seanbell/django-queued-storage.git opt/django-queued-storage
cd opt/django-queued-storage
git fetch --all
git reset --hard origin/develop
pip install -e .
cd "$REPO_DIR"

# install clint from forked source (since main repo was broken for at least
# 2012-2013).  note that this repo is not the main repo.
echo "Install clint from source"
set +e
pip uninstall --no-input -y clint
set -e
[[ -d opt/clint ]] || git clone git://github.com/Lothiraldan/clint.git opt/clint
cd opt/clint
# checkout version with args bugfix
git fetch --all
git reset --hard 0bb660b483303bfb80c4f30401d1b8970ce8061b
pip install -e .
cd "$REPO_DIR"

# install specific version of pilkit and imagekit (since the thumbnail hash is
# sensitive to version)
pip install "pilkit==0.1.2"
set +e
pip uninstall --no-input -y django-imagekit
set -e
echo "Install imagekit from source"
[[ -d opt/django-imagekit ]] || git clone git://github.com/jdriscoll/django-imagekit.git opt/django-imagekit
cd opt/django-imagekit
git fetch --all
git reset --hard 3.0a5
pip install -e .
cd "$REPO_DIR"

echo ""
echo "Installing cubam from source"
[[ -d opt/cubam ]] || git clone git://github.com/welinder/cubam.git opt/cubam
cd opt/cubam
rm -rf build
git fetch --all
git reset --hard fe5ba700f1adbb489c69af311558d64370d73d36
python setup.py install
cd "$REPO_DIR"

# unfortunately, something downgrades our installation of celery, so we need to
# re-upgrade it here (function defined above)
_install_python_packages
