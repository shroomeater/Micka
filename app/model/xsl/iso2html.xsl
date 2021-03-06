<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" 
	xmlns:php="http://php.net/xsl" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:csw="http://www.opengis.net/cat/csw/2.0.2" 
	xmlns:ows="http://www.opengis.net/ows" 
	xmlns:srv="http://www.isotc211.org/2005/srv" 
	xmlns:gmd="http://www.isotc211.org/2005/gmd" 
  	xmlns:gmi="http://standards.iso.org/iso/19115/-2/gmi/1.0" 
	xmlns:gml="http://www.opengis.net/gml"
	xmlns:gml32="http://www.opengis.net/gml/3.2" 
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:gmx="http://www.isotc211.org/2005/gmx"
	xmlns:gfc="http://www.isotc211.org/2005/gfc" 
	xmlns:gco="http://www.isotc211.org/2005/gco">
	<xsl:output method="html"/>
	
	<xsl:variable name="apos">\'</xsl:variable>
	<xsl:variable name="msg" select="document(concat('client/labels-', $lang, '.xml'))/messages/msg"/>
	<xsl:variable name="capabilities" select="document(concat('../../cfg/cswConfig-', $lang, '.xml'))"/>
	<xsl:variable name="cl" select="document(concat('codelists_', $lang, '.xml'))/map"/>
	<xsl:variable name="mdlang" select="*/gmd:language/gmd:LanguageCode/@codeListValue"/>
	<xsl:include href="client/common_cli.xsl" />

	<xsl:template match="/*">
		<html>
		<head>
			<title><xsl:call-template name="multi">
					<xsl:with-param name="el" select="*/*/gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
					<xsl:with-param name="lang" select="$lang"/>
					<xsl:with-param name="mdlang" select="$mdlang"/>
				</xsl:call-template> (Metadata)</title>
			<xsl:variable name="desc">
				<xsl:call-template name="multi">
					<xsl:with-param name="el" select="*/*/gmd:identificationInfo/*/gmd:abstract"/>
					<xsl:with-param name="lang" select="$lang"/>
					<xsl:with-param name="mdlang" select="$mdlang"/>
				</xsl:call-template>
			</xsl:variable>		
			<meta name="Description" content="{$desc}"/>
			<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
			<base href=".." />
			<link rel="shortcut icon" href="themes/{$THEME}/favicon.ico"/>
			<link rel="stylesheet" type="text/css" href="themes/{$THEME}/micka.css"/>
			<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.6.0/css/font-awesome.min.css"/>
			<link title="MICKA" href="csw/opensearch.php" type="application/opensearchdescription+xml" rel="search"/>
			<script language="javascript" src="scripts/micka.js"></script>
			<link rel="stylesheet" href="scripts/ol3/css/ol.css" type="text/css"/>
			<script src="scripts/ol3/build/ol.js"></script>
		    <style>
		    	@import url(themes/<xsl:value-of select="$THEME"/>/single.css);
		    </style>		
		</head>
		<body id="micka-body" onload="micka.initMap();" style=" background:#F8F8F8; text-align:center;">
		<div style="background:white; padding: 10px; max-width: 21cm; text-align:left; margin: auto; border: 1px solid #DDD; position:relative" vocab="http://www.w3.org/ns/dcat#" typeof="http://www.w3.org/2000/01/rdf-schema#Resource">
			<div id="topper" class="noprint">
				<a href="https://geoportal.gov.cz/web/guest/home"></a>
				<h1 style="padding-top:10px"><xsl:value-of select="$capabilities//ows:Title"/></h1>
			</div>

			<xsl:if test="count(*)=0">
				<h1><xsl:value-of select="$msg[@eng='Bad']"/></h1>
			</xsl:if>
			<xsl:apply-templates select="rec/gmd:MD_Metadata|rec/gmi:MI_Metadata"/>
			<xsl:apply-templates select="rec/gfc:FC_FeatureCatalogue"/>
			<xsl:apply-templates select="rec/csw:Record"/>
			<xsl:apply-templates select="//csw:GetRecordByIdResponse/*"/>
			<xsl:if test="@read=1">
				<a class="go-back" href="javascript:history.back();" title="{$msg[@eng='Back']}"/>
			</xsl:if>
		</div>
		<div id="footer">
			<a href="{$capabilities/*/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:OnlineResource/@xlink:href}" target="_blank"><xsl:value-of select="$capabilities/*/ows:ServiceProvider/ows:ProviderName"/></a>
		</div>
		</body>
		</html>		
	</xsl:template>
	
	<xsl:template match="gmd:MD_Metadata|gmi:MI_Metadata"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:csw="http://www.opengis.net/cat/csw/2.0.2" 
	xmlns:ows="http://www.opengis.net/ows" 
	xmlns:srv="http://www.isotc211.org/2005/srv" 
    xmlns:gmi="http://standards.iso.org/iso/19115/-2/gmi/1.0"  
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xmlns:xlink="http://www.w3.org/1999/xlink" 
	xmlns:gco="http://www.isotc211.org/2005/gco">
		<xsl:variable name="rtype" select="gmd:hierarchyLevel/*/@codeListValue"/>
		<xsl:variable name="srv">
			<xsl:choose>
				<xsl:when test="name(gmd:identificationInfo/*)='srv:SV_ServiceIdentification'">1</xsl:when>
				<xsl:otherwise>0</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

	<h2 class="noprint">
		<div class="icons">
		  	<xsl:variable name="wmsURL" select="gmd:distributionInfo/*/gmd:transferOptions/*/gmd:onLine/*[contains(gmd:protocol/*,'WMS') or contains(gmd:linkage/*,'WMS')]/gmd:linkage/*"/>		  		
			<xsl:if test="gmd:identificationInfo/*/srv:serviceType/*='download'">
				<a href="csw/?service=CSW&amp;version=2.0.2&amp;request=GetRecordById&amp;id={gmd:fileIdentifier}&amp;language={$LANGUAGE}&amp;outputSchema=http://www.w3.org/2005/Atom" target="_blank" title="Atom"><i class="fa fa-feed fa-fw"></i></a>
			</xsl:if>
			<xsl:if test="string-length($wmsURL)>0">
				<xsl:choose>
					<xsl:when test="contains($wmsURL,'?')">
			   			<a class='map' href="{$viewerURL}{substring-before($wmsURL,'?')}" target="wmsviewer"><i class="fa fa-map-o fa-fw"></i></a>		  				
					</xsl:when>
					<xsl:otherwise>
						<a class='map' href="{$viewerURL}{$wmsURL}" target="wmsviewer"><i class="fa fa-map-o fa-fw"></i></a>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text> </xsl:text>
			</xsl:if>
			<xsl:if test="../@read=1">
				<xsl:if test="../@md_standard=0 or ../@md_standard=10">
					<a href="csw/?service=CSW&amp;request=GetRecordById&amp;id={../@uuid}&amp;outputschema=http://www.w3.org/ns/dcat%23" class="rdf" target="_blank" title="Geo-DCAT RDF"><i class="fa fa-cube fa-fw"></i></a>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$REWRITE">	
							<a href="records/{../@uuid}?format=application/xml" class="xml" target="_blank" title="XML"><i class="fa fa-file-code-o fa-fw"></i></a>
						</xsl:when>
					<xsl:otherwise>
							<a href="?ak=xml&amp;uuid={../@uuid}" class="xml" target="_blank" title="XML"><i class="fa fa-file-code-o fa-fw"></i></a>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</div>			
		<xsl:if test="../@read=1">
			<span class="icons">
				<xsl:choose>
					<xsl:when test="$REWRITE">	
						<a href="records/{../@uuid}?detail=full&amp;language={$lang}" class="icons" title="{$msg[@eng='fullMetadata']}"><i class="fa fa-folder-o fa-fw"></i></a>
					</xsl:when>
					<xsl:otherwise>
						<a href="?ak=detailall&amp;uuid={../@uuid}" class="icons" title="{$msg[@eng='fullMetadata']}"><i class="fa fa-folder-o fa-fw"></i></a>
					</xsl:otherwise>
				</xsl:choose>
			</span>		
		</xsl:if>
		<xsl:text> </xsl:text>
		<xsl:value-of select="$msg[@eng='basicMetadata']"/>
	</h2>

	<h1 title="{$cl/updateScope/value[@name=$rtype]}" property="http://purl.org/dc/terms/title">
		<div class="{$rtype}" style="padding-left: 20px;"><xsl:call-template name="multi">
			<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
			<xsl:with-param name="lang" select="$lang"/>
			<xsl:with-param name="mdlang" select="$mdlang"/>
		</xsl:call-template>
		 <xsl:if test="gmd:hierarchyLevelName/*='http://geoportal.gov.cz/inspire'"><span class="for-inspire" title="{$msg[@eng='forInspire']}"></span></xsl:if>
		</div>
	</h1>
	
	<div class="report">
		<div class="row">
			<label><xsl:value-of select="$msg[@eng='Abstract']"/></label>
			<div class="c" property="http://purl.org/dc/terms/description">
				<xsl:call-template name="multi">
					<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:abstract"/>
					<xsl:with-param name="lang" select="$lang"/>
					<xsl:with-param name="mdlang" select="$mdlang"/>
				</xsl:call-template>
			</div>
		</div>

		  	<xsl:if test="gmd:identificationInfo/*/gmd:graphicOverview/*/gmd:fileName/*">
		  		<div class="row">
		  			<label><xsl:value-of select="$msg[@eng='Browse Graphic']"/></label>
					<div class="c">
	  					<div><img src="{gmd:identificationInfo/*/gmd:graphicOverview/*/gmd:fileName/*}"/></div>
	  					<div>
		  					<xsl:call-template name="multi">
			    				<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:graphicOverview/*/gmd:fileDescription"/>
			    				<xsl:with-param name="lang" select="$LANGUAGE"/>
			    				<xsl:with-param name="mdlang" select="$mdlang"/>
			  				</xsl:call-template>  					
	  					</div>
					</div>
				</div>
	  		</xsl:if>	
			
			<div class="row" rel="http://www.w3.org/1999/02/22-rdf-syntax-ns#type">
				<label><xsl:value-of select="$msg[@eng='Type']"/></label>
				<xsl:variable name="res">
					<xsl:choose>
						<xsl:when test="$rtype='service'">Catalog</xsl:when>
						<xsl:otherwise>Dataset</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<div class="c" resource="http://www.w3.org/ns/dcat#{$res}">
					<xsl:value-of select="$cl/updateScope/value[@name=$rtype]"/>
					<xsl:if test="gmd:hierarchyLevelName != ''">
					- <xsl:value-of select="gmd:hierarchyLevelName"/>
					</xsl:if>
				</div>
			</div>

	
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Resource Locator']"/></label>
				<div class="c">
					<xsl:for-each select="gmd:distributionInfo/*/gmd:transferOptions/*/gmd:onLine">
						<xsl:variable name="label">
                                <xsl:choose>
                                	<xsl:when test="*/gmd:description">
                                		<xsl:call-template name="multi">
                                            <xsl:with-param name="el" select="*/gmd:description"/>
                                            <xsl:with-param name="lang" select="$LANGUAGE"/>
                                            <xsl:with-param name="mdlang" select="$mdlang"/>
                                        </xsl:call-template>
                                	</xsl:when>
                                    <xsl:when test="*/gmd:name">
                                        <xsl:call-template name="multi">
                                            <xsl:with-param name="el" select="*/gmd:name"/>
                                            <xsl:with-param name="lang" select="$LANGUAGE"/>
                                            <xsl:with-param name="mdlang" select="$mdlang"/>
                                        </xsl:call-template>
                                    </xsl:when>
                                    <xsl:otherwise><xsl:value-of select="*/gmd:linkage"/></xsl:otherwise>
                                </xsl:choose>
						</xsl:variable>
                        <div>
                          	<xsl:choose>
                           		<xsl:when test="contains(*/gmd:protocol, 'DOWNLOAD')">
                                	<a href="{*/gmd:linkage}"  target="_blank">
                                      	<span style="color:#070; font-size:20px;"><i class="fa fa-download"></i></span><xsl:text> </xsl:text>
                                      	<xsl:value-of select="$label"/>
                                	</a>	
                            	</xsl:when>
                           		<xsl:when test="contains(*/gmd:protocol, 'rss')">
                                	<a href="{*/gmd:linkage}"  target="_blank">
                                      	<span style="color:#ff6600; font-size:20px;"><i class="fa fa-feed"></i></span><xsl:text> </xsl:text>
                                      	<xsl:value-of select="$label"/>
                                	</a>	
                            	</xsl:when>
								<xsl:when test="contains(*/gmd:protocol/*,'WMS') or contains(*/gmd:linkage/*,'WMS')">
									<xsl:variable name="label1">
		                                <xsl:choose>
			                                	<xsl:when test="*/gmd:description">
			                                		<xsl:call-template name="multi">
			                                            <xsl:with-param name="el" select="*/gmd:description"/>
			                                            <xsl:with-param name="lang" select="$LANGUAGE"/>
			                                            <xsl:with-param name="mdlang" select="$mdlang"/>
			                                        </xsl:call-template>
			                                	</xsl:when>		                                    
			                                	<xsl:when test="*/gmd:name">
		                                        <xsl:call-template name="multi">
		                                            <xsl:with-param name="el" select="*/gmd:name"/>
		                                            <xsl:with-param name="lang" select="$LANGUAGE"/>
		                                            <xsl:with-param name="mdlang" select="$mdlang"/>
		                                        </xsl:call-template>
		                                    </xsl:when>
		                                    <xsl:otherwise><xsl:value-of select="$msg[@eng='showMap']"/></xsl:otherwise>
		                                </xsl:choose>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="contains(*/gmd:linkage/*,'?')">
							   				<a class='map' href="{$viewerURL}{substring-before(*/gmd:linkage/*,'?')}" target="wmsviewer"><span style="color:#ff6600; font-size:20px;"><i class="fa fa-map"></i></span> WMS: <xsl:value-of select="$label1"/></a>		  				
										</xsl:when>
										<xsl:otherwise>
											<a class='map' href="{$viewerURL}{*/gmd:linkage/*}" target="wmsviewer"><span style="color:#ff6600; font-size:20px;"><i class="fa fa-map"></i></span> WMS: <xsl:value-of select="$label1"/></a>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
                                <xsl:otherwise>
                                	<a href="{*/gmd:linkage}"  target="_blank">
                                		<span style="font-size:20px;"><i class="fa fa-external-link-square"></i></span><xsl:text> </xsl:text>
                                		<xsl:value-of select="$label"/>
                                	</a>
                                </xsl:otherwise>
                        	</xsl:choose>   
                        </div>
					</xsl:for-each>
				</div>
			</div>


			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Identifier']"/></label>
				<div class="c" property="http://purl.org/dc/terms/identifier">
					<xsl:value-of select="gmd:identificationInfo/*/gmd:citation/*/gmd:identifier/*/gmd:code"/>
				</div>
			</div>
			

		<xsl:if test="$srv!=1">
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Language']"/></label>
				<div class="c">
					<xsl:for-each select="gmd:identificationInfo/*/gmd:language">
						<xsl:variable name="kod" select="*/@codeListValue"/>
						<xsl:value-of select="$cl/language/value[@code=$kod]"/>
						<xsl:if test="position()!=last()">, </xsl:if>
					</xsl:for-each>
				</div>
			</div>
			
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Topic category']"/></label>
				<div class="c">
					<xsl:for-each select="gmd:identificationInfo/*/gmd:topicCategory">
						<xsl:variable name="k" select="*"/>
						<xsl:value-of select="$cl/topicCategory/value[@name=$k]"/>
						<xsl:if test="position()!=last()"><br/></xsl:if>
					</xsl:for-each>
				</div>
			</div>
		</xsl:if>


		<xsl:if test="$srv=1">
			<div class="row">
				<label>
					<xsl:value-of select="$msg[@eng='Service Type']"/>
				</label>
				<div class="c">
					<xsl:value-of select="gmd:identificationInfo/*/srv:serviceType"/>
					<xsl:for-each select="gmd:identificationInfo/*/srv:serviceTypeVersion">
						<xsl:text> </xsl:text>
						<xsl:value-of select="."/>
						<xsl:if test="not(position()=last())">,</xsl:if>
					</xsl:for-each>
				</div>
			</div>
		</xsl:if>

			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Keywords']"/></label>
				<div class="c">
					<xsl:for-each select="//gmd:descriptiveKeywords[string-length(*/gmd:thesaurusName/*/gmd:title/*)>0]">

						<xsl:choose>
							<!-- blbost kvuli CENII -->
							<xsl:when test="contains(*/gmd:thesaurusName/*/gmd:title/*,'CENIA')">
								<i><b>GEOPORTAL:</b></i>
								<xsl:for-each select="*/gmd:keyword">
							     	<div style="margin-left:20px;">
							     		<xsl:variable name="k" select="*"/>
							     		<xsl:value-of select="$cl/cenia/value[@name=$k]"/>
							     	</div>
						  		</xsl:for-each>
				  			</xsl:when>

				  			<!-- ISO 19119 -->
							<xsl:when test="contains(*/gmd:thesaurusName/*/gmd:title/*,'ISO - 19119') or contains(*/gmd:thesaurusName/*/gmd:title/*,'INSPIRE Services')">
								<i><b>ISO 19119:</b></i>
								<xsl:for-each select="*/gmd:keyword">
							     	<div style="margin-left:20px;">
							     		<xsl:variable name="k" select="*"/>
							     		<a property="http://www.w3.org/ns/dcat#theme" resource="http://inspire.ec.europa.eu/metadata-codelist/SpatialDataServiceCategory/{$k}" href="http://inspire.ec.europa.eu/metadata-codelist/SpatialDataServiceCategory/{$k}" target="_blank">
							     		<xsl:value-of select="$cl/serviceKeyword/value[@name=$k]"/></a>
							     	</div>
						  		</xsl:for-each>
				  			</xsl:when>

				  			<xsl:otherwise>
								<xsl:variable name="thesaurus">
									<xsl:call-template name="multi">
										<xsl:with-param name="el" select="*/gmd:thesaurusName/*/gmd:title"/>
										<xsl:with-param name="lang" select="$lang"/>
										<xsl:with-param name="mdlang" select="$mdlang"/>
									</xsl:call-template>
								</xsl:variable>
								<i><b><xsl:value-of select="$thesaurus"/>:</b></i>
						  		<div style="margin-left:20px;">
								<xsl:for-each select="*/gmd:keyword">
							     		<xsl:variable name="theme">
								     		<xsl:call-template name="multi">
								    			<xsl:with-param name="el" select="."/>
								    			<xsl:with-param name="lang" select="$lang"/>
								    			<xsl:with-param name="mdlang" select="$mdlang"/>
								  			</xsl:call-template>
								  		</xsl:variable>							     	
							  			<xsl:choose>
								     		<xsl:when test="starts-with(*/@xlink:href, 'http://inspire.ec.europa.eu/theme')">
								     			<a property="http://www.w3.org/ns/dcat#theme" resource="{./*/@xlink:href}" href="{./*/@xlink:href}" title="{$theme}" target="_blank">
								     				<img src="themes/{$THEME}/img/inspire/{substring-after(./*/@xlink:href, 'theme/')}.png"/>
								     			</a>
								     			<xsl:text> </xsl:text>
								     		</xsl:when>
								     		<xsl:when test="./*/@xlink:href">
								     			<div>
								     				<a property="http://www.w3.org/ns/dcat#theme" resource="{./*/@xlink:href}" href="{./*/@xlink:href}" title="registry" target="_blank">
								     					<xsl:choose>
								     						<xsl:when test="normalize-space($theme)">
								     							<xsl:value-of select="$theme"/>
								     						</xsl:when>
								     						<xsl:otherwise>
								     							<xsl:value-of select="./*/@xlink:href"/>
								     						</xsl:otherwise>
								     					</xsl:choose>
								     				</a>
								     			</div>	
								     		</xsl:when>
								     		<xsl:otherwise>
								     			<div rel="http://www.w3.org/ns/dcat#theme" typeof="http://www.w3.org/2000/01/rdf-schema#Resource">
								     				<span property="http://www.w3.org/2004/02/skos/core#prefLabel"><xsl:value-of select="$theme"/></span>
													<span rel="http://www.w3.org/2004/02/skos/core#inScheme" typeof="http://www.w3.org/2004/02/skos/core#ConceptScheme">
														<span content="{$thesaurus}" property="http://purl.org/dc/terms/title"></span>
														<span content="{../../*/gmd:thesaurusName/*/gmd:date/*/gmd:date/*}" property="http://purl.org/dc/terms/issued"></span>
													</span>
								     			</div>	
								     		</xsl:otherwise>
							     		</xsl:choose>
						  			</xsl:for-each>
						  		</div>
				  			</xsl:otherwise>
				  		</xsl:choose>
					</xsl:for-each>

					<xsl:for-each select="//gmd:descriptiveKeywords[string-length(*/gmd:thesaurusName/*/gmd:title/*)=0]">
						<div>
							<i><b><xsl:value-of select="$msg[@eng='Free']"/>: </b></i>
							<div style="margin-left:20px;">
							<xsl:for-each select="*/gmd:keyword">
					     		<xsl:variable name="theme">
						     		<xsl:call-template name="multi">
						    			<xsl:with-param name="el" select="."/>
						    			<xsl:with-param name="lang" select="$lang"/>
						    			<xsl:with-param name="mdlang" select="$mdlang"/>
						  			</xsl:call-template>
						  		</xsl:variable>							     	
					  			<xsl:choose>
						     		<xsl:when test="starts-with(*/@xlink:href, 'http://inspire.ec.europa.eu/theme')">
						     			<a href="{./*/@xlink:href}" title="{$theme}" target="_blank">
						     				<img src="themes/{$THEME}/img/inspire/{substring-after(./*/@xlink:href, 'theme/')}.png"/>
						     			</a>
						     			<xsl:text> </xsl:text>
						     		</xsl:when>
						     		<xsl:when test="./*/@xlink:href">
						     			<div>
						     				<a href="{./*/@xlink:href}" title="registry" target="_blank">
						     					<xsl:choose>
						     						<xsl:when test="normalize-space($theme)">
						     							<xsl:value-of select="$theme"/>
						     						</xsl:when>
						     						<xsl:otherwise>
						     							<xsl:value-of select="./*/@xlink:href"/>
						     						</xsl:otherwise>
						     					</xsl:choose>
						     				</a>
						     			</div>	
						     		</xsl:when>
						     		<xsl:otherwise>
						     			<div>
						     				<xsl:value-of select="$theme"/>
						     			</div>	
						     		</xsl:otherwise>
					     		</xsl:choose>
					  		</xsl:for-each>
					  		</div>
					  	</div>
					</xsl:for-each>


				</div>
			</div>

		<div class="row">
			<label><xsl:value-of select="$msg[@eng='Bounding box']"/></label>
			<div class="c" rel="http://purl.org/dc/terms/spatial">

				<xsl:for-each select="gmd:identificationInfo//gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox">
				    <xsl:variable name="x1" select="gmd:westBoundLongitude/*"/>
					<xsl:variable name="y1" select="gmd:southBoundLatitude/*"/>
					<xsl:variable name="x2" select="gmd:eastBoundLongitude/*"/>
					<xsl:variable name="y2" select="gmd:northBoundLatitude/*"/>
				
				
					<xsl:if test="gmd:westBoundLongitude!=''">
						<span typeof="http://www.w3.org/2000/01/rdf-schema#Resource" property="http://www.w3.org/ns/locn#geometry" datatype="http://www.opengis.net/ont/geosparql#wktLiteral" content="POLYGON(({$x1} {$y1} {$x1} {$y2} {$x2} {$y2} {$x2} {$y1} {$x1} {$y1}"></span>
						<div id="r-1" itemscope="itemscope" itemtype="http://schema.org/GeoShape">
							<meta itemprop="box" id="i-1" content="{gmd:westBoundLongitude} {gmd:southBoundLatitude} {gmd:eastBoundLongitude} {gmd:northBoundLatitude}"/>
							<xsl:value-of select="gmd:westBoundLongitude/*"/>,
							<xsl:value-of select="gmd:southBoundLatitude/*"/>,
							<xsl:value-of select="gmd:eastBoundLongitude/*"/>,
							<xsl:value-of select="gmd:northBoundLatitude/*"/>
							<br/>
			                <!-- 
			                <xsl:variable name="extImage" select="php:function('drawMapExtent', 250, string(gmd:westBoundLongitude), string(gmd:southBoundLatitude), string(gmd:eastBoundLongitude), string(gmd:northBoundLatitude))"/>
			                <xsl:if test="$extImage!=''">
			                   <img class="bbox" src="{$extImage}"/>
			                </xsl:if> -->
		                </div>
	                </xsl:if>					
				</xsl:for-each>
				<div id="overmap" style="width:7.6cm !important; height: 6cm !important;"></div>
       		</div>
		</div>


		<div class="row">
			<label><xsl:value-of select="$msg[@eng='Date']"/></label>
			<div class="c">
				<xsl:for-each select="gmd:identificationInfo/*/gmd:citation/*/gmd:date">
					<xsl:variable name="k" select="*/gmd:dateType/*/@codeListValue"/>
					<span property="http://purl.org/dc/terms/{$cl/dateType/value[@name=$k]/@dc}" content="{*/gmd:date}" datatype="http://www.w3.org/2001/XMLSchema#date">
						<xsl:value-of select="$cl/dateType/value[@name=$k]"/>: <xsl:value-of select="*/gmd:date"/>
					</span>
					<xsl:if test="not(position()=last())">, </xsl:if>
				</xsl:for-each>
			</div>
		</div>


		<xsl:if test="gmd:identificationInfo//gmd:temporalElement">
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Temporal extent']"/></label>
				<div class="c">
					<xsl:for-each select="gmd:identificationInfo//gmd:temporalElement">	
						<div rel="http://purl.org/dc/terms/temporal">
							<xsl:choose>
							<!-- rozsah 1 --> 
							<xsl:when test="string-length(*/gmd:extent/*/gml:beginPosition|*/gmd:extent/*/gml32:beginPosition)>0">
								<div typeof="http://purl.org/dc/terms/PeriodOfTime">
									<span property="http://schema.org/startDate" content="{*//gml:beginPosition|*//gml32:beginPosition}" datatype="http://www.w3.org/2001/XMLSchema#date"></span>
									<span property="http://schema.org/endDate" content="{*//gml:endPosition|*//gml32:endPosition}" datatype="http://www.w3.org/2001/XMLSchema#date"></span>
									<xsl:choose>
										<xsl:when test="*//gml:endPosition|*//gml32:endPosition=9999">
											<xsl:value-of select="$msg[@eng='from']"/><xsl:text> </xsl:text><xsl:value-of select="php:function('drawDate', string(*//gml:beginPosition|*//gml32:beginPosition), $lang)"/>
										</xsl:when>
										<xsl:when test="*//gml:beginPosition|*//gml32:beginPosition=0001">
											<xsl:value-of select="$msg[@eng='to']"/><xsl:text> </xsl:text><xsl:value-of select="php:function('drawDate', string(*//gml:endPosition|*//gml32:endPosition), $lang)"/>								
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="php:function('drawDate', string(*//gml:beginPosition|*//gml32:beginPosition), $lang)"/>
												-
											<xsl:value-of select="php:function('drawDate', string(*//gml:endPosition|*//gml32:endPosition), $lang)"/>
										</xsl:otherwise>
									</xsl:choose>
									</div>
							</xsl:when>
							
							<!-- rozsah 2 stary -->
							<xsl:when test="string-length(*//gml:begin)>0">
								<xsl:value-of select="php:function('drawDate', string(*//gml:begin), $lang)"/> -
		      					<xsl:value-of select="php:function('drawDate', string(*//gml:end), $lang)"/>
							</xsl:when>
							
							<!-- instant -->
							<xsl:when test="string-length(*//gml:timePosition|*//gml32:timePosition)>0">
								<xsl:value-of select="php:function('drawDate', string(*//gml:timePosition|*//gml32:timePosition), $lang)"/>
							</xsl:when>
						</xsl:choose>
						<xsl:if test="not(position()=last())">, </xsl:if>
						</div>
					</xsl:for-each>
				</div>
			</div>
		</xsl:if>
		
		<xsl:if test="//gmd:spatialRepresentationType">
			<div class="row">
				<label>
					<xsl:value-of select="$msg[@eng='Spatial Representation']"/>
				</label>
				<div class="c">
					<xsl:for-each select="//gmd:spatialRepresentationType">
						<xsl:variable name="sr" select="gmd:MD_SpatialRepresentationTypeCode"/>
						<xsl:value-of select="$cl/spatialRepresentationType/value[@name=$sr]"/>
						<xsl:if test="not(position()=last())">, </xsl:if>
					</xsl:for-each>
				</div>
			</div>
		</xsl:if>

		<div class="row">
			<label><xsl:value-of select="$msg[@eng='Contact Info']"/></label>
			<div class="c">
				<xsl:for-each select="gmd:identificationInfo/*/gmd:pointOfContact">
					<div rel="http://www.w3.org/ns/dcat#contactPoint">
						<xsl:apply-templates select="*"/>
						<xsl:if test="position()!=last()"><div style="margin-top:8px"></div></xsl:if>
					</div>
				</xsl:for-each>
			</div>
		</div>


	</div>


	
	<h3><xsl:value-of select="$msg[@eng='Data Quality']"/></h3>

		<div class="row">

		<xsl:if test="$srv!=1">
			<div class="row" rel="http://purl.org/dc/terms/provenance" typeof="http://purl.org/dc/terms/ProvenanceStatement">
				<label>
					<xsl:value-of select="$msg[@eng='Lineage']"/>
				</label>
				<div class="c" property="http://www.w3.org/2000/01/rdf-schema#label">
					<xsl:variable name="sr" select="gmd:dataQualityInfo/*/gmd:lineage/*/gmd:statement"/>
					<xsl:call-template name="multi">
						<xsl:with-param name="el" select="gmd:dataQualityInfo/*/gmd:lineage/*/gmd:statement"/>
						<xsl:with-param name="lang" select="$lang"/>
						<xsl:with-param name="mdlang" select="$mdlang"/>
					</xsl:call-template>					
				</div>
			</div>

			<xsl:if test="gmd:dataQualityInfo/*/gmd:lineage/*/gmd:source">
				<div class="row">
					<label><xsl:value-of select="$msg[@eng='Sources']"/></label>
					<div class="c">
						<xsl:for-each select="gmd:dataQualityInfo/*/gmd:lineage/*/gmd:source">
							<xsl:variable name="md" select="php:function('getData', string(*/gmd:sourceCitation/@xlink:href))"/>
	  						<xsl:variable name="url">
					            <xsl:choose>
					  				<xsl:when test="$REWRITE">	
					  					<xsl:value-of select="concat('records/',$md//gmd:fileIdentifier)"/>
					  				</xsl:when>
					  				<xsl:otherwise>
					                	<xsl:value-of select="concat('?ak=detail&amp;uuid=',$md//gmd:fileIdentifier)"/>
					  				</xsl:otherwise>
					  			</xsl:choose>
				            </xsl:variable>
							
							<div>
								<a href="{$url}">				
									<xsl:call-template name="multi">
										<xsl:with-param name="el" select="$md//gmd:title"/>
										<xsl:with-param name="lang" select="$lang"/>
										<xsl:with-param name="mdlang" select="$mdlang"/>
									</xsl:call-template>
								</a>
							</div>
						</xsl:for-each>
					</div>
				</div>	
			</xsl:if>

			<div class="row">
			<label><xsl:value-of select="$msg[@eng='Spatial Resolution']"/></label>
			<div class="c">
				<xsl:if test="gmd:identificationInfo/*/gmd:spatialResolution/*/gmd:equivalentScale/*/gmd:denominator!=''">
					<xsl:value-of select="$msg[@eng='Equivalent Scale']"/> =
  					<xsl:text> 1:</xsl:text>
					<xsl:value-of select="gmd:identificationInfo/*/gmd:spatialResolution/*/gmd:equivalentScale/*/gmd:denominator"/>
				</xsl:if>
				<xsl:if test="gmd:identificationInfo/*/gmd:spatialResolution/gmd:MD_Resolution/gmd:distance">
					<xsl:value-of select="$msg[@eng='Distance']"/> =
 					 <xsl:value-of select="gmd:identificationInfo/*/gmd:spatialResolution/gmd:MD_Resolution/gmd:distance/gco:Distance"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="gmd:identificationInfo/*/gmd:spatialResolution/gmd:MD_Resolution/gmd:distance/gco:Distance/@uom"/>
				</xsl:if>
			</div>
			</div>

		</xsl:if>
		<xsl:for-each select="gmd:dataQualityInfo/*/gmd:report[gmd:DQ_DomainConsistency]">
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Conformity']"/></label>
				<div class="c">
					<xsl:for-each select="*/gmd:result">
						<xsl:call-template name="multi">
							<xsl:with-param name="el" select="*/gmd:specification/*/gmd:title"/>
							<xsl:with-param name="lang" select="$lang"/>
							<xsl:with-param name="mdlang" select="$mdlang"/>
						</xsl:call-template>
						<hr/>
						<xsl:variable name="k" select="*/gmd:pass"/>
						<b><xsl:value-of select="$cl/compliant/value[@name=$k]"/></b>
					</xsl:for-each>
				</div>
			</div>
		</xsl:for-each>
	</div>


	
	<h3><xsl:value-of select="$msg[@eng='Constraints']"/></h3>

		<div class="row">
			<label><xsl:value-of select="$msg[@eng='Use Limitation']"/></label>
			<div class="c">
				<xsl:for-each select="gmd:identificationInfo/*/gmd:resourceConstraints">
					<xsl:for-each select="*/gmd:useLimitation">
						<xsl:choose>
							<xsl:when test="contains(gmx:Anchor/@xlink:href,'://creativecommons.org')">
								<xsl:variable name="licence" select="substring-after(gmx:Anchor/@xlink:href,'creativecommons.org/licenses/')"/>							
								<a href="{gmx:Anchor/@xlink:href}" target="_blank">
									<img src="http://licensebuttons.net/l/{$licence}/88x31.png"/><br/>
									<xsl:call-template name="multi">
										<xsl:with-param name="el" select="."/>
										<xsl:with-param name="lang" select="$lang"/>
										<xsl:with-param name="mdlang" select="$mdlang"/>
									</xsl:call-template>
								</a>
							</xsl:when>
							<xsl:otherwise>
							<div>
								<xsl:call-template name="multi">
									<xsl:with-param name="el" select="."/>
									<xsl:with-param name="lang" select="$lang"/>
									<xsl:with-param name="mdlang" select="$mdlang"/>
								</xsl:call-template>
							</div>
						</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:for-each>
			</div>
		</div>

		<div class="row">
			<label><xsl:value-of select="$msg[@eng='Access Constraints']"/></label>
			<div class="c">
				<xsl:for-each select="gmd:identificationInfo/*/gmd:resourceConstraints">
					<xsl:for-each select="*/gmd:accessConstraints">
						<xsl:variable name="kod" select="*/@codeListValue"/>
						<div><xsl:value-of select="$cl/accessConstraints/value[@name=$kod]"/></div>
					</xsl:for-each>
					<xsl:for-each select="*/gmd:otherConstraints">
						<div>
							<xsl:call-template name="multi">
								<xsl:with-param name="el" select="."/>
								<xsl:with-param name="lang" select="$lang"/>
								<xsl:with-param name="mdlang" select="$mdlang"/>
							</xsl:call-template>
						</div>
					</xsl:for-each>
				</xsl:for-each>
			</div>
		</div>	
	

	
	<!-- metadata -->
	<h3><xsl:value-of name="str" select="$msg[@eng='Metadata Metadata']"/></h3>
		<div rel="http://xmlns.com/foaf/0.1/isPrimaryTopicOf" typeof="http://www.w3.org/2000/01/rdf-schema#Resource">
			 <div class="row">	
				<label><xsl:value-of select="$msg[@eng='MDIdentifier']"/></label>
				<div class="c"><xsl:value-of select="gmd:fileIdentifier"/></div>
			</div>
			<xsl:if test="gmd:parentIdentifier!=''">
				<xsl:variable name="pilink" select="php:function('getMetadata', concat('identifier=', $apos, gmd:parentIdentifier/*, $apos))"/>
				<div class="row">
					<label><xsl:value-of select="$msg[@eng='Parent Identifier']"/></label>
					<div class="c">
						<xsl:value-of select="gmd:parentIdentifier"/>
					</div>
				</div>
			</xsl:if>
			 <div class="row">
				<label><xsl:value-of select="$msg[@eng='Metadata Contact']"/></label>
				<div class="c">
					<xsl:for-each select="gmd:contact">
						<div  rel="http://www.w3.org/ns/dcat#contactPoint">
							<xsl:apply-templates select="*"/>
							<xsl:if test="position()!=last()"><div style="margin-top:8px"></div></xsl:if>
						</div>
					</xsl:for-each>
				</div>
			</div> 
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Date Stamp']"/></label>
				<div class="c" rel="http://purl.org/dc/terms/modified" resource="{gmd:dateStamp/*}"><xsl:value-of select="php:function('drawDate', string(gmd:dateStamp/*), $lang)"/></div>
			</div>

			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Language']"/></label>
				<div class="c" rel="http://purl.org/dc/terms/language" resource="http://publications.europa.eu/resource/authority/language/{translate($lang,$lower,$upper)}"><xsl:value-of select="$cl/language/value[@code=$lang]"/></div>
			</div>
		</div>
	
	<h3><xsl:value-of select="$msg[@eng='Coupled Resource']"/></h3>




		<!-- ===VAZBY=== -->
		
		<!-- sluzby -->
		<xsl:variable name="vazby" select="php:function('getMetadata', concat('uuidRef=',gmd:fileIdentifier/*))"/>
		<div class="row">
			<label><xsl:value-of select="$msg[@eng='Used']"/></label>
			<div class="c">
				<xsl:for-each select="$vazby//gmd:MD_Metadata">
	                <xsl:variable name="url">
	                    <xsl:choose>
							<xsl:when test="$REWRITE">	
								<xsl:value-of select="concat('page/',gmd:fileIdentifier)"/>
							</xsl:when>
							<xsl:otherwise>
	                        	<xsl:value-of select="concat('?ak=detail&amp;uuid=',gmd:fileIdentifier)"/>
							</xsl:otherwise>
						</xsl:choose>
	                </xsl:variable>
	
					<div><a href="{$url}" class="t {gmd:hierarchyLevel/*/@codeListValue}" title="{$cl/updateScope/value[@name=$vazby[position()]//gmd:hierarchyLevel/*/@codeListValue]}">
						<!-- <xsl:value-of select="gmd:identificationInfo/*/gmd:citation/*/gmd:title/*"/> -->
						<xsl:call-template name="multi">
							<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
							<xsl:with-param name="lang" select="$lang"/>
							<xsl:with-param name="mdlang" select="$mdlang"/>
						</xsl:call-template>
					</a></div>
				</xsl:for-each>	
			</div>
		</div>	
		
		<!-- parent -->
		<xsl:if test="gmd:parentIdentifier!=''">
			<xsl:variable name="pilink" select="php:function('getMetadata', concat('identifier=', $apos, gmd:parentIdentifier/*, $apos))"/>
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Parent']"/></label>
				<div class="c">
					<xsl:variable name="a" select="$pilink//gmd:hierarchyLevel/*/@codeListValue"/>
	                <xsl:variable name="url">
	                    <xsl:choose>
							<xsl:when test="$REWRITE">	
								<xsl:value-of select="concat('page/',$pilink//gmd:fileIdentifier)"/>
							</xsl:when>
							<xsl:otherwise>
	                        	<xsl:value-of select="concat('?ak=xml&amp;uuid=',$pilink//gmd:fileIdentifier)"/>
							</xsl:otherwise>
						</xsl:choose>
	                </xsl:variable>

					<a class="t {$a}" href="{$url}" title="{$cl/updateScope/value[@name=$a]}">
						<!-- <xsl:value-of select="$pilink//gmd:identificationInfo/*/gmd:citation/*/gmd:title/*"/> -->
						<xsl:call-template name="multi">
							<xsl:with-param name="el" select="$pilink//gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
							<xsl:with-param name="lang" select="$lang"/>
							<xsl:with-param name="mdlang" select="$mdlang"/>
						</xsl:call-template>
					</a>
				</div>
			</div>
		</xsl:if>
		
		<!-- podrizene -->
		<xsl:variable name="subsets" select="php:function('getMetadata', concat('ParentIdentifier=', $apos, gmd:fileIdentifier/*, $apos))"/>		
		<xsl:if test="$subsets//gmd:MD_Metadata">
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Children']"/></label>
				<div class="c">
					<xsl:for-each select="$subsets//gmd:MD_Metadata">
						<xsl:variable name="a" select="gmd:hierarchyLevel/*/@codeListValue"/>
  						<xsl:variable name="url">
				            <xsl:choose>
				  				<xsl:when test="$REWRITE">	
				  					<xsl:value-of select="concat('page/',gmd:fileIdentifier)"/>
				  				</xsl:when>
				  				<xsl:otherwise>
				                	<xsl:value-of select="concat('?ak=detail&amp;uuid=',gmd:fileIdentifier)"/>
				  				</xsl:otherwise>
				  			</xsl:choose>
			            </xsl:variable>

						<div><a href="{$url}" class="t {$a}" title="{$cl/updateScope/value[@name=$a]}">
							<!-- <xsl:value-of select="gmd:identificationInfo/*/gmd:citation/*/gmd:title/*"/>-->
							<xsl:call-template name="multi">
								<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
								<xsl:with-param name="lang" select="$lang"/>
								<xsl:with-param name="mdlang" select="$mdlang"/>
							</xsl:call-template>							 
						</a></div>
					</xsl:for-each>
					<xsl:if test="$subsets//csw:SearchResults/@numberOfRecordsMatched &gt; 25">
						<div>
							<a href="?request=GetRecords&amp;format=text/html&amp;language={$lang}&amp;query=parentIdentifier={gmd:fileIdentifier/*}">See all <xsl:value-of select="$subsets//csw:SearchResults/@numberOfRecordsMatched"/> children ...</a>
						</div>
					</xsl:if>
				</div>
			</div>	
		</xsl:if>
		
		<!-- sourozenci -->
		<xsl:if test="gmd:parentIdentifier!=''">
			<xsl:variable name="siblinks" select="php:function('getMetadata', concat('ParentIdentifier=',$apos, gmd:parentIdentifier/*,$apos))"/>
			<xsl:if test="count($siblinks) &gt; 1">
				<xsl:variable name="myid" select="gmd:fileIdentifier/*"/>
				<div class="row">
					<label><xsl:value-of select="$msg[@eng='Siblinks']"/></label>
					<div class="c">
						<xsl:for-each select="$siblinks//gmd:MD_Metadata[gmd:fileIdentifier/*!=$myid]">
							<xsl:variable name="a" select="gmd:hierarchyLevel/*/@codeListValue"/>
							<xsl:variable name="url">
                				<xsl:choose>
    					  			<xsl:when test="$REWRITE">	
    									<xsl:value-of select="concat('page/',gmd:fileIdentifier)"/>
    								</xsl:when>
    					   			<xsl:otherwise>
                  						<xsl:value-of select="concat('?ak=detail&amp;uuid=',gmd:fileIdentifier)"/>
    					   			</xsl:otherwise>
    				    		</xsl:choose>
              				</xsl:variable>

							<div><a href="{$url}" class="t {$a}"  title="{$cl/updateScope/value[@name=$a]}">
								<!-- <xsl:value-of select="gmd:identificationInfo/*/gmd:citation/*/gmd:title/*"/> -->
								<xsl:call-template name="multi">
									<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
									<xsl:with-param name="lang" select="$lang"/>
									<xsl:with-param name="mdlang" select="$mdlang"/>
								</xsl:call-template>							 
							</a></div>
					</xsl:for-each>
				</div></div>
			</xsl:if>
		</xsl:if>

		<!-- 1.6 sluzby - operatesOn NOVA VERZE -->
		<xsl:if test="gmd:identificationInfo/srv:SV_ServiceIdentification">
			<div class="row">
				<label><xsl:value-of select="$msg[@eng='Use']"/></label>
				<div class="c">
					 <xsl:for-each select="gmd:identificationInfo/*/srv:operatesOn">
						<!--xsl:variable name="siblinks" select="php:function('getMetadata', concat('identifier=',$opid))"/-->
						<xsl:variable name="siblinks" select="php:function('getData', string(@xlink:href))"/>
						<xsl:for-each select="$siblinks//gmd:MD_Metadata">
							<xsl:variable name="a" select="gmd:hierarchyLevel/*/@codeListValue"/>
							<xsl:variable name="url">
					        	<xsl:choose>
					    			<xsl:when test="$REWRITE">	
					    				<xsl:value-of select="concat('page/',normalize-space(gmd:fileIdentifier))"/>
					    			</xsl:when>
					    			<xsl:otherwise>
					            	  	<xsl:value-of select="concat('?ak=detail&amp;uuid=',normalize-space(gmd:fileIdentifier))"/>
					    			</xsl:otherwise>
					    		</xsl:choose>
					        </xsl:variable>

							<div><a href="{$url}" class="t {$a}"  title="{$cl/updateScope/value[@name=$a]}">
									<xsl:call-template name="multi">
										<xsl:with-param name="el" select="gmd:identificationInfo/*/gmd:citation/*/gmd:title"/>
										<xsl:with-param name="lang" select="$lang"/>
										<xsl:with-param name="mdlang" select="$mdlang"/>
									</xsl:call-template>							 
								</a></div>
						</xsl:for-each>
					</xsl:for-each>
				</div>	
			</div>
		</xsl:if>

		<!-- Citace FC -->
		<xsl:for-each select="gmd:contentInfo/gmd:MD_FeatureCatalogueDescription">
			<div class="row">
				<label>
					<xsl:value-of select="$msg[@eng='Feature catalogue']"/>
				</label>
				<div class="c">
					<!-- <xsl:value-of select="gmd:featureCatalogueCitation/*/gmd:title"/> -->
					<xsl:call-template name="multi">
						<xsl:with-param name="el" select="gmd:featureCatalogueCitation/*/gmd:title"/>
						<xsl:with-param name="lang" select="$lang"/>
						<xsl:with-param name="mdlang" select="$mdlang"/>
					</xsl:call-template>							 

					<xsl:variable name="url">
						<xsl:if test="gmd:featureCatalogueCitation/*/gmd:identifier">
							<xsl:choose>
								<xsl:when test="$REWRITE">	
									<xsl:value-of select="concat( 'records/', gmd:featureCatalogueCitation/*/gmd:identifier, '?language=', $lang)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="concat( '?ak=detailall&amp;uuid=', gmd:featureCatalogueCitation/*/gmd:identifier, '&amp;language=', $lang)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:variable>

					<xsl:if test="gmd:featureCatalogueCitation/*/gmd:identifier"> 
						[<a href="{$url}"><xsl:value-of select="gmd:featureCatalogueCitation/*/gmd:identifier"/></a>]
					</xsl:if>
					
					<xsl:for-each select="gmd:featureTypes">
						<div>
						  	<xsl:choose>
  						  		<xsl:when test="$url">
  							   		<a href="{$url}#{*}" class="t fc"><xsl:value-of select="*"/></a>
  								</xsl:when>
  								<xsl:otherwise>
  							   		<a class="t fc"><xsl:value-of select="*"/></a>
  								</xsl:otherwise>
              				</xsl:choose>   
						</div>						
					</xsl:for-each>
				</div>
			</div>
		</xsl:for-each>		

	</xsl:template>
	
	<!-- Zpracovani DC -->
	<xsl:template match="csw:Record" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dct="http://purl.org/dc/terms/">
		<h1>
		<div class="cat-{translate(dc:type,$upper,$lower)}">
			<xsl:value-of select="dc:title"/>
			<xsl:for-each select="dc:identifier">
				<xsl:if test="substring(.,1,4)='http'">
					<div style="float:right; font-size:13px;">
						<a class="open" href="{.}" target="_blank">
							<xsl:value-of select="$msg/open"/>
						</a>
					</div>
				</xsl:if>
			</xsl:for-each>
		</div>
		</h1>
		<h2>
			Dublin Core metadata
			<div class="detail icons">
				<xsl:if test="../@edit=1">
					<a href="?ak=edit&amp;recno={../@recno}" class="edit" title="{$msg[@eng='edit']}"> </a>				
					<a href="?ak=copy&amp;recno={../@recno}" class="copy" title="{$msg[@eng='clone']}"> </a>				
					<a href="javascript:md_delrec({../@recno});" class="delete" title="{$msg[@eng='delete']}"> </a>				
				</xsl:if>
				<a href="?ak=xml&amp;uuid={../@uuid}" class="xml" target="_blank" title="XML"> </a>
			</div>
			<xsl:value-of select="$msg[@eng='basic']"/>
		</h2>
		

			<xsl:for-each select="*">
				<!-- TODO dodelat vzhled -->
				<div class="row">
					<div class="subtitle">
						<xsl:variable name="itemName" select="substring-after(name(),':')"/>
						<xsl:value-of select="$msg[translate(@eng,$upper,$lower)=$itemName]"/>
					</div>
					<div>
						<xsl:choose>
							<xsl:when test="substring(.,1,4)='http'">
								<a href="{.}" target="_blank">
									<xsl:value-of select="."/>
								</a>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="."/>
							</xsl:otherwise>
						</xsl:choose>
					</div>
				</div>
			</xsl:for-each>
			<xsl:for-each select="ows:BoundingBox">
				<div class="row">
					<div>
						<div id="extMap" style="position:relative"/>
						<span class="geo">
							<xsl:value-of select="$msg[@eng=west]"/>:
      							<span id="westBoundLongitude" class="longitude">
								<xsl:value-of select="substring-before(ows:LowerCorner,' ')"/>
							</span>,
      <xsl:value-of select="$msg/south"/>:
      <span id="southBoundLatitude" class="latitude">
								<xsl:value-of select="substring-after(ows:LowerCorner,' ')"/>
							</span>,
    </span>
						<span class="geo">
							<xsl:value-of select="$msg/east"/>:
      <span id="eastBoundLongitude" class="longitude">
								<xsl:value-of select="substring-before(ows:UpperCorner,' ')"/>
							</span>,
      <xsl:value-of select="$msg/north"/>:
      <span id="northBoundLatitude" class="latitude">
								<xsl:value-of select="substring-after(ows:UpperCorner,' ')"/>
							</span>
						</span>
					</div>
				</div>
			</xsl:for-each>

	</xsl:template>


	<!-- pro kontakty -->
	<xsl:template match="gmd:CI_ResponsibleParty">
		<div typeof="http://www.w3.org/2000/01/rdf-schema#Resource">
			<xsl:if test="gmd:organisationName">
				<div property="http://www.w3.org/2006/vcard/ns#fn">
					<xsl:call-template name="multi">
						<xsl:with-param name="el" select="gmd:organisationName"/>
						<xsl:with-param name="lang" select="$lang"/>
						<xsl:with-param name="mdlang" select="$mdlang"/>
					</xsl:call-template>
				</div>
			</xsl:if>
			<xsl:if test="gmd:individualName">
				<xsl:call-template name="multi">
					<xsl:with-param name="el" select="gmd:individualName"/>
					<xsl:with-param name="lang" select="$lang"/>
					<xsl:with-param name="mdlang" select="$mdlang"/>
				</xsl:call-template>
			</xsl:if>
			<div rel="http://www.w3.org/2006/vcard/ns#hasAddress" vocab="http://www.w3.org/2006/vcard/ns#" typeof="http://www.w3.org/2006/vcard/ns#Address" >
				<xsl:if test="gmd:contactInfo/*/gmd:address/*/gmd:deliveryPoint">
					<span property="street-address"><xsl:value-of select="gmd:contactInfo/*/gmd:address/*/gmd:deliveryPoint"/></span>,
				</xsl:if>
				<xsl:if test="gmd:contactInfo/*/gmd:address/*/gmd:city">
					<span property="locality"><xsl:value-of select="gmd:contactInfo/*/gmd:address/*/gmd:city"/></span> 
				</xsl:if>
				<xsl:if test="gmd:contactInfo/*/gmd:address/*/gmd:postalCode">,
					<span property="postal-code"><xsl:value-of select="gmd:contactInfo/*/gmd:address/*/gmd:postalCode"/></span>
				</xsl:if>
				<xsl:if test="gmd:contactInfo/*/gmd:address/*/gmd:country">, 
					<span property="country-name"><xsl:value-of select="gmd:contactInfo/*/gmd:address/*/gmd:country"/></span>
				</xsl:if>		
			</div>
			<xsl:for-each select="gmd:contactInfo/*/gmd:onlineResource[*/gmd:linkage/gmd:URL!='']">
				<div rel="http://www.w3.org/2006/vcard/ns#hasURL"><a href="{*/gmd:linkage}" resource="{*/gmd:linkage}" target="_blank"><xsl:value-of select="*/gmd:linkage"/></a></div>
			</xsl:for-each>
			<xsl:for-each select="gmd:contactInfo/*/gmd:phone/*/gmd:voice">
				<div>tel: <xsl:value-of select="."/></div>
			</xsl:for-each>
			<xsl:for-each select="gmd:contactInfo/*/gmd:address/*/gmd:electronicMailAddress">
				<div rel="http://www.w3.org/2006/vcard/ns#hasEmail" resource="mailto:{.}">email: <xsl:value-of select="."/></div>
				</xsl:for-each>
			<xsl:variable name="kod" select="gmd:role/*/@codeListValue"/>
			 <xsl:value-of select="$msg[@eng='role']"/>: <b><xsl:value-of select="$cl/role/value[@name=$kod]"/></b>
		 </div> 
	</xsl:template>
	

</xsl:stylesheet>
