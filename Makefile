# Makefile for luatextra.

NAME = luatextra
DTX = $(wildcard *.dtx)
DOC_DTX = $(patsubst %.dtx, %.pdf, $(DTX))
SRC_TEX = luatextra-reference.tex
DOC_TEX = $(patsubst %.tex, %.pdf, $(SRC_TEX))

# Files grouped by generation mode
UNPACKED_EXTRA = luaextra.lua 
UNPACKED_MCB = luamcallbacks-test.tex luamcallbacks.lua
UNPACKED_TEXTRA = luatextra-latex.tex luatextra.lua luatextra.sty 
UNPACKED = $(UNPACKED_EXTRA) $(UNPACKED_MCB) $(UNPACKED_TEXTRA)
COMPILED = $(DOC_DTX) $(DOC_TEX) 
GENERATED = $(UNPACKED) $(COMPILED)
SOURCE = $(DTX) $(SRC_TEX) README Makefile

# Files grouped by installation location
RUNFILES = $(UNPACKED_EXTRA) $(UNPACKED_TEXTRA) luamcallbacks.lua
DOCFILES = $(DOC_DTX) $(DOC_TEX) README luamcallbacks-test.tex
SRCFILES = $(DTX) $(SRC_TEX) Makefile

# The following definitions should be equivalent
# ALL_FILES = $(RUNFILES) $(DOCFILES) $(SRCFILES)
ALL_FILES = $(GENERATED) $(SOURCE)

# Installation locations
FORMAT = luatex
RUNDIR = $(TEXMFROOT)/tex/$(FORMAT)/$(NAME)
DOCDIR = $(TEXMFROOT)/doc/$(FORMAT)/$(NAME)
SRCDIR = $(TEXMFROOT)/source/$(FORMAT)/$(NAME)
TEXMFROOT = ./texmf

CTAN_ZIP = $(NAME).zip
TDS_ZIP = $(NAME).tds.zip
ZIPS = $(CTAN_ZIP) $(TDS_ZIP)

DO_TEX = tex --interaction=batchmode $< >/dev/null
DO_PDFLATEX = pdflatex --interaction=batchmode $< >/dev/null
DO_PDFLUALATEX = pdflualatex --interaction=batchmode $< >/dev/null
DO_MAKEINDEX = makeindex -s gind.ist $(subst .dtx,,$<) >/dev/null 2>&1

all: $(GENERATED)
doc: $(COMPILED)
unpack: $(UNPACKED)
ctan: $(CTAN_ZIP)
tds: $(TDS_ZIP)
world: all ctan

%.pdf: %.dtx
	$(DO_PDFLATEX)
	$(DO_MAKEINDEX)
	$(DO_PDFLATEX)
	$(DO_PDFLATEX)

$(DOC_TEX): $(SRC_TEX)
	$(DO_PDFLUALATEX)
	$(DO_PDFLUALATEX)
	$(DO_PDFLUALATEX)

$(UNPACKED_TEXTRA): luatextra.dtx
	$(DO_TEX)

$(UNPACKED_EXTRA): luaextra.dtx
	$(DO_TEX)

$(UNPACKED_MCB): luamcallbacks.dtx
	$(DO_TEX)

$(CTAN_ZIP): $(SOURCE) $(COMPILED) $(TDS_ZIP)
	@echo "Making $@ for CTAN upload."
	@$(RM) -- $@
	@zip -9 $@ $^ >/dev/null

define run-install
@mkdir -p $(RUNDIR) && cp $(RUNFILES) $(RUNDIR)
@mkdir -p $(DOCDIR) && cp $(DOCFILES) $(DOCDIR)
@mkdir -p $(SRCDIR) && cp $(SRCFILES) $(SRCDIR)
endef

$(TDS_ZIP): TEXMFROOT=./tmp-texmf
$(TDS_ZIP): $(ALL_FILES)
	@echo "Making TDS-ready archive $@."
	@$(RM) -- $@
	$(run-install)
	@cd $(TEXMFROOT) && zip -9 ../$@ -r . >/dev/null
	@$(RM) -r -- $(TEXMFROOT)

.PHONY: install manifest clean mrproper

install: $(ALL_FILES)
	@echo "Installing in '$(TEXMFROOT)'."
	$(run-install)

manifest: 
	@echo "Source files:"
	@for f in $(SOURCE); do echo $$f; done
	@echo ""
	@echo "Derived files:"
	@for f in $(GENERATED); do echo $$f; done

clean: 
	@$(RM) -- *.log *.aux *.toc *.idx *.ind *.ilg

mrproper: clean
	@$(RM) -- $(GENERATED) $(ZIPS)

