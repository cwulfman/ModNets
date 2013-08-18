<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    
    A set of XSL templates for transforming the MODS records produced by
    the Modernist Journals Project into RDF suitable for ingestion into 
    ModNets.
    
    REFERENCES: http://wiki.collex.org/index.php/Submitting_RDF

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:mjp="http://modjourn.org"
    xmlns:collex="http://www.collex.org/schema#" xmlns:role="http://www.loc.gov/loc.terms/relators/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs mods" version="2.0">

    <xsl:output indent="yes"/>


    <!-- 
        GLOBAL DECLARATIONS
    -->

    <!-- Collex requires &quot;a shorthand reference to the contributing project or journal&quot;.  -->
    <xsl:variable name="project-id" as="xs:string">MJP</xsl:variable>

    <!-- Collex requires one or more federation ids. An authorized string for ModNets would be nice
    but this will do for now. -->
    <xsl:variable name="federation-id" as="xs:string">ModNets</xsl:variable>




    <!-- 
    TEMPLATES
    -->

    <xsl:template match="/">
        <!-- The top-level RDF element is REQUIRED. -->
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <!-- This stylesheet uses the &quot;pull&quot; method of XSL processing,
    because the purpose is to create a conformant Collex document, not to
    account for all elements in the MJP MODS record. -->

    <xsl:template match="mods:mods">
        <!-- An element with an rdf:about element is REQUIRED.  
            It does not have to be an rdf:Description element.  -->
        <rdf:Description rdf:about="http://modjourn.org/{@ID}"/>

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
            <xsl:apply-templates select="mods:titleInfo[1]"/>
        </dc:title>

        <!-- One or more <dc:type> elements are REQUIRED. -->
        <dc:type>
            <xsl:apply-templates select="mods:genre"/>
        </dc:type>

        <!-- One or more <role:*> elements are REQUIRED. The MJP does not
        presently record roles (like editor) for top-level titles, volumes, or issues. -->
        <xsl:apply-templates select="mods:name"/>


    </xsl:template>

    <xsl:template match="mods:titleInfo">
        <xsl:variable name="nonSort">
            <xsl:choose>
                <xsl:when test="mods:nonSort">
                    <xsl:value-of select="concat(mods:nonSort/text(), ' ')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="title">
            <xsl:value-of select="mods:title/text()"/>
        </xsl:variable>
        <xsl:variable name="subTitle">
            <xsl:choose>
                <xsl:when test="mods:subTitle">
                    <xsl:value-of select="concat(': ', mods:subTitle/text())"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="part">
            <xsl:choose>
                <xsl:when test="mods:partNumber">
                    <xsl:value-of select="concat(' (',mods:partNumber/text(),')')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($nonSort,$title,$subTitle,$part)"/>
    </xsl:template>

    <xsl:template match="mods:genre[@authority='aat']">
        <xsl:choose>
            <xsl:when test="./text() = 'periodicals'">
                <xsl:text>Periodical</xsl:text>
            </xsl:when>
            <xsl:otherwise>ERROR</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="mods:name">
        <!-- ARC has a fixed set of elements to denote roles. -->
        <xsl:variable name="name" select="mods:namePart/text()" as="xs:string"/>
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
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
