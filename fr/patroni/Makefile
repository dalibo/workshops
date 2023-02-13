#
# Chemin vers les thèmes Dalibo. DLB est le chemin pour la command pandoc,
# HOST_DLB est le chemin pour le Makefile.
#
DLB?=$(HOME)/.dalibo/themes/
HOST_DLB:=$(DLB)

#
# Pandoc
#
P=pandoc

# if pandoc is not installed, let's use pandocker
ifeq (, $(shell which $(P)))
	DOCKER?=latest
endif

ifneq ($(DOCKER),)
	DLB=/root/dalibo/themes
	P:=docker run --rm -it --privileged -e TEXMFHOME --volume $(CURDIR):/pandoc --volume $(HOST_DLB):$(DLB) dalibo/pandocker:$(DOCKER)
endif

PANDOC_ARGS=--standalone
P+=--metadata=dlb:$(DLB) $(PANDOC_ARGS)


#
# Pandoc Flags
#
ifeq ("$(wildcard $(HOST_DLB))","")
 # Default Compilation Flags
 REVEAL_FLAGS=-V revealjs-url:http://lab.hakim.se/reveal-js/css/reveal.css/css/reveal.css
 TEX_FLAGS=
 BEAMER_FLAGS=
 PDF_FLAGS=
 ODT_FLAGS=
 DOCX_FLAGS=
 EPUB_FLAGS=
else
 # Dalibo's Compilation Flags
 REVEAL_LOCAL_FLAGS=-V revealjs-url="$(HOST_DLB)/reveal.js/" --template="$(DLB)/reveal.js/pandoc/templates/dalibo.revealjs"
 REVEAL_FLAGS=-V revealjs-url="$(DLB)/reveal.js/" --template="$(DLB)/reveal.js/pandoc/templates/dalibo.revealjs" --self-contained
 TEX_FLAGS=-V theme=Dalibo
	export TEXMFHOME=$(DLB)/beamer
 BEAMER_FLAGS=-V theme=Dalibo
ifneq (,$(wildcard $(HOST_DLB)/beamer/template.latex))
 BEAMER_FLAGS:=$(BEAMER_FLAGS) --template $(DLB)/beamer/template.latex
endif
ifneq (,$(wildcard $(HOST_DLB)/highlight/dalibo-dark.theme))
 $(info Utilisation du style Dalibo pour la coloration syntaxique)
 BEAMER_FLAGS:=$(BEAMER_FLAGS) --highlight-style=$(DLB)/highlight/dalibo-dark.theme
 REVEAL_FLAGS:=$(REVEAL_FLAGS) --highlight-style=$(DLB)/highlight/dalibo-dark.theme
 REVEAL_LOCAL_FLAGS:=$(REVEAL_LOCAL_FLAGS) --highlight-style=$(DLB)/highlight/dalibo-dark.theme
endif
 PDF_FLAGS=--template=$(DLB)/tex/audit/template.tex --pdf-engine-opt=-shell-escape
 ODT_FLAGS=--reference-doc=$(DLB)/odt/template_conference.dokuwiki.odt
 DOCX_FLAGS=--reference-doc=$(DLB)/doc/template_conference.dokuwiki.doc
 EPUB_FLAGS=
endif

##
## DECKTAPE
##
DECKTAPE?=docker run --rm -it --privileged -v $(CURDIR):/slides astefanutti/decktape

##
## $(SRCS) is the list of all source files
##

# Ignore documentation
EXCLUDES:= -and -not -name 'QUICKSTART.md' -and -not -name 'README.md'
# Ignore themes directories
EXCLUDES+= -and -not -path './themes/*' -and -not -path '*/reveal.js/*'
# Ignore directories and files that starts with a '_'
EXCLUDES+= -and -not -path '*/_*'

# Search for all .md files
SRCS=$(shell find . -type f -name '*.md' $(EXCLUDES) )

##
## Objects files
##
REVEAL_OBJS=$(SRCS:.md=.html)
REVEAL_LOCAL_OBJS=$(SRCS:.md=.local.html)
REVEAL_PDF_OBJS=$(SRCS:.md=.reveal.pdf)
TEX_OBJS=$(SRCS:.md=.tex)
BEAMER_OBJS=$(SRCS:.md=.beamer.pdf)
BEAMER_NOTES_OBJS=$(SRCS:.md=.beamer.speaker.pdf)
PDF_OBJS=$(SRCS:.md=.pdf)
ODT_OBJS=$(SRCS:.md=.odt)
DOCX_OBJS=$(SRCS:.md=.docx)
EPUB_OBJS=$(SRCS:.md=.epub)


test:
	@echo Présentations: $(SRCS)
	@echo Thèmes dalibo: $(DLB)
	@echo Commande pandoc: $(P)
	@echo Options reveal: echo $(REVEAL_FLAGS)

install:
	ln -s $(HOME)/.dalibo/themes/

uninstall:
	rm themes

all: reveal reveal_local pdf epub odt

reveal: $(REVEAL_OBJS)
reveal_local: $(REVEAL_LOCAL_OBJS)
tex: $(TEX_OBJS)
beamer: $(BEAMER_OBJS)
beamer_notes: $(BEAMER_NOTES_OBJS)
pdf: $(PDF_OBJS)
odt: $(ODT_OBJS)
docx: $(DOCX_OBJS)
epub: $(EPUB_OBJS)
reveal_pdf: $(REVEAL_PDF_OBJS)


%.all:  %.html %.pdf %.odt %.epub

%.local.html: %.md
	$P -t revealjs $(REVEAL_LOCAL_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.html: %.md
	$P -t revealjs $(REVEAL_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.tex: %.md
	$P -t beamer $(TEX_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.beamer.pdf: %.md
	TEXMFHOME=$(DLB)/beamer $P -t beamer -V classoption=14pt -V classoption="aspectratio=169" $(BEAMER_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.beamer.notes.pdf: %.md
	$P -t beamer -V classoption=14pt -V "beameroption=show notes on second screen" $(BEAMER_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.pdf: %.md
	$P --pdf-engine=xelatex $(PDF_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.odt: %.md
	$P $(ODT_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.docx: %.md
	$P $(DOCX_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.epub: %.md
	$P $(EPUB_FLAGS) --resource-path=.:$(dir $^) $^ -o $@

%.reveal.pdf: %.html
	$(DECKTAPE) --size 1920x1080 $^ $@

# Utiliser make watch-reveal_local pour regénérer les reveal.html à chaque
# changement des md.
watch-%:
	echo $(SRCS) | entr -c make $*

clean:
	rm -fr $(REVEAL_OBJS)
	rm -fr $(REVEAL_LOCAL_OBJS)
	find . -name reveal.js | xargs -r rm -fr
	rm -fr $(TEX_OBJS)
	rm -fr $(BEAMER_OBJS)
	rm -fr $(BEAMER_NOTES_OBJS)
	rm -fr $(PDF_OBJS)
	rm -fr $(ODT_OBJS)
	rm -fr $(DOCX_OBJS)
	rm -fr $(EPUB_OBJS)
