<?xml version="1.0" encoding="UTF-8"?>
<!--
-   Author George Gershevich
-   This file converts XML Schema Definition files to Russian Doll Patten.
-   
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<xsl:output method="xml" indent="no"/>

	<!-- target namespace -->
	<xsl:variable name="tns" select="/xs:schema/@targetNamespace"/>
	<!-- target namespace prefix -->
	<xsl:variable name="tnsp" select="name(//namespace::*[. = $tns])"/>

	<!-- special rule for the document element -->
	<xsl:template match="/*">
		<xsl:copy>
			<!-- copy attributes -->
			<xsl:copy-of select="@*"/>          
			<!-- Add a namespace node -->
			<!--<xsl:namespace name="mynamespace" select="'somenamespace'"/>-->
			<!-- processing starts here from the root element -->
			<!--<xsl:apply-templates select="//xs:element[@ref]" />-->
			<xsl:apply-templates select="@* | node()"/>
			<!--<xsl:apply-templates select="@* | node()"/>-->
		</xsl:copy>
	</xsl:template>

	<!-- resolve element reference template -->
	<xsl:template match="//xs:element[@ref]" name="replace-element-ref">
		<xsl:copy>

			<xsl:variable name="ref-name">
				<xsl:call-template name="remove-tnsp">
					<xsl:with-param name="param-text" select="@ref"/>
					<xsl:with-param name="param-tnsp" select="$tnsp" />
				</xsl:call-template>
			</xsl:variable>       

			<!-- copy all attributes but "ref" -->
			<xsl:copy-of select="@*[name() != 'ref']"/>
			<!-- copy all attributes from referenced element but "final" -->
			<xsl:copy-of select="/xs:schema/xs:element[@name = $ref-name]/@*[name() != 'final']"/>
			<!-- add attribute "form" (both refereed and reference element MUST (by spec) not contain it) -->
			<xsl:attribute name="form">qualified</xsl:attribute>

			<!-- copy children. (only xs:annotation must be) -->
			<xsl:call-template name="merge-annotations">
				<xsl:with-param name="param-element1" select="."/>
				<xsl:with-param name="param-element2" select="/xs:schema/xs:element[@name = $ref-name]"/>
			</xsl:call-template>


			<!-- copy referenced element childs except xs:annotation -->
			<xsl:apply-templates select="/xs:schema/xs:element[@name = $ref-name]/*[name() != 'xs:annotation']"/>

		</xsl:copy>
		<!--<xsl:apply-templates select="//xs:element[@ref]"/>-->
	</xsl:template>

	<!-- resolve attribute reference template -->
	<xsl:template match="//xs:attribute[@ref]" name="replace-attribute-ref">
		<xsl:copy>

			<xsl:variable name="ref-name">
				<xsl:call-template name="remove-tnsp">
					<xsl:with-param name="param-text" select="@ref"/>
					<xsl:with-param name="param-tnsp" select="$tnsp" />
				</xsl:call-template>
			</xsl:variable>

			<!-- copy all attributes but "ref" -->
			<xsl:copy-of select="@*[name()!='ref']"/>
			<!-- copy all attributes from referenced element -->
			<xsl:copy-of select="/xs:schema/xs:attribute[@name=$ref-name]/@*"/>
			<!-- add attribute "form" (both refereed and reference element MUST (by spec) not contain it) -->
			<xsl:attribute name="form">qualified</xsl:attribute>

			<!-- merge annotations -->
			<xsl:call-template name="merge-annotations">
				<xsl:with-param name="param-element1" select="."/>
				<xsl:with-param name="param-element2" select="/xs:schema/xs:attribute[@name=$ref-name]"/>
			</xsl:call-template>
			<!-- copy referenced element children except xs:annotation -->
			<xsl:apply-templates select="/xs:schema/xs:attribute[@name=$ref-name]/*[name() != 'xs:annotation']"/>

		</xsl:copy>
	</xsl:template>

	<!-- resolve element type template -->
	<xsl:template match="//xs:element[@type[starts-with(., $tnsp)]]" name="replace-element-type">
		<xsl:copy>

			<xsl:variable name="type-name">
				<xsl:call-template name="remove-tnsp">
					<xsl:with-param name="param-text" select="@type"/>
					<xsl:with-param name="param-tnsp" select="$tnsp" />
				</xsl:call-template>
			</xsl:variable>       

			<!-- copy all attributes but "type" -->
			<xsl:copy-of select="@*[name() != 'type']"/>

			<xsl:apply-templates select="/xs:schema/xs:complexType[@name = $type-name]/.">
				<xsl:with-param name="param-delete-name-from-complexType" select="."/>
			</xsl:apply-templates>

		</xsl:copy>

	</xsl:template>  

	<!-- the identity template -->
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>

	<!-- make sting like 'ns0:tratata' to 'tratata' -->
	<xsl:template name="remove-tnsp">
		<xsl:param name="param-text"/>
		<xsl:param name="param-tnsp"/>
		<xsl:variable name="tnspc" select="concat($param-tnsp, ':')" />
		<xsl:choose>
			<xsl:when test="contains($param-text, $tnspc)">
				<xsl:value-of select="substring-after($param-text, $tnspc)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$param-text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="merge-annotations">
		<xsl:param name="param-element1"/>
		<xsl:param name="param-element2"/>
		<xsl:variable name="element1-have-annotation" select="name($param-element1/xs:annotation)" />
		<xsl:variable name="element2-have-annotation" select="name($param-element2/xs:annotation)" />
		<xsl:if test="concat($element1-have-annotation, $element2-have-annotation)">
			<xsl:comment>annotation exist and must be merged, but it is not necessary right now</xsl:comment>
		</xsl:if>
	</xsl:template>

	<!-- This template copy complexType excluding attribute 'name'  -->
	<xsl:template match="/xs:schema/xs:complexType" name="copy-complexType">
		<xsl:param name="param-delete-name-from-complexType"/>	
		<xsl:if test="$param-delete-name-from-complexType">
			<xsl:copy>
				<xsl:apply-templates select="@*[name()!='name'] | node()"/>
			</xsl:copy>
		</xsl:if>	  
	</xsl:template>

</xsl:stylesheet>