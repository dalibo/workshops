How To Write a Workshop
===============================================================================

The markdown syntax is vast and has various interpretations. We want a consitent
layout among all our workshops, therefore it is crucial to use the followin
common writing rules.

## Headers

The information is structured in 4 levels: 

* `# Title` is for the main title of the workshop (H1)
* `## Title` is for the big sections (H2)  
* `### Title` is the title of each slide (H3)  
* `### Title` is for subtitles in the handout (not displayed on slides) (H4)  


## Basic Rules

* Each workshop starts with a "Menu" slide that gives the list of all sections (H2)

* Each workshop starts with a "Goal" slide ("Objectif" in French) that outilines
  the main direction of the workshop
  
* H4 titles are only for the handout

* No more than 8 items by list ! If a list is too long break it into a second
  slide

* No more than 2 levels of bullets in lists


## Emphasss 


\``xxxx`\` is reserved for technical terms (eg. `two-phase commit` ), parameters, SQL or
shell commands

`**xxxx**` outlines **important** terms

`_xxxx_` indicates a _neologisme_ ou un terme utilisé out of context

`~~xxxx~~` is for ~~striking~~ a word

`> xxx ` is reserved for quotes or citation: 

> Here's a quote




## Tables

Tables are horrible in markdown. Please use them carefully and keep them
simple.

We only use the so-called [grid_table](http://pandoc.org/MANUAL.html#extension-grid_tables)
syntax for tables. Any other syntax is invalid.



## Separation between slide and handout

You can place your text either in the slide or the handout. We use custom HTML
div tags to mark the difference.

For the slide content, just use the self-explanatory tags  :

```
<div class="slide-content">
Le contenu de ma slide
</div>
```

And write the handout content, like this:

```
<div class="notes">
Mon handout
</div>
```



## Liste

Markdown has different syntax for lists. We recommand that you use the syntax
proposed by the [pandoc manual](http://pandoc.org/MANUAL.html#lists)


**WARNING**: always put a line break before a list



## Images

Images files should be placed in the common `medias` directory. Then you can
include it in you workshop like this :


![PostgreSQL FTW](fr/medias/z1-elephant-1057465_1280.jpg)

```
![PostgreSQL FTW](medias/z1-elephant-1057465_1280.jpg)  
```

**WARNING** : Please put images outside out the `<div class='slide-content'>`
tags. They will be displayed on the slide anyway.

For instance:

```
### Jointure interne

<div class="slide-content">

  * Clause `INNER JOIN`
    * meilleure lisibilitÃ©
    * facilite le travail de l'optimiseur
  * Joint deux tables entre elles
    * Selon une condition de jointure

</div>

![Jointure interne](medias/s3-innerjoin.png)


<div class="notes">

Une jointure interne est considérée comme............
</div>
```



## Links

Please follow the syntax described by the [pandoc manual](http://pandoc.org/MANUAL.html#links)




## Example

Here's an example of a valid slide with a bullet list, a link, an image and some content in the
handout 

```                                                                             
### Jointure interne                                                            
                                                                                
<div class="slide-content">                                                     
                                                                                
  * Clause `INNER JOIN`                                                         
    * meilleure lisibilité                                                     
    * facilite le travail de l'optimiseur                                       
  * Joint deux tables entre elles                                               
    * Selon une condition de jointure                                           
                                                                                
</div>                                                                          
                                                                                
![Jointure interne](medias/s3-innerjoin.png)                                    
                                                                                
                                                                                
<div class="notes">                                                             
                                                                                
Une jointure interne est considérée comme............                           

[RTFM](https://docs.postgresql.fr/10/tutorial-join.html)

</div>
```
