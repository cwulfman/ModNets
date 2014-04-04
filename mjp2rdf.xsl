<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    A set of XSL templates for transforming the METS records produced by
    the Modernist Journals Project (the MJP objects) into RDF suitable for ingestion into 
    ModNets.
    
    REFERENCES: http://wiki.collex.org/index.php/Submitting_RDF
-->

<!-- This stylesheet uses the &quot;pull&quot; method of XSL processing,
    because the purpose is to create a conformant Collex document, not to
    account for all elements in the MJP MODS record. -->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mjp="http://modjourn.org/schema#"
    xmlns:mets="http://www.loc.gov/METS/" xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/" xmlns:collex="http://www.collex.org/schema#"
    xmlns:role="http://www.loc.gov/loc.terms/relators/" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs mods" version="2.0">

    <xsl:output indent="yes"/>


    <!-- 
        GLOBAL DECLARATIONS
    -->

    <!-- Collex REQUIRES "a shorthand reference to the contributing project or journal."  -->
    <xsl:variable name="project-id" as="xs:string">mjp</xsl:variable>

    <!-- Collex REQUIRES one or more federation ids. An authorized string for ModNets would be nice
    but this will do for now. -->
    <xsl:variable name="federation-id" as="xs:string">ModNets</xsl:variable>

    <!-- Collex REQUIRES one or more disciplines.  These are not terribly well defined; for
    now, Literature seems to be the only one universally applicable to MJP materials. -->
    <xsl:variable name="disciplines">
        <disciplines>
            <discipline>Literature</discipline>
        </disciplines>
    </xsl:variable>


    <!--   
	 TEMPLATES
    -->

    <xsl:template match="/">
        <!-- The top-level RDF element is REQUIRED. -->
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <!-- 
        The MJP library contains resources of the following types:
        
text.periodicals.issue
text.biographies
image
text.essays
collection
text.indexes
text.books
text.periodicals
text

Each requies a different kind of RDF.
    -->


    <!-- 
    Periodical Issues (text.periodicals.issue)
-->

    <xsl:template match="mets:mets[@TYPE='text.periodicals.issue']">
        <!-- An element with an rdf:about element is REQUIRED.  
            The spec says it should be an arbitrary element in the
            project's namespace.  -->
        <xsl:variable name="objid" select="@OBJID"/>
        <mjp:Description rdf:about="http://modjourn.org/{@OBJID}">
            <xsl:apply-templates select="//mods:mods">
                <xsl:with-param name="objid" select="@OBJID"/>
            </xsl:apply-templates>
        </mjp:Description>

        <!-- Generate an RDF object for each issue constituent.	-->

        <xsl:for-each select="//mods:mods/mods:relatedItem[@type='constituent']">
            <!-- The MJP does not assign IDs to relatedItems (it should)
	       so we must construct a unique id for the relatedItem
	       from its position in the sequence of relatedItems. -->
            <mjp:Description rdf:about="http://modjourn.org/{$objid}#{position()}">
                <dcterms:isPartOf rdf:resource="http://modjourn.org/{$objid}"/>
                <xsl:apply-templates select=".">
                    <xsl:with-param name="objid" select="$objid"/>
                </xsl:apply-templates>
            </mjp:Description>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="mods:mods">
        <xsl:param name="objid"/>

        <!-- One or more <collex:federation> elements are REQUIRED. -->
        <collex:federation>
            <xsl:value-of select="$federation-id"/>
        </collex:federation>

        <!-- A SINGLE <collex:archive> element is REQUIRED. -->
        <collex:archive>
            <xsl:value-of select="$project-id"/>
        </collex:archive>

        <!-- A SINGLE <dc:title> element is REQUIRED. -->
        <!--Some issues may have more than one title element; use the
	     first one. -->
        <dc:title>
            <xsl:apply-templates select="mods:titleInfo[1]"/>
        </dc:title>

        <!-- ONE OR MORE <dc:type> elements are REQUIRED. We determine
             the dc:type from the mods:genre; NB that the mods:genre
             element is also used to determine the collex:genre. -->
        <dc:type>
            <xsl:apply-templates select="mods:genre"/>
        </dc:type>

        <!-- ONE OR MORE <role:*> elements are REQUIRED. The MJP does not
        presently record roles (like editor) for top-level titles, volumes, or issues. -->
        <xsl:choose>
            <xsl:when test="mods:name">
                <xsl:apply-templates select="mods:name"/>
            </xsl:when>
            <xsl:otherwise><role:AUT>Unknown</role:AUT></xsl:otherwise>
        </xsl:choose>

        <!-- One or more <collex:discipline> elements are REQUIRED. -->
        <xsl:for-each select="$disciplines/disciplines/discipline">
            <collex:discipline>
                <xsl:value-of select="current()"/>
            </collex:discipline>
        </xsl:for-each>

        <!-- ONE OR MORE <collex:genre> elements are REQUIRED. -->
        <xsl:apply-templates select="mods:genre" mode="collex-genre"/>

        <!-- ONE OR MORE <dc:date> elements are REQUIRED. -->
        <dc:date>
            <xsl:value-of select="mods:originInfo/mods:dateIssued[@keyDate='yes']"/>
        </dc:date>

        <!-- ONE <rdfs:seeAlso> element with the URL of the resource is REQUIRED. 
	     We write a function, mjp:object-URL(), that returns this URL. -->
        <rdfs:seeAlso>
            <xsl:attribute name="rdf:resource" select="mjp:object-URL($objid)"/>
        </rdfs:seeAlso>

        <!-- END OF REQUIRED ELEMENTS -->

        <!-- Generate a <collex:source_xml> element that points to the TEI file
        associated with this object.  Unfortunately, that file is not represented in the 
        fileSec of the METS.  Fortunately, there is a naming convention: the
        TEI derivative is named MJPID.tei.xml, where MJPID is the ID of the MODS record,
	so we write a function, mjp:tei-URL() that returns a URL. -->
        <collex:source_xml>
            <xsl:value-of select="mjp:tei-URL(@ID)"/>
        </collex:source_xml>

        <!-- MODS constituents are represented as explicit resources (objects).
        In the parent (issue) object, their relationship with the parent object
        is represented with <dcterms:hasPart> elements. -->
        <xsl:for-each select="mods:relatedItem[@type='constituent']">
            <dcterms:hasPart rdf:resource="http://modjourn.org/{$objid}#{position()}"/>
        </xsl:for-each>
    </xsl:template>






    <!-- This template converts a mods:titleInfo element into a formatted string.
    The complete format is the following: NonSort Title: Subtitle (Part) -->
    <xsl:template match="mods:titleInfo">
        <xsl:variable name="nonSort">
            <xsl:choose>
                <xsl:when test="mods:nonSort">
                    <xsl:value-of select="concat(mods:nonSort/text(), ' ')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="title">
            <xsl:value-of select="mods:title[1]/text()"/>
        </xsl:variable>
        <xsl:variable name="subTitle">
            <xsl:choose>
                <xsl:when test="mods:subTitle">
                    <xsl:value-of select="concat(': ', mods:subTitle[1]/text())"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="part">
            <xsl:choose>
                <xsl:when test="mods:partNumber">
                    <xsl:value-of select="concat(' (',mods:partNumber[1]/text(),')')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($nonSort,$title,$subTitle,$part)"/>
    </xsl:template>


    <xsl:template match="mods:genre[@authority='aat' or @authority='marcgt']">
        <!-- <dc:type> is poorly implemented in Collex.
            For purposes of ingestion into Collex, we identify
            magazine issues as Collections and the contents of
	    issues as Periodical. -->
        <xsl:choose>
            <xsl:when test="./text() = 'periodicals'">
                <xsl:text>Collection</xsl:text>
            </xsl:when>
            <xsl:otherwise>Periodical</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- We need a default for the genre of *all* constituent content;
    the only reasonable value is Periodical. -->
    <xsl:template match="mods:genre">
      <xsl:text>Periodical</xsl:text>
    </xsl:template>

    <xsl:template match="mods:genre" mode="collex-genre">
        <collex:genre>
            <xsl:choose>
                <xsl:when test="./text() = 'periodicals'">
                    <xsl:text>Collection</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'articles'">
                    <xsl:text>Nonfiction</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'advertisements'">
                    <xsl:text>Ephemera</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'letters'">
                    <xsl:text>Correspondence</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'poetry'">
                    <xsl:text>Poetry</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'fiction'">
                    <xsl:text>Fiction</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'drama'">
                    <xsl:text>Drama</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'images'">
                    <xsl:text>Visual Art</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Unspecified</xsl:text>
                </xsl:otherwise>
                
            </xsl:choose>
        </collex:genre>
    </xsl:template>

    <xsl:template match="mods:name">
        <!-- ARC has a fixed set of elements to denote roles. -->

        <!-- The MJP data occasionally uses namePart[@type='date'] and
             namePart[@type='termsOfAddress'] but mostly uses untyped
             nameParts (no 'given' or 'family').  We pluck out the
             untyped namePart for the RDF. -->
        
        <!-- MJP data is somewhat dirty. There are <mods:name>
             elements with <mods:role> subelements but no
             <mods:namePart> element.  We have to check for this.-->
        <xsl:if test="mods:namePart[empty(@type)]">
            <xsl:variable name="name">
                <xsl:apply-templates select="mods:namePart[empty(@type)]" />
            </xsl:variable>
        
        <xsl:if test="$name">
            <xsl:variable name="roleTerm" select="mods:role/mods:roleTerm/text()"/>
            <xsl:choose>
                <xsl:when test="$roleTerm = 'editor'">
                    <role:EDT>
                        <xsl:value-of select="$name"/>
                    </role:EDT>
                </xsl:when>
                <xsl:when test="$roleTerm = 'creator'">
                    <role:CRE>
                        <xsl:value-of select="$name"/>
                    </role:CRE>
                </xsl:when>
                <xsl:when test="$roleTerm = 'translator'">
                    <role:TRL>
                        <xsl:value-of select="$name"/>
                    </role:TRL>
                </xsl:when>
		
            </xsl:choose>
        </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:function name="mjp:object-URL">
        <xsl:param name="objid" as="xs:string"/>

        <xsl:value-of
            select="concat('http://modjourn.org/render.php?id=', $objid,'&amp;', 'view=mjp_object')"
        />
    </xsl:function>

    <xsl:function name="mjp:tei-URL">
        <xsl:param name="modsid" as="xs:string"/>
        <xsl:value-of select="concat('http://dl.lib.brown.edu/mjp/teifiles/', $modsid, '.tei.xml')"
        />
    </xsl:function>

    

    <!-- Template for processing issue constituents.  There's a good
         deal of overlap with the mods:mods template, so some code
         refactoring needs to be done. -->
    <xsl:template match="mods:relatedItem[@type='constituent']">
        <xsl:param name="objid"/>

        <!-- One or more <collex:federation> elements are REQUIRED. -->
        <collex:federation>
            <xsl:value-of select="$federation-id"/>
        </collex:federation>

        <!-- A SINGLE <collex:archive> element is REQUIRED. -->
        <collex:archive>
            <xsl:value-of select="$project-id"/>
        </collex:archive>

        <!-- A SINGLE <dc:title> element is REQUIRED. -->

        <dc:title>
	  <xsl:choose>
	    <xsl:when test="mods:titleInfo[1]">
              <xsl:apply-templates select="mods:titleInfo[1]"/>	      
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:text>[untitled]</xsl:text>
	    </xsl:otherwise>
	  </xsl:choose>
        </dc:title>

        <!-- One or more <dc:type> elements are REQUIRED. -->
        <dc:type>
            <xsl:apply-templates select="mods:genre"/>
        </dc:type>

        <!-- One or more <role:*> elements are REQUIRED. The MJP does not
        presently record roles (like editor) for top-level titles, volumes, or issues.
        ARC advises to encode <role:AUT>Unknown</role:AUT> to indicate that the
        -->
        <xsl:choose>
            <xsl:when test="mods:name and not(empty(mods:name/text()))">
                <xsl:apply-templates select="mods:name"/>
            </xsl:when>
            <xsl:otherwise><role:AUT>Unknown</role:AUT></xsl:otherwise>
        </xsl:choose>


        <!-- One or more <collex:discipline> elements are REQUIRED. -->
        <xsl:for-each select="$disciplines/disciplines/discipline">
            <collex:discipline>
                <xsl:value-of select="current()"/>
            </collex:discipline>
        </xsl:for-each>

        <!-- One or more <collex:genre> elements are REQUIRED. -->
        <xsl:apply-templates select="mods:genre" mode="collex-genre"/>

        <!-- One or more <dc:date> elements are REQUIRED. -->
        <dc:date>
            <xsl:value-of
                select="ancestor::mods:mods/mods:originInfo/mods:dateIssued[@keyDate='yes']"/>
        </dc:date>

        <!-- ONE <rdfs:seeAlso> element with the URL of the resource is REQUIRED. -->
        <rdfs:seeAlso>
            <xsl:attribute name="rdf:resource" select="mjp:object-URL($objid)"/>
        </rdfs:seeAlso>
    </xsl:template>

</xsl:stylesheet>
