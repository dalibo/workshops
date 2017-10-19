PostgreSQL Workshops
===============================================================================

This project contains various PostgreSQL workshops including slides, handout or
exerices. This was initially produced by [dalibo](https://dalibo.com) and it's 
now available to everyone under the [PostgreSQL License](LICENSE.md). 

The content is written in markdown using a specific set of [SYNTAX](SYNTAX.md) rules. 

We use [pandoc](http://pandoc.org/), a wonderful document converter, to export
this content in various format. For now the following format are supported :
reveal slides (HTML), PDF, EPUB, doc.

For now, the workshops are available in 2 languages:

* [French Workshops](fr/README.md) are in the `fr` directory 
* [English workshops](en/README.md) are in the `en` directory 

Any other translation is welcome !

Install                                                                          
------------------------------------------------------------------------------- 

We have a dedicated docker image to compile this content. See the 
[QUICKSTART](QUICKSTART.md) guide for more details.

Alternavely you can also [INSTALL](INSTALL.md) the entire debian/pandoc/latex
toolchain.

Compile
-------------------------------------------------------------------------------

Each workshop is contained in a single markdown file (for instance
[fr/100-postgresql_10.md](fr/100-postgresql_10.md) )

You can export the content using `make` and specify the file extension you want

```
make fr/100-postgresql_10.html
make fr/100-postgresql_10.epub
make fr/100-postgresql_10.pdf
etc.
```

You can also build all workshops in all formats with:

```
make all
```

Contribute
------------------------------------------------------------------------------- 

This is an open project. You can [CONTRIBUTE](CONTRIBUTING.md) in many ways: 

* declare a bug
* fix a typo
* translate
* submit a brand new workshop
* etc.



