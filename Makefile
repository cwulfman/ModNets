mets := $(patsubst %.tif, %.mets, $(wildcard *.tif))
jp2s := $(patsubst %.tif, %.jp2, $(wildcard *.tif))

mfiles := $(cat issues.txt)

jp2files : $(jp2s)
metsfiles : $(mets)
rdffiles : $(mfiles)

%.rdf : %.xml
	saxon -s:$< -xsl:mjp2rdf.xsl -o:$@


%.jp2 : %.tif
	kdu_compress -i $< -o $@ -rate .80 Clevels=5 Clayers=5 Cuse_precincts=yes Cprecincts=\{256,256\} Cblk=\{64,64\} Corder=RPCL ORGgen_plt=yes ORGtparts=R Stiles=\{256,256\} \
	-jp2_space sRGB \
	-double_buffering 10 \
	-num_threads 2 \
        -no_weights \
	-quiet \

%.jpg : %.tif
	gm convert -scale 25% -quality 70% -colorspace sRGB $< $@

%.pdf : %.jpg
	gm convert $< $@

%.xmp : %.tif
	exiftool -xmp -b $< > $@

%.md5 : %.tif
	openssl md5 $< | sed -e 's/^.*= \(.*\)$\/\1/' > $@

%.sha1 : %.tif
	openssl sha1 $< | sed -e 's/^.*= \(.*\)$\/\1/' > $@


%.mets : %.xmp %.jp2 %.md5
	xsltproc --stringparam fname $* \
	--stringparam md5 `md5 -q $*.tif` \
	--stringparam sha1  `openssl sha1 $< | sed -e 's/^.*= \(.*\)$\/\1/'` \
	-o $@ xmp2mets.xsl $<



.PHONY: clean
clean:
	rm *.mets *.sha1 *.md5
