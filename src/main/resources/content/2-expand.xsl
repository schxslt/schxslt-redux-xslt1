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
               xmlns:sch="http://purl.oclc.org/dsdl/schematron"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:include href="shared.xsl"/>

  <xsl:key name="abstractPattern" match="sch:pattern[@abstract = 'true']" use="@id"/>
  <xsl:key name="abstractPatternParam" match="sch:pattern/sch:param" use="generate-id(..)"/>
  <xsl:key name="diagnosticAndProperties" match="sch:diagnostics/sch:diagnostic" use="@id"/>
  <xsl:key name="diagnosticAndProperties" match="sch:properties/sch:property" use="@id"/>

  <xsl:template match="sch:rule[@abstract = 'true']"/>

  <xsl:template match="sch:rule/sch:extends[@rule]">
    <xsl:if test="not(../../sch:rule[@abstract = 'true'][@id = current()/@rule])">
      <xsl:variable name="message">
        The current pattern <xsl:value-of select="../../@id"/> does not define an abstract rule with an id of <xsl:value-of select="@rule"/>.
      </xsl:variable>
      <xsl:message terminate="yes">
        <xsl:text/>
        <xsl:value-of select="normalize-space($message)"/>
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="../../sch:rule[@abstract = 'true'][@id = current()/@rule]/node()">
      <xsl:with-param name="sourceLanguage">
        <xsl:call-template name="in-scope-language"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="sch:pattern[@abstract = 'true']"/>

  <xsl:template match="sch:pattern[@is-a]">
    <xsl:if test="not(key('abstractPattern', @is-a))">
      <xsl:variable name="message">
        The current schema does not define an abstract pattern with an id of <xsl:value-of select="@is-a"/>.
      </xsl:variable>
      <xsl:message terminate="yes">
        <xsl:text/>
        <xsl:value-of select="normalize-space($message)"/>
      </xsl:message>
    </xsl:if>

    <xsl:variable name="instanceId" select="generate-id()"/>

    <xsl:copy>
      <xsl:apply-templates select="@*" mode="make-instance">
        <xsl:with-param name="instanceId" select="$instanceId"/>
      </xsl:apply-templates>
      <xsl:if test="not(@documents)">
        <xsl:apply-templates select="key('abstractPattern', @is-a)/@documents" mode="make-instance">
          <xsl:with-param name="instanceId" select="$instanceId"/>
        </xsl:apply-templates>
      </xsl:if>

      <xsl:apply-templates select="key('abstractPattern', @is-a)/node()" mode="make-instance">
        <xsl:with-param name="instanceId" select="$instanceId"/>
        <xsl:with-param name="sourceLanguage">
          <xsl:call-template name="in-scope-language"/>
        </xsl:with-param>
      </xsl:apply-templates>

      <!-- Create instances of diagnostics and properties, too. -->
      <xsl:if test="key('abstractPattern', @is-a)/sch:rule/sch:*/@diagnostics">
        <xsl:variable name="ids">
          <xsl:for-each select="key('abstractPattern', @is-a)/sch:rule/sch:*[@diagnostics]">
            <xsl:value-of select="concat(' ', @diagnostics, ' ')"/>
          </xsl:for-each>
        </xsl:variable>

        <xsl:element name="diagnostics" namespace="http://purl.oclc.org/dsdl/schematron">
          <xsl:call-template name="make-instance">
            <xsl:with-param name="ids" select="normalize-space($ids)"/>
            <xsl:with-param name="instanceId" select="$instanceId"/>
            <xsl:with-param name="sourceLanguage">
              <xsl:call-template name="in-scope-language"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>

      <xsl:if test="key('abstractPattern', @is-a)/sch:rule/sch:*/@properties">
        <xsl:variable name="ids">
          <xsl:for-each select="key('abstractPattern', @is-a)/sch:rule/sch:*[@properties]">
            <xsl:value-of select="concat(' ', @properties, ' ')"/>
          </xsl:for-each>
        </xsl:variable>

        <xsl:element name="properties" namespace="http://purl.oclc.org/dsdl/schematron">
          <xsl:call-template name="make-instance">
            <xsl:with-param name="ids" select="normalize-space($ids)"/>
            <xsl:with-param name="instanceId" select="$instanceId"/>
            <xsl:with-param name="sourceLanguage">
              <xsl:call-template name="in-scope-language"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>

    </xsl:copy>

  </xsl:template>

  <xsl:template name="make-instance">
    <xsl:param name="ids"/>
    <xsl:param name="instanceId"/>
    <xsl:param name="instances"/>
    <xsl:param name="sourceLanguage"/>

    <xsl:if test="not($ids = '')">
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

      <xsl:if test="not(contains($instances, concat(' ', $id, ' ')))">
        <xsl:apply-templates select="key('diagnosticAndProperties', $id)" mode="make-instance">
          <xsl:with-param name="instanceId" select="$instanceId"/>
          <xsl:with-param name="sourceLanguage" select="$sourceLanguage"/>
        </xsl:apply-templates>
      </xsl:if>

      <xsl:call-template name="make-instance">
        <xsl:with-param name="ids" select="substring-after($ids, ' ')"/>
        <xsl:with-param name="instanceId" select="$instanceId"/>
        <xsl:with-param name="instances" select="concat($instances, concat(' ', $id, ' '))"/>
        <xsl:with-param name="sourceLanguage" select="$sourceLanguage"/>
      </xsl:call-template>

    </xsl:if>

  </xsl:template>

  <xsl:template match="sch:diagnostic | sch:property" mode="make-instance">
    <xsl:param name="instanceId"/>
    <xsl:param name="sourceLanguage"/>

    <xsl:variable name="inScopeLanguage">
      <xsl:call-template name="in-scope-language"/>
    </xsl:variable>

    <xsl:copy>
      <xsl:apply-templates select="@*" mode="make-instance">
        <xsl:with-param name="instanceId" select="$instanceId"/>
      </xsl:apply-templates>
      <xsl:if test="not(@xml:lang) and not($inScopeLanguage = $sourceLanguage)">
        <xsl:attribute name="xml:lang">
          <xsl:value-of select="$inScopeLanguage"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="make-instance">
        <xsl:with-param name="instanceId" select="$instanceId"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="make-instance">
    <xsl:param name="instanceId"/>
    <xsl:param name="sourceLanguage">
      <xsl:call-template name="in-scope-language"/>
    </xsl:param>

    <xsl:variable name="inScopeLanguage">
      <xsl:call-template name="in-scope-language"/>
    </xsl:variable>

    <xsl:copy>
      <xsl:apply-templates select="@*" mode="make-instance">
        <xsl:with-param name="instanceId" select="$instanceId"/>
      </xsl:apply-templates>
      <xsl:if test="not(@xml:lang) and not($inScopeLanguage = $sourceLanguage)">
        <xsl:attribute name="xml:lang">
          <xsl:value-of select="$inScopeLanguage"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="make-instance">
        <xsl:with-param name="instanceId" select="$instanceId"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*" mode="make-instance">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="@is-a" mode="make-instance"/>

  <xsl:template match="sch:assert/@test | sch:report/@test | sch:rule/@context | sch:value-of/@select | sch:pattern/@documents | sch:name/@path | sch:let/@value | xsl:copy-of[ancestor::sch:property]/@select" mode="make-instance">
    <xsl:param name="instanceId"/>

    <xsl:variable name="params">
      <xsl:for-each select="key('abstractPatternParam', $instanceId)">
        <xsl:sort select="string-length(@name)" order="descending"/>
        <xsl:value-of select="concat('$', @name, ' ')"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:attribute name="{name()}">
      <xsl:call-template name="replace-placeholder">
        <xsl:with-param name="instanceId" select="$instanceId"/>
        <xsl:with-param name="source" select="."/>
        <xsl:with-param name="params" select="normalize-space($params)"/>
      </xsl:call-template>
    </xsl:attribute>

  </xsl:template>

  <xsl:template name="replace-placeholder">
    <xsl:param name="instanceId"/>
    <xsl:param name="source"/>
    <xsl:param name="params"/>

    <xsl:choose>
      <xsl:when test="normalize-space($params) != ''">
        <xsl:variable name="param">
          <xsl:choose>
            <xsl:when test="contains($params, ' ')">
              <xsl:value-of select="substring-before($params, ' ')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$params"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="replacement" select="key('abstractPatternParam', $instanceId)[@name = substring($param, 2)]/@value"/>

        <xsl:variable name="source">
          <xsl:call-template name="replace-placeholder-single">
            <xsl:with-param name="source" select="$source"/>
            <xsl:with-param name="param" select="$param"/>
            <xsl:with-param name="replacement" select="$replacement"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="contains($params, ' ')">
            <xsl:call-template name="replace-placeholder">
              <xsl:with-param name="instanceId" select="$instanceId"/>
              <xsl:with-param name="source" select="$source"/>
              <xsl:with-param name="params" select="substring-after($params, ' ')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$source"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$source"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="replace-placeholder-single">
    <xsl:param name="source"/>
    <xsl:param name="param"/>
    <xsl:param name="replacement"/>

    <xsl:choose>
      <xsl:when test="contains($source, $param)">
        <xsl:value-of select="substring-before($source, $param)"/>
        <xsl:value-of select="$replacement"/>
        <xsl:call-template name="replace-placeholder-single">
          <xsl:with-param name="source" select="substring-after($source, $param)"/>
          <xsl:with-param name="param" select="$param"/>
          <xsl:with-param name="replacement" select="$replacement"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$source"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:transform>
