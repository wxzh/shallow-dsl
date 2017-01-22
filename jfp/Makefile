#-----------------------------------------------------------------------------
# programs

-include local.mk

LHS2TEX  := lhs2TeX
PDFLATEX := pdflatex
LATEX    := latex
BIBTEX   := bibtex

#-----------------------------------------------------------------------------
# directories and files

file		:= Main
main		:= main
objects	:= Main.o

#-----------------------------------------------------------------------------
# commands

ghc		:= ghc
ghcflags	:= -Wall -O

flags           := --poly
ifndef PDFTEX
ifndef DVIPS
flags		:= --poly -s dvipdfm
endif
endif

spell           := ispell -d british -t -l -p

#-----------------------------------------------------------------------------

ifdef DVIPS
default : postscript
else
default : pdf
endif

postscript : $(file).ps
pdf : $(file).pdf

#-----------------------------------------------------------------------------
# static pattern rules

$(objects) : %.o : %.lhs
	$(ghc) -c $(ghcflags) $< -o $@

#-----------------------------------------------------------------------------
# pattern rules

%-TR.tex : %.lhs force
	$(LHS2TEX) $(flags) -s tr $< > $@ || rm -f $@

%-ABS.tex : %.lhs force
	$(LHS2TEX) $(flags) -s abs $< > $@ || rm -f $@

$(file).tex : %.tex : %.lhs force build
	$(LHS2TEX) $(flags) $< > $@ || rm -f $@

%.ps : %.dvi
	dvips -o $@ $<

ifndef PDFTEX

#%.pdf : %.dvi
#	dvipdfm $<

%.pdf : %.ps
	ps2pdf $<

endif

%.hi : %.o
	@:

#-----------------------------------------------------------------------------
# rules

.PHONY 	: edit xdvi gv acro print spell spellupdate links clean realclean force
.SUFFIXES :

edit :
	xemacs $(file).fmt $(file).lhs &

ifdef PDFTEX

%.pdf : %.tex force
	$(PDFLATEX) $(<)
	if grep -s '^LaTeX Warning: Citation .* undefined' $(<:.tex=.log); \
	then $(BIBTEX) $(<:.tex=); $(PDFLATEX) $(<); \
	fi
	while grep -s "Warning.*Rerun" $(<:.tex=.log); \
	  do $(PDFLATEX) $<; done;

else

%.dvi : %.tex force
	$(LATEX) $(<)
	if grep -s '^LaTeX Warning: Citation .* undefined' $(<:.tex=.log); \
	then $(BIBTEX) $(<:.tex=); $(LATEX) $(<); \
	fi
	while grep -s "Warning.*Rerun" $(<:.tex=.log); \
	  do $(LATEX) $<; done;

endif

build :
	cd paper && ./build.sh && cd ..

ghci : $(file).lhs
	ghci -v0 -pgmL $(LHS2TEX) -optL--pre $(file).lhs

xdvi : $(file).dvi
	xdvi -s 6 $(file).dvi &

gv : $(file).ps
	gv -spartan $(file).ps &

acro : $(file).pdf
	/opt/Acrobat7/acroread $(file).pdf &

print	: $(file).ps
	uulpr $(file).ps

spell: $(file).tex
	egrep -v '$\%' $(file).tex | $(spell) $(file).spell | sort | uniq

spellupdate: $(file).tex
	egrep -v '$\%' $(file).tex | $(spell)  $(file).spell | sort | uniq > $(file).spell

$(main) : $(objects)
	$(ghc) $(ghcflags) -o $(main) $(objects)

links:
	ln -s $(HOME)/local/abbr.bib
	ln -s $(HOME)/local/rh.bib
	ln -s $(HOME)/local/lhs2TeX.fmt
	ln -s $(HOME)/local/lhs2TeX.sty
	ln -s $(HOME)/local/FuncMP.mp

clean	:
	rm -f *~ *% *.aux *.bbl *.blg *.log *.toc *.out
	rm -f main $(file).tex $(file).[1-9]* *.mpx

realclean : clean
	rm -f *.dvi *.ps *.pdf
	rm -f abbr.bib rh.bib lhs2TeX.fmt lhs2TeX.sty FuncMP.mp
