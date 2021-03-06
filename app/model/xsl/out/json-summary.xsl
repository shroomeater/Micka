<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:csw="http://www.opengis.net/cat/csw/2.0.2"   
  xmlns:ows="http://www.opengis.net/ows" 
  xmlns:srv="http://www.isotc211.org/2005/srv" 
  xmlns:gmd="http://www.isotc211.org/2005/gmd"  
  xmlns:gmi="http://standards.iso.org/iso/19115/-2/gmi/1.0" 
  xmlns:gml="http://www.opengis.net/gml/3.2" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:gco="http://www.isotc211.org/2005/gco" 
  xmlns:php="http://php.net/xsl">
<xsl:output method="html"/>

<xsl:variable name="lower">abcdefghijklmnopqrstuvwxyz</xsl:variable>
<xsl:variable name="upper">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>

  <!-- pro ISO 19139 zaznamy -->
<xsl:template match="gmd:MD_Metadata">
    <xsl:variable name="apos">'</xsl:variable>
  	<xsl:variable name="mdlang" select="gmd:language/*/@codeListValue"/>
	$rec = array();
    
    <xsl:choose>
	  	<xsl:when test="(gmd:identificationInfo/srv:SV_ServiceIdentification)!=''">
            $rec['trida']='service';
            $rec['serviceType']='<xsl:value-of select="gmd:identificationInfo/*/srv:serviceType/*"/>';
      	</xsl:when>
		<xsl:when test="contains(gmd:distributionInfo/*/gmd:transferOptions/*/gmd:onLine/*/gmd:linkage/*,'wmc')">
	        $rec['trida']='wmc';
      	</xsl:when>
		<xsl:when test="gmd:hierarchyLevel/*/@codeListValue!=''">
           	$rec['trida']='<xsl:value-of select="gmd:hierarchyLevel/*/@codeListValue"/>';
       	</xsl:when>
		<xsl:otherwise>$rec['trida']='dataset';</xsl:otherwise>
	</xsl:choose>
		$rec['id'] = '<xsl:value-of select="normalize-space(gmd:fileIdentifier)"/>';	
		$rec['title'] = '<xsl:call-template name="multi">
		    	<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
		    	<xsl:with-param name="lang" select="$lang"/>
		    	<xsl:with-param name="mdlang" select="$mdlang"/>
		  	</xsl:call-template>'; 
		$rec['abstract'] = '<xsl:call-template name="multi">
		    	<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:abstract"/>
		      	<xsl:with-param name="lang" select="$lang"/>
		    	<xsl:with-param name="mdlang" select="$mdlang"/>
		  	</xsl:call-template>';
		$rec['link'] = '<xsl:value-of disable-output-escaping="yes" select="php:function('addslashes', normalize-space(gmd:distributionInfo/*/gmd:transferOptions/*/gmd:onLine/*/gmd:linkage/gmd:URL))"/>';
		$rec['links'] = array();
		<xsl:for-each select="gmd:distributionInfo/*/gmd:transferOptions/*/gmd:onLine">
			$l['url'] = '<xsl:value-of disable-output-escaping="yes" select="php:function('addslashes', normalize-space(*/gmd:linkage/gmd:URL))"/>';
			$l['protocol'] = '<xsl:value-of select="normalize-space(*/gmd:protocol)"/>';
            $rec['links'][] = $l;
		</xsl:for-each>
		$rec['formats'] = array();
		<xsl:for-each select="gmd:distributionInfo/*/gmd:distributionFormat">
			$rec['formats'][] = '<xsl:value-of select="*/gmd:name"/>';
		</xsl:for-each>
		<xsl:if test="gmd:identificationInfo/*/gmd:graphicOverview/*/gmd:fileName!=''">
			$rec['imgURL'] = '<xsl:value-of disable-output-escaping="yes" select="gmd:identificationInfo/*/gmd:graphicOverview/*/gmd:fileName"/>';
		</xsl:if>		
		$rec['bbox'] = '<xsl:value-of select="normalize-space(gmd:identificationInfo//gmd:westBoundLongitude)"/><xsl:text> </xsl:text><xsl:value-of select="normalize-space(gmd:identificationInfo//gmd:southBoundLatitude)"/><xsl:text> </xsl:text><xsl:value-of select="normalize-space(gmd:identificationInfo//gmd:eastBoundLongitude)"/><xsl:text> </xsl:text><xsl:value-of select="normalize-space(gmd:identificationInfo//gmd:northBoundLatitude)"/>';
		$rec['contact'] = '<xsl:call-template name="multi">
		    	<xsl:with-param name="el" select="gmd:contact/*/gmd:organisationName"/>
		    	<xsl:with-param name="lang" select="$lang"/>
		    	<xsl:with-param name="mdlang" select="$mdlang"/>
		  	</xsl:call-template>';
		$rec['inspireKeywords'] = array();
		<xsl:for-each select="gmd:identificationInfo/*/gmd:descriptiveKeywords[contains(*/gmd:thesaurusName/*/gmd:title/*,'INSPIRE')]/*/gmd:keyword[gco:CharacterString!='']">
			$rec['inspireKeywords'][] = '<xsl:value-of select="gco:CharacterString"/>';
		</xsl:for-each> 
		<xsl:variable name="degree" select="gmd:dataQualityInfo/*/gmd:report/gmd:DQ_DomainConsistency/gmd:result/gmd:DQ_ConformanceResult[contains(gmd:specification/*/gmd:title, 'INSPIRE') or contains(gmd:specification/*/gmd:title, 'Commission')]/gmd:pass/*"/>
		$rec['degree'] = <xsl:choose>
			<xsl:when test="$degree!=''"><xsl:value-of select="$degree"/>;</xsl:when>
			<xsl:otherwise>null;</xsl:otherwise>
		</xsl:choose>	
		$rec['coverageKm'] = '<xsl:value-of select="gmd:dataQualityInfo/*/gmd:report/gmd:DQ_CompletenessOmission[gmd:measureIdentification/*/gmd:code/*='CZ-COVERAGE']/gmd:result[contains(*/gmd:valueUnit/@xlink:href,'km')]/*/gmd:value/gco:Record"/>';
		$rec['coveragePercent'] = '<xsl:value-of select="gmd:dataQualityInfo/*/gmd:report/gmd:DQ_CompletenessOmission[gmd:measureIdentification/*/gmd:code/*='CZ-COVERAGE']/gmd:result[contains(*/gmd:valueUnit/@xlink:href,'percent')]/*/gmd:value/gco:Record"/>';

    $json['records'][] =$rec;
</xsl:template>	
	
	<!-- pro DC zaznamy -->
  <xsl:template match="csw:Record" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dct="http://purl.org/dc/terms/">
    <xsl:variable name="apos">'</xsl:variable>
		$rec = array();
	  	$rec['trida'] = '<xsl:value-of select="dc:type"/>';
		$rec['id'] = '<xsl:value-of select="dc:identifier[substring(.,1,4)!='http']"/>';
		$rec['title'] = '<xsl:value-of select="translate(normalize-space(dc:title), $apos, '')"/>';
		$rec['abstract'] = '<xsl:value-of select="translate(normalize-space(dct:abstract), $apos, '')"/>';
		if(!$rec['abstract']) $rec['abstract'] = '<xsl:value-of select="translate(normalize-space(dc:description), $apos, '')"/>';
		$rec['link'] = '<xsl:value-of select="dc:identifier[substring(.,1,4)='http']"/>';
		$rec['bbox'] = '<xsl:value-of select="ows:BoundingBox/ows:LowerCorner"/><xsl:text> </xsl:text><xsl:value-of select="ows:BoundingBox/ows:UpperCorner"/>';
   		$json['records'][] =$rec;
	</xsl:template> 
	

 <!-- pro multiligualni nazvy -->
  <xsl:template name="multi">
    <xsl:param name="el"/>
    <xsl:param name="lang"/>
    <xsl:param name="mdlang"/>
  
    <xsl:variable name="txt" select="$el/gmd:PT_FreeText/*/gmd:LocalisedCharacterString[@locale=concat('#locale-',$lang)]"/>	
     <xsl:choose>
    	<xsl:when test="string-length($txt)>0">
    	  <xsl:value-of select="php:function('addslashes', normalize-space($txt))"/>
    	</xsl:when>
    	<xsl:otherwise>
    	  <xsl:value-of select="php:function('addslashes', normalize-space($el/gco:CharacterString))"/>
    	</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
</xsl:stylesheet>
