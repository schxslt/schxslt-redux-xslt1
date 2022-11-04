<!--
Copyright (C) 2022 by David Maus <dmaus@dmaus.name>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->
<xsl:transform version="1.0"
               xmlns:alias="http://www.w3.org/1999/XSL/TransformAlias"
               xmlns:sch="http://purl.oclc.org/dsdl/schematron"
               xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output indent="yes"/>

  <xsl:namespace-alias stylesheet-prefix="alias" result-prefix="xsl"/>

  <xsl:param name="phase">#DEFAULT</xsl:param>

  <xsl:key name="patternByPhase" match="sch:pattern" use="../sch:phase[current()/@id = sch:active/@pattern]/@id"/>
  <xsl:key name="patternByPhase" match="sch:pattern" use="'#ALL'"/>

  <xsl:include href="shared.xsl"/>

  <xsl:template match="sch:schema">
    <xsl:variable name="queryBinding" select="translate(@queryBinding, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
    <xsl:if test="not($queryBinding = 'xslt') and not($queryBinding = '')">
      <xsl:variable name="message">
        This Schematron processor only supports the XSLT 1.0 query binding.
      </xsl:variable>
      <xsl:message terminate="yes">
        <xsl:text/>
        <xsl:value-of select="normalize-space($message)"/>
      </xsl:message>
    </xsl:if>

    <xsl:variable name="phase">
      <xsl:choose>
        <xsl:when test="($phase = '#DEFAULT') or ($phase = '')">
          <xsl:choose>
            <xsl:when test="@defaultPhase">
              <xsl:value-of select="@defaultPhase"/>
            </xsl:when>
            <xsl:otherwise>#ALL</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$phase"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="not($phase = '#ALL') and not(sch:phase[@id = $phase])">
      <xsl:variable name="message">
        The phase <xsl:value-of select="$phase"/> is not defined.
      </xsl:variable>
      <xsl:message terminate="yes">
        <xsl:text/>
        <xsl:value-of select="normalize-space($message)"/>
      </xsl:message>
    </xsl:if>

    <alias:transform version="1.0">
      <xsl:for-each select="sch:ns">
        <xsl:attribute name="{@prefix}:dummy" namespace="{@uri}"/>
      </xsl:for-each>

      <xsl:call-template name="declare-variables">
        <xsl:with-param name="variables" select="sch:let"/>
        <xsl:with-param name="declName" select="'param'"/>
      </xsl:call-template>

      <xsl:call-template name="declare-variables">
        <xsl:with-param name="variables" select="sch:phase[@id = $phase]/sch:let"/>
      </xsl:call-template>

      <xsl:call-template name="declare-variables">
        <xsl:with-param name="variables" select="key('patternByPhase', $phase)/sch:let"/>
      </xsl:call-template>

      <xsl:copy-of select="xsl:key[not(preceding-sibling::sch:pattern)]"/>

      <alias:template match="/">
        <svrl:schematron-output>
          <xsl:for-each select="key('patternByPhase', $phase)">
            <alias:call-template name="{generate-id()}"/>
          </xsl:for-each>
        </svrl:schematron-output>
      </alias:template>

      <xsl:apply-templates select="key('patternByPhase', $phase)"/>

      <xsl:apply-templates select="document('location.xsl')/xsl:transform/xsl:template" mode="copy-location-function"/>

    </alias:transform>

  </xsl:template>

  <xsl:template match="sch:pattern">

    <alias:template name="{generate-id()}">
      <svrl:active-pattern>
        <xsl:copy-of select="@id"/>
        <xsl:if test="@documents">
          <alias:attribute name="documents">
            <alias:for-each select="{@documents}">
              <alias:if test="position() > 1">
                <alias:value-of select="' '"/>
              </alias:if>
              <alias:value-of select="."/>
            </alias:for-each>
          </alias:attribute>
        </xsl:if>
      </svrl:active-pattern>

      <xsl:choose>
        <xsl:when test="@documents">
          <alias:for-each select="{@documents}">
            <alias:apply-templates select="document(normalize-space())" mode="{generate-id()}">
              <alias:with-param name="document-uri" select="."/>
            </alias:apply-templates>
          </alias:for-each>
        </xsl:when>
        <xsl:otherwise>
          <alias:apply-templates select="." mode="{generate-id()}"/>
        </xsl:otherwise>
      </xsl:choose>
    </alias:template>

    <xsl:apply-templates select="sch:rule"/>

    <alias:template match="*" mode="{generate-id()}" priority="-10">
      <alias:param name="document-uri"/>
      <alias:apply-templates mode="{generate-id()}" select="@*"/>
      <alias:apply-templates mode="{generate-id()}" select="node()">
        <alias:with-param name="document-uri" select="$document-uri"/>
      </alias:apply-templates>
    </alias:template>

  </xsl:template>

  <xsl:template match="sch:rule">
    <alias:template match="{@context}" mode="{generate-id(..)}" priority="{count(following-sibling::sch:rule)}">
      <alias:param name="document-uri"/>

      <svrl:fired-rule>
        <xsl:copy-of select="@id"/>
        <xsl:copy-of select="@role"/>
        <xsl:copy-of select="@flag"/>
        <xsl:copy-of select="@context"/>
        <alias:if test="$document-uri != ''">
          <alias:attribute name="document">
            <alias:value-of select="$document-uri"/>
          </alias:attribute>
        </alias:if>
      </svrl:fired-rule>

      <xsl:call-template name="declare-variables">
        <xsl:with-param name="variables" select="sch:let"/>
      </xsl:call-template>
      <xsl:apply-templates select="sch:assert | sch:report"/>
    </alias:template>
  </xsl:template>

  <xsl:template match="sch:assert">
    <alias:if test="not({@test})">
      <svrl:failed-assert>
        <xsl:copy-of select="@flag"/>
        <xsl:copy-of select="@id"/>
        <xsl:copy-of select="@role"/>
        <xsl:copy-of select="@test"/>
        <xsl:attribute name="xml:lang">
          <xsl:call-template name="in-scope-language"/>
        </xsl:attribute>
        <alias:attribute name="location">
          <alias:call-template name="location"/>
        </alias:attribute>
        <xsl:call-template name="report"/>
      </svrl:failed-assert>
    </alias:if>
  </xsl:template>

  <xsl:template match="sch:report">
    <alias:if test="{@test}">
      <svrl:successful-report>
                <xsl:copy-of select="@flag"/>
        <xsl:copy-of select="@id"/>
        <xsl:copy-of select="@role"/>
        <xsl:copy-of select="@test"/>
        <xsl:attribute name="xml:lang">
          <xsl:call-template name="in-scope-language"/>
        </xsl:attribute>
        <alias:attribute name="location">
          <alias:call-template name="location"/>
        </alias:attribute>
        <xsl:call-template name="report"/>
      </svrl:successful-report>
    </alias:if>
  </xsl:template>

  <xsl:template name="report">
    <xsl:if test="@diagnostics">
      <xsl:call-template name="report-diagnostics"/>
    </xsl:if>
    <xsl:if test="@properties">
      <xsl:call-template name="report-properties"/>
    </xsl:if>
    <xsl:if test="text() | *">
      <svrl:text>
        <xsl:copy-of select="@xml:*"/>
        <xsl:apply-templates select="node()" mode="message-content"/>
      </svrl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="report-diagnostics">
    <xsl:param name="ids" select="normalize-space(@diagnostics)"/>
    <xsl:variable name="id">
      <xsl:choose>
        <xsl:when test="contains($ids, ' ')">
          <xsl:value-of select="substring-before($ids, ' ')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$ids"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <svrl:diagnostic-reference diagnostic="{$id}">
      <svrl:text>
        <xsl:choose>
          <xsl:when test="ancestor::sch:pattern/sch:diagnostics">
            <xsl:copy-of select="ancestor::sch:pattern/sch:diagnostics/sch:diagnostic[@id = $id]/@xml:*"/>
            <xsl:copy-of select="ancestor::sch:pattern/sch:diagnostics/sch:diagnostic[@id = $id]/@see"/>
            <xsl:copy-of select="ancestor::sch:pattern/sch:diagnostics/sch:diagnostic[@id = $id]/@icon"/>
            <xsl:copy-of select="ancestor::sch:pattern/sch:diagnostics/sch:diagnostic[@id = $id]/@fpi"/>
            <xsl:apply-templates select="ancestor::sch:pattern/sch:diagnostics/sch:diagnostic[@id = $id]/node()" mode="message-content"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="ancestor::sch:schema/sch:diagnostics/sch:diagnostic[@id = $id]/@xml:*"/>
            <xsl:copy-of select="ancestor::sch:schema/sch:diagnostics/sch:diagnostic[@id = $id]/@see"/>
            <xsl:copy-of select="ancestor::sch:schema/sch:diagnostics/sch:diagnostic[@id = $id]/@icon"/>
            <xsl:copy-of select="ancestor::sch:schema/sch:diagnostics/sch:diagnostic[@id = $id]/@fpi"/>
            <xsl:apply-templates select="ancestor::sch:schema/sch:diagnostics/sch:diagnostic[@id = $id]/node()" mode="message-content"/>
          </xsl:otherwise>
        </xsl:choose>
      </svrl:text>
    </svrl:diagnostic-reference>

    <xsl:if test="contains($ids, ' ')">
      <xsl:call-template name="report-diagnostics">
        <xsl:with-param name="ids" select="substring-after($ids, ' ')"/>
      </xsl:call-template>
    </xsl:if>

  </xsl:template>

  <xsl:template name="report-properties">
    <xsl:param name="ids" select="normalize-space(@properties)"/>
    <xsl:variable name="id">
      <xsl:choose>
        <xsl:when test="contains($ids, ' ')">
          <xsl:value-of select="substring-before($ids, ' ')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$ids"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <svrl:property-reference property="{$id}">
      <xsl:choose>
        <xsl:when test="ancestor::sch:pattern/sch:properties">
          <xsl:copy-of select="ancestor::sch:pattern/sch:properties/sch:property[@id = $id]/@role"/>
          <xsl:copy-of select="ancestor::sch:pattern/sch:properties/sch:property[@id = $id]/@scheme"/>
          <svrl:text>
            <xsl:copy-of select="ancestor::sch:pattern/sch:properties/sch:property[@id = $id]/@xml:*"/>
            <xsl:copy-of select="ancestor::sch:pattern/sch:properties/sch:property[@id = $id]/@see"/>
            <xsl:copy-of select="ancestor::sch:pattern/sch:properties/sch:property[@id = $id]/@icon"/>
            <xsl:copy-of select="ancestor::sch:pattern/sch:properties/sch:property[@id = $id]/@fpi"/>
            <xsl:apply-templates select="ancestor::sch:pattern/sch:properties/sch:property[@id = $id]/node()" mode="message-content"/>
          </svrl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="ancestor::sch:schema/sch:properties/sch:property[@id = $id]/@role"/>
          <xsl:copy-of select="ancestor::sch:schema/sch:properties/sch:property[@id = $id]/@scheme"/>
          <svrl:text>
            <xsl:copy-of select="ancestor::sch:schema/sch:properties/sch:property[@id = $id]/@xml:*"/>
            <xsl:copy-of select="ancestor::sch:schema/sch:properties/sch:property[@id = $id]/@see"/>
            <xsl:copy-of select="ancestor::sch:schema/sch:properties/sch:property[@id = $id]/@icon"/>
            <xsl:copy-of select="ancestor::sch:schema/sch:properties/sch:property[@id = $id]/@fpi"/>
            <xsl:apply-templates select="ancestor::sch:schema/sch:properties/sch:property[@id = $id]/node()" mode="message-content"/>
          </svrl:text>
        </xsl:otherwise>
      </xsl:choose>
    </svrl:property-reference>

    <xsl:if test="contains($ids, ' ')">
      <xsl:call-template name="report-properties">
        <xsl:with-param name="ids" select="substring-after($ids, ' ')"/>
      </xsl:call-template>
    </xsl:if>

  </xsl:template>

  <xsl:template match="*" mode="message-content">
    <alias:element namespace="{namespace-uri(.)}" name="{local-name(.)}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="message-content"/>
    </alias:element>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction()" mode="message-content">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="xsl:copy-of[ancestor::sch:property]" mode="message-content">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="sch:name[@path]" mode="message-content">
    <alias:value-of select="{@path}"/>
  </xsl:template>

  <xsl:template match="sch:name[not(@path)]" mode="message-content">
    <alias:value-of select="name()"/>
  </xsl:template>

  <xsl:template match="sch:value-of" mode="message-content">
    <alias:value-of select="{@select}"/>
  </xsl:template>

  <xsl:template name="declare-variables">
    <xsl:param name="variables"/>
    <xsl:param name="declName" select="'variable'"/>

    <xsl:for-each select="$variables">
      <xsl:element name="{$declName}" namespace="http://www.w3.org/1999/XSL/Transform">
        <xsl:copy-of select="@name"/>
        <xsl:choose>
          <xsl:when test="@value">
            <xsl:attribute name="select">
              <xsl:value-of select="@value"/>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="node()" mode="variable-content"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction()" mode="variable-content">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="*" mode="variable-content">
    <alias:element namespace="{namespace-uri(.)}" name="{local-name(.)}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="variable-content"/>
    </alias:element>
  </xsl:template>

  <xsl:template match="*" mode="copy-location-function">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="copy-location-function"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xsl:*" mode="copy-location-function">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/XSL/Transform">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="copy-location-function"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction() | text()" mode="copy-location-function">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:transform>
