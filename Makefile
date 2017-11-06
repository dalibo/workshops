###############################################################################
#
# How To Use this Makefile
#------------------------------------------------------------------------------
# Let's say you have a markdown source file named foo.md in the 'fr' directory
#
#  - `make fr/foo.pdf` will build a PDF from fr/foo.md
#  - `make fr/foo.epub` will build an EPUB from fr/foo.md
#  - `make all` will build all source files in all formats
#  - `make clean` will remove all build artifacts
#
# Pandoc or docker ?
#------------------------------------------------------------------------------
#  
#  - by default, we use pandoc to compile documents
#  - if pandoc is not install, we use a docker image instead
#  - use `DOCKER=latest make all` to force make to use docker 
#
#
# Dalibo Themes or not ?
#-------------------------------------------------------------------------------
#
#   - dalibo themes are not open source but they're optionnal
#   - you can compile the docs without them
#   - use `LOCAL_DLB=/tmp/dalibo make all` to change the dalibo themes location
#
#
###############################################################################


ECHO=$(info Compiling $^ into $@)

#
# Folders
#
IN=`basename $^`
OUT=`basename $@`
DIR=`dirname $^`


#
# LOCAL_DLB is a directory containing dalibo themes
# by default it's ~/.dalibo/themes/
#
# dalibo themes are not open source but they're optionnal
# you can compile the docs without them
#
ifeq ($(LOCAL_DLB),)
LOCAL_DLB=$(HOME)/.dalibo/themes/
endif

# Normally DLB == LOCAL_DLB, but this will change when we'll use docker
DLB=$(LOCAL_DLB)

#
# Pandoc binary
#

P=pandoc --metadata=dlb:$(DLB)

#
# If pandoc is not installed, 
# Then let's use the docker image by setting DOCKER_TAG
#
ifeq (, $(shell which $P))
	DOCKER_TAG=latest
endif

# If make was launched with DOCKER=latest 
# Then we force usage of docker by setting DOCKER_TAG
ifneq ($(DOCKER),)
	DOCKER_TAG=$(DOCKER)
endif

# If DOCKER_TAG is defined
# Then we replace $P with a docker call
ifneq ($(DOCKER_TAG),)
	DOCKER_DLB=/root/dalibo/themes
	P=docker run --rm -it --volume `pwd`:/pandoc --volume $(LOCAL_DLB):$(DOCKER_DLB) dalibo/pandocker:$(DOCKER_TAG) --metadata=dlb:$(DOCKER_DLB)
	DLB=$(DOCKER_DLB)
endif

#
# Pandoc Compilation Flags
#
ifeq ("$(wildcard $(LOCAL_DLB))","")
 #####
 # dalibo themes are not available
 # Let's use default compilation flags
 ####

 #  self-contained mode is currently buggy with the official revealjs css file
 #  REVEAL_FLAGS=-t revealjs --self-contained --standalone -V revealjs-url:http://lab.hakim.se/reveal-js/
 REVEAL_FLAGS=-t revealjs --standalone -V revealjs-url:http://lab.hakim.se/reveal-js/
 TEX_FLAGS= -st beamer 
 BEAMER_FLAGS= -st beamer 
 PDF_FLAGS=--latex-engine=xelatex --no-tex-ligatures
 ODT_FLAGS=
 DOC_FLAGS=
 EPUB_FLAGS=
else
 ####
 # Dalibo's Compilation Flags
 ####
 REVEAL_FLAGS=-t revealjs --template="$(DLB)/reveal.js/pandoc/templates/dalibo.revealjs" --self-contained --standalone -V revealjs-url="$(DLB)/reveal.js/"
 TEX_FLAGS= -st beamer -V theme=Dalibo
 BEAMER_FLAGS= -st beamer -V theme=Dalibo
 PDF_FLAGS=--latex-engine=xelatex --template=$(DLB)/tex/book1/template.tex --no-tex-ligatures --filter pandoc-latex-admonition
 ODT_FLAGS=--reference-odt=$(DLB)/odt/template_conference.dokuwiki.odt
 DOC_FLAGS=--reference-doc=$(DLB)/doc/template_conference.dokuwiki.doc
 EPUB_FLAGS=
endif

#
# SRCS is the list of all the source markdown files
# README files and other documentation markdown files are not compiled
#
EXCLUDE_FILES=\./\(LICENSE\|QUICKSTART\|CONTRIBUTING\|SYNTAX\|INSTALL\|AUTHORS\)\.md
SRCS=$(shell find . -name '*.md' -and -not -name README.md -and -not -regex '$(EXCLUDE_FILES)' -and -not -path './themes/*')

REVEAL_OBJS=$(SRCS:.md=.html)
TEX_OBJS=$(SRCS:.md=.tex)
BEAMER_OBJS=$(SRCS:.md=.beamer.pdf)
PDF_OBJS=$(SRCS:.md=.pdf)
ODT_OBJS=$(SRCS:.md=.odt)
DOC_OBJS=$(SRCS:.md=.doc)
EPUB_OBJS=$(SRCS:.md=.epub)

_PHONY: all

test:
	echo $(DLB)
	echo $(REVEAL_FLAGS)

install:
	ln -s $(HOME)/.dalibo/themes/ 

uninstall:
	rm themes

#
# Supported formats
#
#all: reveal tex beamer pdf odt doc epub
all: reveal pdf epub doc

reveal: $(REVEAL_OBJS)
tex: $(TEX_OBJS)
beamer: $(BEAMER_OBJS)
pdf: $(PDF_OBJS)
odt: $(ODT_OBJS)
doc: $(DOC_OBJS)
epub: $(EPUB_OBJS)


%.all:  %.html %.tex %.beamer.pdf %.pdf %.odt %.doc %.epub
	$(ECHO)

%.html: %.md
	$(ECHO)
	cd $(DIR) && $P $(REVEAL_FLAGS) $(IN) -o $(OUT)

%.tex: %.md
	$(ECHO)
	cd $(DIR) && $P $(TEX_FLAGS) $(IN) -o $(OUT)

%.beamer.pdf: %.md
	$(ECHO)
	TEXMFHOME=$(DLB)/beamer	cd $(DIR) && $P $(BEAMER_FLAGS) $(IN) -o $(OUT)

%.pdf: %.md
	$(ECHO)	
	cd $(DIR) && $P $(PDF_FLAGS) $(IN) -o $(OUT)


%.peecho.pdf: %.pdf
	$(ECHO)
	cd $(DIR) && $(LOCAL_DLB)/tex/book1/postprod.peecho.py -b $(LOCAL_DLB)/_build/tex/book1/backcover.pdf -n $(LOCAL_DLB)/_build/tex/book1/note.pdf -p $(LOCAL_DLB)/_build/tex/book1/publications.pdf $(IN) -o $(OUT) 

%.odt: %.md
	$(ECHO)
	cd $(DIR) && $P $(ODT_FLAGS) $(IN) -o  $(OUT)


%.doc: %.md
	$(ECHO)
	cd $(DIR) && $P $(DOC_FLAGS) $(IN) -o  $(OUT)


%.epub: %.md
	$(ECHO)
	cd $(DIR) && $P $(EPUB_FLAGS) $(IN) -o  $(OUT)

clean:
	rm -fr $(REVEAL_OBJS)
	rm -fr $(TEX_OBJS)
	rm -fr $(BEAMER_OBJS)
	rm -fr $(PDF_OBJS)
	rm -fr $(ODT_OBJS)
	rm -fr $(DOC_OBJS)
	rm -fr $(EPUB_OBJS)

