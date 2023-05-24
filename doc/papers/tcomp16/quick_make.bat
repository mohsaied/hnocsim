taskkill /FI "WINDOWTITLE eq tcomp.pdf - Adobe Reader"
taskkill /FI "WINDOWTITLE eq tcomp.pdf - Adobe Acrobat Reader DC"
del *.blg
del *.bbl
del *.toc
del *.out
del *.log
del *.aux
del *.dvi
del *.mtc*
del *.nlo
del *.maf
del *.lot
del *.lof
del *.ilg
del *.brf
del *.nls	
pdflatex -interaction=batchmode tcomp.tex
bibtex -min-crossrefs=1000 tcomp
pdflatex -interaction=batchmode tcomp.tex
pdflatex -interaction=batchmode tcomp.tex
start tcomp.pdf