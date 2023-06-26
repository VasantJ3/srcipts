#!/bin/bash
set -e
# Run this bash file using super user privilege

# Constants
# !!! Add '/' at the end for all the path constants

USER=$USER
PYTHON_VER='3.7'
WORK_DIR='/home/'$USER'/chromite_bb/'
CONDA_INSTALLATION_DIR=${WORK_DIR}'conda/'
BLUESPEC_DIR=${WORK_DIR}'bluespec/'
GNU_TOOLCHAIN_DIR=${WORK_DIR}'gnu_toolchain/'
MOD_SPIKE_DIR=${WORK_DIR}'mod-spike/'

welcome() {
  echo Hello $USER! 
  echo This installation script will help you to get started with setting up requirements.
  sudo apt-get update
  sudo apt install git
  mkdir -p $WORK_DIR
}

bluespec() {
  mkdir -p $BLUESPEC_DIR
  sudo apt install -y ghc libghc-regex-compat-dev libghc-syb-dev iverilog
  sudo apt install -y libghc-old-time-dev libfontconfig1-dev libx11-dev
  sudo apt install -y libghc-split-dev libxft-dev flex bison libxft-dev
  sudo apt install -y tcl-dev tk-dev libfontconfig1-dev libx11-dev gperf
  sudo apt install -y itcl3-dev itk3-dev autoconf git
  sudo apt install -y libcanberra-gtk-module libcanberra-gtk3-module
  sudo apt-get -y install gtkwave

  cd $BLUESPEC_DIR
  if [ ! -d "bsc" ] ; then
    git clone --recursive "https://github.com/B-Lang-org/bsc"
  fi
  cd bsc
  make install-src
  cd $WORK_DIR
  echo 'export PATH=$PATH:'${BLUESPEC_DIR}'/bsc/inst/bin' >> ~/.bashrc
  source ~/.bashrc
}

verilator(){
  # Install Verilator 4.106
  sudo apt-get -y install git perl python3 make
  sudo apt-get -y install g++

  sudo apt-get -y install ccache  # If present at build, needed for run
  sudo apt-get -y install libgoogle-perftools-dev numactl perl-doc
  sudo apt-get -y install git autoconf flex bison

  cd $WORK_DIR
  if [ ! -d "verilator" ] ; then
    git clone https://github.com/verilator/verilator
  fi
  unset VERILATOR_ROOT  # For bash shell
  cd verilator
  git checkout v4.106
  autoconf
  ./configure
  make -j4
  sudo make install
}

gnu_toolchain() {

  sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
  mkdir -p $GNU_TOOLCHAIN_DIR
  cd $WORK_DIR
  if [ ! -d "riscv-gnu-toolchain" ] ; then
    git clone "https://github.com/riscv/riscv-gnu-toolchain"
  fi

  cd riscv-gnu-toolchain/
  git checkout 1a36b5dc44d71ab6a583db5f4f0062c2a4ad963b
  ./configure --prefix=/home/<user>/chromitem_tools/myriscv/ --with-arch=rv64imac --with-abi=lp64 --with-cmodel=medany
  sudo make -j8
  echo 'export PATH=$PATH:'${GNU_TOOLCHAIN_DIR}'bin' >>~/.bashrc
  source ~/.bashrc
  cd $WORK_DIR
}

mod_spike() {
  #installing device tree compiler
  sudo apt-get install device-tree-compiler

  # installing Mod-spike
  # cd $WORK_DIR
  # if [ ! -d "mod-spike" ] ; then
    #git clone "https://gitlab.com/shaktiproject/tools/mod-spike"
  #fi
  #echo "cloned mod-spike"
  #cd $MOD_SPIKE_DIR
  #git checkout bump-to-latest
  if [ ! -d "riscv-isa-sim" ] ; then
    git clone "https://github.com/riscv/riscv-isa-sim.git"
  fi
  cd riscv-isa-sim/
  git checkout a04da860635b4e94fc05f23f75fd99578258bc3e
  #git apply ../shakti.patch
  export RISCV=$GNU_TOOLCHAIN_DIR
  mkdir -p build
  cd build
  ../configure --prefix=$RISCV --enable-commitlog
  sudo make
  sudo make install
  cd $HOME_DIR
  echo 'export PATH=$PATH:'${MOD_SPIKE_DIR}'/riscv-isa-sim/build/' >>~/.bashrc
  source ~/.bashrc
}

miniconda() {
  if [ -d $CONDA_INSTALLATION_DIR ]; then
    echo ${CONDA_INSTALLATION_DIR}" exists"
  else
    mkdir -p $CONDA_INSTALLATION_DIR
    echo ${CONDA_INSTALLATION_DIR}" created"
  fi

  if [ -e ${CONDA_INSTALLATION_DIR}miniconda.sh ]; then
    echo ${CONDA_INSTALLATION_DIR}"miniconda.sh already exists"
  else
    echo "downloading "${CONDA_INSTALLATION_DIR}"miniconda.sh"
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ${CONDA_INSTALLATION_DIR}miniconda.sh
    echo ${CONDA_INSTALLATION_DIR}"miniconda.sh downloaded"
  fi

  bash ${CONDA_INSTALLATION_DIR}miniconda.sh
  # TODO: yes to licence, enter to location, yes to conda init
  #  rm -rf ~/miniconda3/miniconda.sh

  ~/miniconda3/bin/conda init bash
  printf '\n# add path to conda\nexport PATH='${CONDA_INSTALLATION_DIR}'miniconda3/bin:$PATH\n' >>~/.bashrc
  source ~/.bashrc
}

close() {
  #echo 'Finished installing riscv-gnu toolchain, bluespec compiler, mod-spike and miniconda'
  echo 'Thank You. Please close and restart the terminal to view the changes.'
}

welcome

read -p "Do you wish to install bluespec? (y/n) " yn
case $yn in
    [Yy]* ) bluespec;;
    [Nn]* ) true ;;
    * ) echo "Please answer yes or no.";;
esac

echo
echo
read -p "Do you wish to install verilator? (y/n) " yn
case $yn in
    [Yy]* ) verilator;;
    [Nn]* ) true;;
    * ) echo "Please answer yes or no.";;
esac

echo
echo
read -p "Do you wish to install riscv gnu_toolchain? (y/n) " yn
case $yn in
    [Yy]* ) gnu_toolchain;;
    [Nn]* ) true;;
    * ) echo "Please answer yes or no.";;
esac

echo
echo
read -p "Do you wish to install mod_spike? (y/n) " yn
case $yn in
    [Yy]* ) mod_spike;;
    [Nn]* ) true;;
    * ) echo "Please answer yes or no.";;
esac

echo
echo
read -p "Do you wish to install miniconda? (y/n) " yn
case $yn in
    [Yy]* ) miniconda;;
    [Nn]* ) true;;
    * ) echo "Please answer yes or no.";;
esac
close
