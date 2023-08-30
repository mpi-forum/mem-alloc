ALL: all-redirect

# Makefile for MPI-Report...
# by Rainer Keller @ HLRS
# Updated by William Gropp @ UIUC
#
# WARNING: This makefile uses GNU extensions to the make language and
# extensions to grep
#
# Use
#   make           to produce version based on the interpreter (ps or pdf)
#   make book      to produce a two-page version
#   make aspell    to produce aspell checking
#   make clean     to get rid of studienarbeit.[abdl]* files
#   make veryclean to get rid of everything which can be reproduced
#   make distclean to get rid of the final files as well.
#   make allversions to create both official and review copies
# 
# The MPI-2.1 (June 23, 2008) standard was produced with the following commands:
# - With \def\mpimergecolor#1{\color{#1}}  in mpi-macs.tex  (lines 41-42) 
#   and colored links in mpi-report.tex (lines 50-57 and 81-88)
#   - with LATEX=pdflatex (see below) in this Makefile (lines 122-123)
#      make 
#      make     (only to be 150% sure that all necessary latex runs are really done)
#   - with LATEX=latex (see below) in this Makefile (lines 122-123)
#      make 
#      make
#   - saving the files:  
#      cp -p mpi-report.pdf                mpi-report-2.1-2008-06-23-reviewcolors.pdf
#      cp -p mpi-report.ps                 mpi-report-2.1-2008-06-23-reviewcolors.ps
#      touch                               mpi-report-2.1-2008-06-23-reviewcolors.pdf 
# 
# - With \def\mpimergecolor#1{\color{black}}  in mpi-macs.tex  (lines 41-42) 
#   and colored links in mpi-report.tex (lines 50-57 and 81-88)
#   - make same executions with LATEX=... (as above)
#   - saving the files:  
#      cp -p mpi-report.pdf                mpi-report-2.1-2008-06-23.pdf
#      cp -p mpi-report.ps                 mpi-report-2.1-2008-06-23.ps
#      touch                               mpi-report-2.1-2008-06-23.pdf 
# 
# - With \def\mpimergecolor#1{\color{black}}  in mpi-macs.tex  (lines 41-42) 
#   and **black** links in mpi-report.tex (lines 50-57 and 81-88)
#   - make same executions with LATEX=... (as above)
#   - saving the files:  
#      cp -p mpi-report.pdf                mpi-report-2.1-2008-06-23-black.pdf
#      cp -p mpi-report.ps                 mpi-report-2.1-2008-06-23-black.ps
#      touch                               mpi-report-2.1-2008-06-23-black.pdf 
#
# - Write on publication html pages, that the other print format 
#   can be achieved by:
#   - $(MAIN).ps is the name of one of the .ps files mentioned above. 
#   - "small" version, i.e., two consecutive A5-pages per A4-sheet 
#        pstops "2:0L@.7(21cm,0)+1L@.7(21cm,14.85cm)" $(MAIN).ps $(MAIN)-small.ps
#        epstopdf --outfile=$(MAIN)-small.pdf $(MAIN)-small.ps
#   - "twice" version, i.e., two identical A5-pages per A4-sheet 
#     ps-file is prepared for duplex printing via long edge, pdf-file via short edge.
#     After printing, the A4 pile must be cut in the middle to get the two A5 books.  
#        pstops '2:0R@.707(0,14.8cm)+0R@.707(0,29.6cm),1L@.707(21cm,0)+1L@.707(21cm,14.8cm)' $(MAIN).ps $(MAIN)-twice.ps 
#        epstopdf --outfile=$(MAIN)-twice.pdf $(MAIN)-twice.ps
#   - "split-book-A5" version, i.e., the MPI-2.1 standard is split into two parts (I and II).
#     Each part has frontmatter pages i-xvi at the beginning and all index pages at the end.
#     Each part has same official title page and may be bound in different colors,
#     e.g., Part I in light yellow and Part II in orange.   
#     Both parts are printed as left an right part of the A4 pile. 
#     After printing, the A4 pile must be cut in the middle to get Part I and Part II as
#     A5 books. The Part II book (A5) has several empty sheets at the end, which should be removed.
#     ps-file is prepared for duplex printing via long edge, pdf-file via short edge.
#        \rm -f $(MAIN)-split.ps $(MAIN)-split-book.ps 
#        psselect -p1-308 -p593-608 -p1-16 -p309-608  -p4 -p4 -p4 -p4 -p4 -p4 -p4 -p4 $(MAIN).ps $(MAIN)-split.ps
#        psbook -s648 $(MAIN)-split.ps $(MAIN)-split-book.ps
#        pstops '4:0R@.707(0,14.8cm)+1R@.707(0,29.6cm),3L@.707(21cm,0)+2L@.707(21cm,14.8cm)' $(MAIN)-split-book.ps $(MAIN)-split-book-A5.ps
#        \rm -f $(MAIN)-split.ps $(MAIN)-split-book.ps 
#        epstopdf --outfile=$(MAIN)-split-book-A5.pdf $(MAIN)-split-book-A5.ps
#   - "-twice-part1 and twice-part2" version,
#     i.e., the MPI-2.1 standard is split into two parts (I and II),
#     and each part is printed twice. 
#     ps-file is prepared for duplex printing via long edge, pdf-file via short edge.
#        \rm -f $(MAIN)-part1.ps $(MAIN)-part2.ps 
#        psselect -p1-308 -p593-608 $(MAIN).ps $(MAIN)-part1.ps
#        psselect -p1-16  -p309-608 $(MAIN).ps $(MAIN)-part2.ps
#        pstops '2:0R@.707(0,14.8cm)+0R@.707(0,29.6cm),1L@.707(21cm,0)+1L@.707(21cm,14.8cm)' $(MAIN)-part1.ps $(MAIN)-twice-part1.ps 
#        pstops '2:0R@.707(0,14.8cm)+0R@.707(0,29.6cm),1L@.707(21cm,0)+1L@.707(21cm,14.8cm)' $(MAIN)-part2.ps $(MAIN)-twice-part2.ps 
#        \rm -f $(MAIN)-part1.ps $(MAIN)-part2.ps 
#        epstopdf --outfile=$(MAIN)-twice-part1.pdf $(MAIN)-twice-part1.ps
#        epstopdf --outfile=$(MAIN)-twice-part2.pdf $(MAIN)-twice-part2.ps
# 
# 
# 
# The MPI-2.1 (June 13, 2008) draft was produced with the following commands:
# - With \def\mpimergecolor#1{\color{#1}}  in mpi-macs.tex    
#   - with LATEX=pdflatex (see below) in this Makefile 
#      make 
#      make     (only to be 150% sure that all necessary latex runs are really done)
#   - with LATEX=latex (see below) in this Makefile 
#      make 
#      make book
#   - with LATEX=pdflatex (see below) in this Makefile 
#      make mpi-report-small.pdf
#      make mpi-report-twice.pdf
#      make mpi-report-split-book-A5.pdf
#   - saving the files:  
#      cp -p mpi-report.pdf                mpi-report-2.1draft-2008-06-13-colored.pdf
#      cp -p mpi-report.ps                 mpi-report-2.1draft-2008-06-13-colored.ps
#      cp -p mpi-report-small.pdf          mpi-report-2.1draft-2008-06-13-colored-small.pdf
#      cp -p mpi-report-small.ps           mpi-report-2.1draft-2008-06-13-colored-small.ps
#      cp -p mpi-report-twice.pdf          mpi-report-2.1draft-2008-06-13-colored-twice.pdf
#      cp -p mpi-report-twice.ps           mpi-report-2.1draft-2008-06-13-colored-twice.ps
#      cp -p mpi-report-split-book-A5.pdf  mpi-report-2.1draft-2008-06-13-colored-split-book-A5.pdf
#      cp -p mpi-report-split-book-A5.ps   mpi-report-2.1draft-2008-06-13-colored-split-book-A5.ps
#      touch                               mpi-report-2.1draft-2008-06-13-colored.pdf 
# 
# - With \def\mpimergecolor#1{\color{black}}  in mpi-macs.tex    
#   - same make executions with LATEX=... (as above)
#   - saving the files:  
#      cp -p mpi-report.pdf                mpi-report-2.1draft-2008-06-13.pdf
#      cp -p mpi-report.ps                 mpi-report-2.1draft-2008-06-13.ps
#      cp -p mpi-report-small.pdf          mpi-report-2.1draft-2008-06-13-small.pdf
#      cp -p mpi-report-small.ps           mpi-report-2.1draft-2008-06-13-small.ps
#      cp -p mpi-report-twice.pdf          mpi-report-2.1draft-2008-06-13-twice.pdf
#      cp -p mpi-report-twice.ps           mpi-report-2.1draft-2008-06-13-twice.ps
#      cp -p mpi-report-split-book-A5.pdf  mpi-report-2.1draft-2008-06-13-split-book-A5.pdf
#      cp -p mpi-report-split-book-A5.ps   mpi-report-2.1draft-2008-06-13-split-book-A5.ps
#      touch                               mpi-report-2.1draft-2008-06-13.pdf 
#
# Change the following accordingly:

MAIN=mpi-report
BIB_FILE=refs.bib
LATEX=pdflatex
#LATEX=latex
GNUPLOT_BIN=gnuplot
RM=rm -fr

TEX      := $(shell ls -1 chap-*/[a-zA-Z]*.tex  ./app*.tex $(MAIN).tex)
TEXNOAPPLANG := $(shell ls -1 chap-*/[a-zA-Z]*.tex $(MAIN).tex)
GNUPLOT  := $(shell find . -name '*.gnuplot' -print)
FIG      := $(shell find . -mindepth 1 -name '[a-zA-Z]*.fig' -print)
EPS      := $(shell find . -mindepth 1 -name '*.eps' -print)
PNG      := $(shell find . -mindepth 1 -name '*.png' -print)
PS       := $(shell find . -mindepth 1 -name '*.ps' -print)
PDFINFO  := $(shell which pdfinfo)

CONVERT_GNUPLOT_EPS=$(GNUPLOT:.gnuplot=.eps)
CONVERT_PNG_EPS=$(PNG:.png=.eps)
CONVERT_FIG_EPS=$(FIG:.fig=.eps)
CONVERT_FIG_EEPIC=$(FIG:.fig=.eepic)      # Currently unused in the dependancy

# Version number for the current version of the MPI standard
MPIVERSION=2.2
# MPIVERSIONSHORT is the version, with no non-digits
MPIVERSIONSHORT=22

ifeq ($(LATEX),pdflatex)
  # All EPS-files and generated EPS-files need to be converted to PDF
  EPS+=$(CONVERT_GNUPLOT_EPS)
  EPS+=$(CONVERT_PNG_EPS)

  CONVERT_FIG_PDF=$(FIG:.fig=.pdf)
  CONVERT_EPS_PDF=$(EPS:.eps=.pdf)
  CONVERT_PS_PDF=$(PS:.ps=.pdf)

  all: $(MAIN).pdf
else
  all: $(MAIN).ps
endif

all-redirect: all

# All output files generated by auxiliary programs such as bibtex or makeindex
# In case we use nomencl or glossary, we need $(MAIN).gls as well.
OBJ=$(MAIN).aux \
    $(MAIN).bbl \
    $(MAIN).ind

# REMOVE dependance on $(MAIN).ind?

# Remove any old toc - if there were problems in a previous run, they
# can contaminate the toc file
$(MAIN).ps: graphics_ps appLang-CNames.tex func-index.tex $(TEX) $(OBJ)
	@echo "---- Running $(LATEX) $(MAIN).tex ---"
	rm -f $(MAIN).toc
	if [ ! -s $(MAIN).toc ] ; then 	$(LATEX) $(MAIN).tex ; fi
	$(LATEX) $(MAIN).tex
	@while ( grep -q 'Rerun to get' $(MAIN).log ) ; do \
          echo "---- Rerunning $(LATEX) $(MAIN).tex ---" ; \
          $(LATEX) $(MAIN).tex ; \
        done
	dvips $(MAIN).dvi -o $(MAIN)_tmp.ps
	mv $(MAIN)_tmp.ps $(MAIN).ps
	@echo "OVERALL: `grep '[[:digit:]]\+\ pages' $(MAIN).log | cut -f2- -d'(' | cut -f1 -d','`"

# Remove any old toc - if there were problems in a previous run, they
# can contaminate the toc file
$(MAIN).pdf: graphics_pdf appLang-CNames.tex func-index.tex $(TEX) $(OBJ)
	@echo "---- Running $(LATEX) $(MAIN).tex ---"
	rm -f $(MAIN).toc
	if [ ! -s $(MAIN).toc ] ; then 	$(LATEX) $(MAIN).tex ; fi
	$(LATEX) $(MAIN).tex
	@while ( grep -q 'Rerun to get' $(MAIN).log ) ; do \
          echo "---- Rerunning $(LATEX) $(MAIN).tex ---" ; \
	  $(LATEX) $(MAIN).tex ; \
        done
	if test -x "$(PDFINFO)" ; then \
	  pdfinfo $(MAIN).pdf ; \
	fi

graphics_ps: $(CONVERT_GNUPLOT_EPS) $(CONVERT_PNG_EPS) $(CONVERT_FIG_EPS)

graphics_pdf: $(CONVERT_GNUPLOT_EPS) $(CONVERT_PNG_EPS) $(CONVERT_FIG_PDF) $(CONVERT_EPS_PDF) $(CONVERT_PS_PDF)

#
# The original was incorrect - the index must be created after the 
# bibliography and after there is a correct aux file for cross references
func-index.tex: $(TEX) $(MAIN).bbl
	$(LATEX) $(MAIN).tex
	@while ( grep -q 'Rerun to get' $(MAIN).log ) ; do \
          echo "---- Rerunning $(LATEX) $(MAIN).tex ---" ; \
          $(LATEX) $(MAIN).tex ; \
        done
	./MAKE-FUNC-INDEX

appLang-CNames.tex: $(TEXNOAPPLANG)
	./MAKE-APPLANG
#       produces: appLang-CNames.tex appLang-CppNames.tex appLang-FNames.tex

gv view:
	@if test -f $(MAIN).pdf ; then \
	  FILE=$(MAIN).pdf ; \
	else \
	  FILE=$(MAIN).ps ; \
	fi ; \
	echo "---- Displaying $$FILE ---" ; \
	nice -n 19 gv -spartan -scale -2 $$FILE &

book: $(MAIN).ps
	pstops "2:0L@.7(21cm,0)+1L@.7(21cm,14.85cm)" $(MAIN).ps $(MAIN)-small.ps
	if [ -f ./duplexon.ps ] ; then \
	  cat duplexon.ps $(MAIN)-small.ps > $(MAIN)-small-duplex.ps ; \
	fi
	\rm -f $(MAIN)-split.ps $(MAIN)-split-book.ps 
	pstops '2:0R@.707(0,14.8cm)+0R@.707(0,29.6cm),1L@.707(21cm,0)+1L@.707(21cm,14.8cm)' $(MAIN).ps $(MAIN)-twice.ps 
	psselect -p1-308 -p593-608 -p1-16 -p309-608  -p4 -p4 -p4 -p4 -p4 -p4 -p4 -p4 $(MAIN).ps $(MAIN)-split.ps
	psbook -s648 $(MAIN)-split.ps $(MAIN)-split-book.ps
	pstops '4:0R@.707(0,14.8cm)+1R@.707(0,29.6cm),3L@.707(21cm,0)+2L@.707(21cm,14.8cm)' $(MAIN)-split-book.ps $(MAIN)-split-book-A5.ps
	\rm -f $(MAIN)-split.ps $(MAIN)-split-book.ps 
 


#
# Use makeindex to create the index and nomenclature.
# For the index, specify our own style-file, to insert our \acselfdefined command in order to
# output the selfdefined acronyms, so that they don't get reprinted, like Pthread (Pthread).
#
$(MAIN).ind: $(TEX)
	@if test -f $(MAIN).idx ; then \
	  if test -f $(MAIN).ist ; then \
	    makeindex -s $(MAIN).ist $(MAIN) ; \
	  else \
	    makeindex $(MAIN) ; \
	  fi \
	else \
	  touch $(MAIN).ind ; \
	fi


# $(MAIN).gls: $(TEX)
# 	makeindex $(MAIN).glo -s nomencl.ist -o $(MAIN).gls

$(MAIN).aux: $(TEX)
	@echo "---- Running $(LATEX) $(MAIN).tex to get $(MAIN).aux-file ---"
	$(LATEX) $(MAIN).tex

#
# If we use chapterbib, we should run bibtex on each of the .aux-files
#
$(MAIN).bbl: $(BIB_FILE) $(TEX) $(MAIN).aux
	# @for i in *.aux ; do bibtex `basename $$i .tex` ; done
	bibtex $(MAIN)

#
# Converting GNUplot files to EPS may generate output on stderr when using fit.
# This also generates a file *.fitlog which needs to be deleted upon distclean
#
$(CONVERT_GNUPLOT_EPS):
	$(shell cd `dirname $@` ; $(GNUPLOT_BIN) `basename $@ .eps`.gnuplot > /dev/null 2>&1 )

$(CONVERT_PNG_EPS):
	$(shell cd `dirname $@` ; convert `basename $@ .eps`.png `basename $@` )

%.eps: %.fig
	fig2dev -L eps $< $@

%.eepic: %.fig
	fig2dev -L eepic $< $@

%.pdf: %.fig
	fig2dev -L pdftex -p 1 $< $@

%.pdf: %.eps
	epstopdf --outfile=$@ $<

%.pdf: %.ps
	epstopdf --outfile=$@ $<

aspell:
	aspell --encoding=iso-8859-1 --mode=tex --lang=de -c *.tex

clean:
	$(RM) $(shell find . -name '*.aux' -print)
	$(RM) $(MAIN).aux $(MAIN).bbl $(MAIN).blg $(MAIN).brf $(MAIN).dvi $(MAIN).glo $(MAIN).gls $(MAIN).idx $(MAIN).idx.save $(MAIN).ilg $(MAIN).ind $(MAIN).lof $(MAIN).log $(MAIN).lot $(MAIN).out $(MAIN).toc tmp.txt
	find . \( -not -type d \) -and \
	  \( -name 'ex.out' -o -name 'ex[0-9]*.[ocCf]' -o -name 'ex[0-9]*.f90' \) -print | xargs $(RM)

veryclean: clean
	find . \( -not -type d \) -and \
	  \( -name '*~' -o -name '*.aux' -o -name '*.bak' -o -name '#*#' -o -name '*.fitlog' -o -name 'ex.out' -o -name 'ex[0-9]*.[ocCf]' -o -name 'ex[0-9]*.f90' \) -print | xargs $(RM)
	$(RM) $(CONVERT_GNUPLOT_EPS) $(CONVERT_PNG_EPS) $(CONVERT_FIG_EPS) $(CONVERT_FIG_EEPIC) $(CONVERT_FIG_PDF) $(CONVERT_EPS_PDF) $(CONVERT_PS_PDF)

distclean maintainer-clean: veryclean
	$(RM) $(MAIN).pdf $(MAIN).pdf.gz $(MAIN).pdf.bz2 $(MAIN).ps $(MAIN)_tmp.ps $(MAIN).ps.gz $(MAIN).ps.bz2 $(MAIN)-small.ps $(MAIN)-small-duplex.ps $(MAIN)-twice.ps $(MAIN)-split-book-A5.ps
	# The following are generated
	$(RM) func-index.tex appLang-CNames.tex appLang-CppNames.tex appLang-FNames.tex

#
# Check the example programs
check: mpicompilechk/mpichk
	for dir in `find . -name 'chap-*' -type d -maxdepth 1 -print` ; do \
	    echo "Checking examples in $$dir" ; \
	    ( cd $$dir && ../mpicompilechk/mpichk *.tex ) ; \
	done	

#
# Create the single chapter versions of the document 
# These simplify checks for index and bibliographic entries
eachchap: 
	for dir in `find . -name 'chap-*' -type d -maxdepth 1 -print` ; do \
	    echo "Building chapter PDF in $$dir" ; \
	    ( cd $$dir && $(MAKE) ) ; \
	done

#
# The following targets produce specific versions of the document.
# For the versions that do not include extra text, but that 
# change the appearence slightly through color, we save the func-index.tex 
# as func-index-<version>.tex.  These provide a way to confirm that the 
# pagination is the same (it isn't a certain test, but a failure to compare
# does indicate an error).
#
# Produce a clean version of the standard.  By clean, we mean one without
# any markup about the changes in the standard.
cleandoc:
	rm -f mpi-report.toc func-index.tex mpi-report.ind
	@if [ -s mpi-report.cfg ] ; then \
	  mv -f mpi-report.cfg mpi-report.cfg.sav ; \
	  cp mpi-report-clean.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ; \
	  mv -f mpi-report.cfg.sav mpi-report.cfg ; \
	else \
	  cp mpi-report-clean.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ;  \
	  rm -f mpi-report.cfg ; \
	fi
	mv -f func-index.tex func-index-clean.tex
cleanbwdoc:
	rm -f mpi-report.toc func-index.tex mpi-report.ind
	@if [ -s mpi-report.cfg ] ; then \
	  mv -f mpi-report.cfg mpi-report.cfg.sav ; \
	  cp mpi-report-cleanbw.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ; \
	  mv -f mpi-report.cfg.sav mpi-report.cfg ; \
	else \
	  cp mpi-report-cleanbw.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ;  \
	  rm -f mpi-report.cfg ; \
	fi
	mv -f func-index.tex func-index-cleanbw.tex

reviewdoc:
	rm -f mpi-report.toc func-index.tex mpi-report.ind
	@if [ -s mpi-report.cfg ] ; then \
	  mv -f mpi-report.cfg mpi-report.cfg.sav ; \
	  cp mpi-report-review.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ; \
	  mv -f mpi-report.cfg.sav mpi-report.cfg ; \
	else \
	  cp mpi-report-review.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ;  \
	  rm -f mpi-report.cfg ; \
	fi

reviewchangeonlydoc:
	rm -f mpi-report.toc func-index.tex mpi-report.ind
	@if [ -s mpi-report.cfg ] ; then \
	  mv -f mpi-report.cfg mpi-report.cfg.sav ; \
	  cp mpi-report-changeonly.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ; \
	  mv -f mpi-report.cfg.sav mpi-report.cfg ; \
	else \
	  cp mpi-report-changeonly.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ;  \
	  rm -f mpi-report.cfg ; \
	fi
	mv -f func-index.tex func-index-changeonly.tex

bookprintingdoc:
	rm -f mpi-report.toc func-index.tex mpi-report.ind
	@if [ -s mpi-report.cfg ] ; then \
	  mv -f mpi-report.cfg mpi-report.cfg.sav ; \
	  cp mpi-report-bookprinting.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ; \
	  mv -f mpi-report.cfg.sav mpi-report.cfg ; \
	else \
	  cp mpi-report-bookprinting.cfg mpi-report.cfg ; \
	  echo "$(MAKE) mpi-report.pdf" ; \
	  $(MAKE) mpi-report.pdf ;  \
	  rm -f mpi-report.cfg ; \
	fi
	mv -f func-index.tex func-index-book.tex

allversions:
	$(MAKE) cleandoc
	mv mpi-report.pdf mpi$(MPIVERSIONSHORT)-report.pdf
	$(MAKE) cleanbwdoc
	mv mpi-report.pdf mpi$(MPIVERSIONSHORT)-reportbw.pdf
	$(MAKE) reviewdoc
	mv mpi-report.pdf mpi$(MPIVERSIONSHORT)-report-review.pdf
	$(MAKE) reviewchangeonlydoc
	mv mpi-report.pdf mpi$(MPIVERSIONSHORT)-report-changeonlyreview.pdf
	$(MAKE) bookprintingdoc
	mv mpi-report.pdf mpi$(MPIVERSIONSHORT)-report-book.pdf
	@if diff -b func-index-clean.tex func-index-cleanbw.tex ; then \
	: else \
	    echo "MPI report indices do not compare between clean and cleanbw" ; \
	fi
	@if diff -b func-index-clean.tex func-index-changeonly.tex ; then \
	: else \
	    echo "MPI report indices do not compare between clean and changeonly" ; \
	fi
	@if diff -b func-index-clean.tex func-index-book.tex ; then \
	: else \
	    echo "MPI report indices do not compare between clean and bookprinting (not part of the official MPI standardization)" ; \
	fi

HTMLVERSION:
	tohtml -default -basedef mpi2defs.txt -numbers -indexname myindex -dosnl -htables  -quietlatex -allgif -endpage mpi2-forum-tail.htm  -Wnoredef -o mpi22-report.tex mpi-report.tex
	tohtml -default -basedef mpi2defs.txt -numbers -indexname myindex -dosnl -htables  -quietlatex -allgif -endpage mpi2-forum-tail.htm  -Wnoredef -o mpi22-report.tex mpi-report.tex

#
BWHTMLVERSION:
	tohtml -default -basedef mpi2defs-bw.txt -numbers -indexname myindex -dosnl -htables  -quietlatex -allgif -endpage mpi2-forum-tail.htm  -Wnoredef -o mpi22-report-bw.tex mpi-report.tex
	tohtml -default -basedef mpi2defs-bw.txt -numbers -indexname myindex -dosnl -htables  -quietlatex -allgif -endpage mpi2-forum-tail.htm -Wnoredef -o mpi22-report-bw.tex mpi-report.tex

