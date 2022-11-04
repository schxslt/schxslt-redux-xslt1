# SchXslt Redux XSLT1

A feature complete implementation of an XSLT 1.0 ISO Schematron processor for the XSLT 1.0 query language binding.

SchXslt Redux XSLT1 is copyright (c) 2018-2022 by David Maus and released under the terms of the MIT license.

## About

This is a trimmed down version of the XSLT 1.0 processor of SchXslt. The processor is implemend as a series of XSLT
transformation that transpile a ISO Schematron schema to an XSLT validation stylesheet. The validation stylesheet
creates a SVRL report when applied to a document instance.

Transpiling a schema is done in three steps.

The stylesheet [1-include.xsl](src/main/resources/content/1-include.xsl) assembles a complete schema by resolving
and internalizing external definitions. It acts on the ```sch:include``` and the ```sch:extends``` with a ```@href```
attribute.

The stylesheet [2-expand.xsl](src/main/resources/content/2-expand.xsl) expands (instantiates) abstract rules and
abstract patterns.

The stylesheet [3-transpile.xsl](src/main/resources/content/3-transpile.xsl) transpiles the schema to the XSLT
validation stylesheet.

SchXslt Redux XSLT1 is a *strict* implementation of ISO Schematron. If you switch from a different implementation such
as [SchXslt](https://github.com/schxslt/schxslt) or the ["Skeleton"](https://github.com/schematron/schematron) your
schema files might not work as expected.

## Limitations

SchXslt Redux XSLT1 comes with the following limitations.

Schematron variables scoped to a phase or pattern are promoted to global XSLT variables.

Schematron variables cannot be used in the rule context expression. XSLT 1.0 [forbids the
use](https://www.w3.org/TR/1999/REC-xslt-19991116#section-Defining-Template-Rules) of variable references in match
patterns.

The URI of the primary document is neither reported in the ```svrl:active-pattern/@documents```, nor in the
```svrl:fired-rule/@document``` attribute. XSLT 1.0 does not provide a function to access the URI of a document..

## Installation and Usage

The [Github releases page](https://github.com/schxslt/schxslt-redux-xslt1/releases) provides a ZIP file with the
processor stylesheets. Download and unzip the file in an appropriate location. Users of [eXist](https://existdb.org) and
[BaseX](https://basex.org) can download and import an EXPath package from the [releases
page](https://github.com/schxslt/schxslt-redux-xslt1/releases), too.

Java users can use the artifact ```name.dmaus.schxslt.schxslt-redux-xslt1``` from Maven Central.

PHP users can use the package ```schxslt/redux-xslt1``` from [Packagist](https://packagist.org). The package provides a
class ```SchXslt\Xslt1\Locator``` with a ```getStylesheets()``` method that returns an array with the paths to the
stylesheets.

## Authors

David Maus &lt;dmaus@dmaus.name&gt;
