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

# Files grouped by installation location
RUNFILES = $(UNPACKED_EXTRA) $(UNPACKED_TEXTRA) luamcallbacks.lua
DOCFILES = $(DOC_DTX) $(DOC_TEX) README luamcallbacks-test.tex
SRCFILES = $(DTX) $(SRC_TEX) Makefile

ALL_FILES = $(RUNFILES) $(DOCFILES) $(SRCFILES)

# Installation locations
FORMAT = luatex
RUNDIR = tex/$(FORMAT)/$(NAME)
DOCDIR = doc/$(FORMAT)/$(NAME)
SRCDIR = source/$(FORMAT)/$(NAME)
ALL_DIRS = $(RUNDIR) $(DOCDIR) $(SRCDIR)

FLAT_ZIP = $(NAME).zip
TDS_ZIP = $(NAME).tds.zip
CTAN = $(FLAT_ZIP) $(TDS_ZIP)

DO_TEX = tex --interaction=batchmode $< >/dev/null
DO_PDFLATEX = pdflatex --interaction=batchmode $< >/dev/null
DO_PDFLUALATEX = pdflualatex --interaction=batchmode $< >/dev/null
DO_MAKEINDEX = makeindex -s gind.ist $(subst .dtx,,$<) >/dev/null 2>&1

all: unpack doc
world: all ctan
ctan: $(CTAN)
doc: $(COMPILED)
unpack: $(UNPACKED)

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

$(FLAT_ZIP): $(ALL_FILES)
	@echo "Making $@ for normal CTAN distribution."
	@$(RM) -- $@
	@zip -9 $@ $(ALL_FILES) >/dev/null

$(TDS_ZIP): $(ALL_FILES)
	@echo "Making $@ for TDS-ready CTAN distribution."
	@$(RM) -- $@
	@mkdir -p $(ALL_DIRS)
	@cp $(RUNFILES) $(RUNDIR)
	@cp $(DOCFILES) $(DOCDIR)
	@cp $(SRCFILES) $(SRCDIR)
	@zip -9 $@ -r $(ALL_DIRS) >/dev/null
	@$(RM) -r tex doc source

clean: 
	@$(RM) -- *.log *.aux *.toc *.idx *.ind *.ilg *.out

mrproper: clean
	@$(RM) -- $(GENERATED) $(CTAN)

.PHONY: clean mrproper
