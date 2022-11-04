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

  <xsl:template match="sch:include">
    <xsl:apply-templates select="document(@href)">
      <xsl:with-param name="sourceLanguage">
        <xsl:call-template name="in-scope-language"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="sch:rule/sch:extends[@href]">
    <xsl:variable name="externalIsDocumentNode">
      <xsl:if test="not(contains(@href, '#'))">true</xsl:if>
    </xsl:variable>
    <xsl:variable name="externalNamespaceUri">
      <xsl:choose>
        <xsl:when test="$externalIsDocumentNode = 'true'">
          <xsl:value-of select="namespace-uri(document(@href)/*)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="namespace-uri(document(@href))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="externalLocalName">
      <xsl:choose>
        <xsl:when test="$externalIsDocumentNode = 'true'">
          <xsl:value-of select="local-name(document(@href)/*)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="local-name(document(@href))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="externalIsSchematronRule">
      <xsl:if test="$externalNamespaceUri = 'http://purl.oclc.org/dsdl/schematron' and $externalLocalName = 'rule'">true</xsl:if>
    </xsl:variable>

    <xsl:if test="$externalIsSchematronRule != 'true'">
      <xsl:variable name="message">
        The @href attribute of an &lt;extends&gt; element must be an
        IRI reference to an external well-formed XML document or to an
        element in an external well-formed XML document that is a
        Schematron &lt;rule&gt; element. This @href points to a
        <xsl:value-of select="concat('Q{', $externalNamespaceUri, '}', $externalLocalName)"/>
        element.
      </xsl:variable>
      <xsl:message terminate="yes">
        <xsl:text/>
        <xsl:value-of select="normalize-space($message)"/>
      </xsl:message>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="$externalIsDocumentNode = 'true'">
        <xsl:apply-templates select="document(@href)/*/node()">
          <xsl:with-param name="sourceLanguage">
            <xsl:call-template name="in-scope-language"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="document(@href)/node()">
          <xsl:with-param name="sourceLanguage">
            <xsl:call-template name="in-scope-language"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:transform>
