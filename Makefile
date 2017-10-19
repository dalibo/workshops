ECHO=$(info Compiling $^ into $@)

#
# Folders
#
IN=`basename $^`
OUT=`basename $@`
DIR=`dirname $^`


#
# Dalibo's themes are not open source
# but they're optionnal
#
LOCAL_DLB=$(HOME)/.dalibo/themes/
DLB=$(LOCAL_DLB)

#
# Pandoc
#

P=pandoc --metadata=dlb:$(DLB)

# if pandoc is not installed, let's use pandocker
ifeq (, $(shell which $P))
	DOCKER_TAG=latest
endif

ifneq ($(DOCKER),)
	DOCKER_TAG=$(DOCKER)
endif

ifneq ($(DOCKER_TAG),)
	DOCKER_DLB=/root/dalibo/themes
	P=docker run -it --volume `pwd`:/pandoc --volume $(LOCAL_DLB):$(DOCKER_DLB) dalibo/pandocker:$(DOCKER_TAG) --metadata=dlb:$(DOCKER_DLB)
	DLB=$(DOCKER_DLB)
endif

#
# Flags
#
ifeq ("$(wildcard $(LOCAL_DLB))","")
 # Default Compilation Flags

 #  self-contained mode is currently buggy with the official revealjs css file
 #  REVEAL_FLAGS=-t revealjs --self-contained --standalone -V revealjs-url:http://lab.hakim.se/reveal-js/
 REVEAL_FLAGS=-t revealjs --standalone -V revealjs-url:http://lab.hakim.se/reveal-js/
 TEX_FLAGS= -st beamer 
 BEAMER_FLAGS= -st beamer 
 PDF_FLAGS=--latex-engine=xelatex
 ODT_FLAGS=
 DOC_FLAGS=
 EPUB_FLAGS=
else
 # Dalibo's Compilation Flags
 REVEAL_FLAGS=-t revealjs --template="$(DLB)/reveal.js/pandoc/templates/dalibo.revealjs" --self-contained --standalone -V revealjs-url="$(DLB)/reveal.js/"
 TEX_FLAGS= -st beamer -V theme=Dalibo
 BEAMER_FLAGS= -st beamer -V theme=Dalibo
 PDF_FLAGS=--latex-engine=xelatex --template=$(DLB)/tex/book1/template.tex
 ODT_FLAGS=--reference-odt=$(DLB)/odt/template_conference.dokuwiki.odt
 DOC_FLAGS=--reference-doc=$(DLB)/doc/template_conference.dokuwiki.doc
 EPUB_FLAGS=
endif

SRCS=$(shell find . -name '*.md' -and -not -name 'README.md' -and -not -path './themes/*')

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

