<!--
Copyright (C) by David Maus <dmaus@dmaus.name>

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
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template name="location">
    <xsl:for-each select="ancestor::*">
      <xsl:variable name="position">
        <xsl:number level="single"/>
      </xsl:variable>
      <xsl:value-of select="concat('/Q{', namespace-uri(), '}', local-name())"/>
      <xsl:value-of select="concat('[', $position, ']')"/>
    </xsl:for-each>
    <xsl:variable name="position">
      <xsl:number level="single"/>
    </xsl:variable>
    <xsl:value-of select="'/'"/>
    <xsl:choose>
      <xsl:when test="self::*">
        <xsl:value-of select="concat('Q{', namespace-uri(.), '}', local-name(.))"/>
        <xsl:value-of select="concat('[', $position, ']')"/>
      </xsl:when>
      <xsl:when test="count(../@*) = count(.|../@*)">
        <xsl:value-of select="concat('@Q{', namespace-uri(.), '}', local-name(.))"/>
      </xsl:when>
      <xsl:when test="self::text()">
        <xsl:value-of select="'text()'"/>
        <xsl:value-of select="concat('[', $position, ']')"/>
      </xsl:when>
      <xsl:when test="self::comment()">
        <xsl:value-of select="'comment()'"/>
        <xsl:value-of select="concat('[', $position, ']')"/>
      </xsl:when>
      <xsl:when test="self::processing-instruction()">
        <xsl:value-of select="'processing-instruction()'"/>
        <xsl:value-of select="concat('[', $position, ']')"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
</xsl:transform>
