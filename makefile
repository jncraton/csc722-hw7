SRC=index
PANDOC_VER=2.3.1

all: test $(SRC).html slides.html $(SRC).pdf

.PHONY: show showpdf clean

slides.html: $(SRC).md makefile
	pandoc --mathjax -t revealjs -s -o $@ $< -V revealjs-url=https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.6.0 -V theme=moon

pandoc:
	wget https://github.com/jgm/pandoc/releases/download/$(PANDOC_VER)/pandoc-$(PANDOC_VER)-linux.tar.gz
	tar -zxvf pandoc-$(PANDOC_VER)-linux.tar.gz pandoc-$(PANDOC_VER)/bin/pandoc
	mv pandoc-$(PANDOC_VER)/bin/pandoc .
	rm -rf pandoc-$(PANDOC_VER)

xetex:
	wget -qO- "https://yihui.name/gh/tinytex/tools/install-unx.sh" | sh
	touch xetex

$(SRC).odt: $(SRC).md
	pandoc --toc -o $@ $<

$(SRC)-md2html.html: $(SRC).pmd
	pweave --format=md2html $(SRC).pmd
	# Hack to remove padding from first line of code blocks
	sed -i -e "s/padding: 2px 4px//g" $(SRC).html

$(SRC).html: $(SRC).md
	pandoc --mathjax --standalone --css=style.css --toc -o $@ $<

$(SRC).md: $(SRC).pmd
	pweave --format=pandoc $(SRC).pmd

$(SRC).py: $(SRC).pmd
	ptangle $(SRC).pmd

$(SRC).pdf: $(SRC).md pandoc xetex
	./pandoc --toc --variable documentclass=extarticle --variable fontsize=12pt --variable mainfont="FreeSans" --variable monofont="FreeMono"  --mathjax --pdf-engine=$HOME/bin/xelatex -s -o $@ $< 

show: $(SRC).html
	firefox $(SRC).html

showpdf: $(SRC).pdf
	firefox $(SRC).pdf
	
run: $(SRC).py
	python3 $(SRC).py

test: $(SRC).py
	cat testhead.py $(SRC).py > $(SRC)-test.py

	# Hack to prevent multiprocessing on module import
	sed -i -e "s/from multiprocessing/from multiprocessing.dummy/g" $(SRC)-test.py
	
	python3 -m doctest $(SRC)-test.py

readme.md: gen_readme.py
	python3 gen_readme.py > readme.md

clean:
	rm -f $(SRC).txt $(SRC).odt $(SRC).docx $(SRC).pdf $(SRC).md $(SRC).py $(SRC)-test.py $(SRC).html slides.html
	rm -rf figures
	rm -rf __pycache__
	rm -f pandoc
