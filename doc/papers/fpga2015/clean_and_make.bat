taskkill /FI "WINDOWTITLE eq fpga15.pdf - Adobe Reader"
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
pdflatex fpga15.tex
bibtex -min-crossrefs=1000 fpga15
pdflatex fpga15.tex
pdflatex fpga15.tex
start fpga15.pdf