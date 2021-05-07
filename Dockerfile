# Docker container for russian dissertation latex template:
# https://github.com/AndreyAkinshin/Russian-Phd-LaTeX-Dissertation-Template
FROM ubuntu:20.04

# Some of the installed packages depend on tzdata which requires interactive
# steps to setup. To avoid interaction, we setup everything here. Taken from
# https://rtfm.co.ua/en/docker-configure-tzdata-and-timezone-during-build/
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# Dependencies list from the template installation instructions (made for ubuntu 19.04)
# https://github.com/AndreyAkinshin/Russian-Phd-LaTeX-Dissertation-Template/blob/master/Readme/Installation.md#%D0%B2-ubuntu
# except for texlive-generic-extra which is absent in focal (20.04)
RUN apt-get update
RUN apt-get install -y make texlive-xetex \
    texlive-lang-cyrillic texlive-lang-french texlive-science \
    fonts-liberation latexmk biber

# EULA license for ttf-mscorefonts-installer is needy. Whants me to say yes.
# Fix for this taken from https://github.com/captnswing/msttcorefonts/blob/master/Dockerfile
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
RUN apt-get install -y ttf-mscorefonts-installer

RUN fc-cache -fv


# Download and install PSCyr. Adapted from here:
# https://github.com/senior-sigan/docker-latex/blob/master/src/install.sh
RUN apt-get install --yes wget zip unzip
RUN wget https://github.com/dmalt/thesis/raw/master/PSCyr/pscyr0.4d.zip
RUN unzip pscyr0.4d.zip -d /tmp/ && rm pscyr0.4d.zip && \
    mv /tmp/pscyr /tmp/PSCyr  && cd /tmp/PSCyr && \
    TEXMF=`kpsewhich -expand-var='$TEXMFLOCAL'` && \
    mkdir -p $TEXMF/tex/latex/pscyr $TEXMF/fonts/tfm/public/pscyr && \
    mkdir -p $TEXMF/fonts/vf/public/pscyr $TEXMF/fonts/type1/public/pscyr && \
    mkdir -p $TEXMF/fonts/afm/public/pscyr $TEXMF/doc/fonts/pscyr && \
    mkdir -p $TEXMF/fonts/enc/pscyr $TEXMF/fonts/map/dvips/pscyr && \
    mkdir fonts/map fonts/enc && \
    mv dvips/pscyr/*.map fonts/map/ && \
    mv dvips/pscyr/*.enc fonts/enc/ && \
    cp fonts/enc/* $TEXMF/fonts/enc/pscyr && \
    cp fonts/map/* $TEXMF/fonts/map/dvips/pscyr && \
    cp tex/latex/pscyr/* $TEXMF/tex/latex/pscyr && \
    cp fonts/tfm/public/pscyr/* $TEXMF/fonts/tfm/public/pscyr && \
    cp fonts/vf/public/pscyr/* $TEXMF/fonts/vf/public/pscyr && \
    cp fonts/type1/public/pscyr/* $TEXMF/fonts/type1/public/pscyr && \
    cp fonts/afm/public/pscyr/* $TEXMF/fonts/afm/public/pscyr && \
    cp LICENSE doc/README.koi doc/PROBLEMS $TEXMF/doc/fonts/pscyr && \
    VARTEXFONTS=`kpsewhich -expand-var='$VARTEXFONTS'` && \
    rm -f $VARTEXFONTS/pk/modeless/public/pscyr/* && \
    mkdir $TEXMF/web2c/ && \
    echo "Map pscyr.map" >> $TEXMF/web2c/updmap.cfg && \
    mktexlsr && \
    updmap-sys

# Setting up dirs so our container works as a terminal command for compilation
# like dockertex: https://github.com/raabf/dockertex/blob/master/latex/ge-jessie.Dockerfile
WORKDIR /home/workdir
# Not sure what this does since we run container with -v $PWD:/home/workdir anyways
VOLUME ["/home/workdir"]
