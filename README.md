# Administrative Data Linking

This repository contains sample code the [California Policy Lab] used to test software approaches to data linking. This topic is explored in the California Policy Lab white paper "[Administrative Data Linking]". 

The purpose of these exercises is to experiment with different approaches to linking administrative data (rules-based, supervised machine learning, and unsupervised machine learning) using publicly available records of Michigan voter registration. We tested programs that carry out each of these approaches and evaluate their relative performance. For more on approaches to administrative data linking and for the results of the tests run, please see the white paper. 

The [fastLink] and [Dedupe] code is adapted from code available from the package authors, the rules-based code (written in SAS) is our own. 

# Code

### Rules-Based

  - This program implements **rules-based linking** using SAS and was developed by the California Policy Lab. This code is intended as an example of rules-based linking – rules and code will vary on a case by case basis. Rules-based data linking can be performed in virtually any programming language. 
  - [Rules code]

### Dedupe - supervised machine learning
- Dedupe is a Python library that implements **supervised machine learning** to deduplicate and link data files. We use the record linkage functions of Dedupe in this code to link two files. 
- Our code is adapted from example code posted on the Dedupe GitHub page – all credit goes to the Dedupe developers, and all questions should be directed to them unless they are specific to the data we’ve used or our changes to the code.
- adapted [Dedupe code]
- [Dedupe GitHub]

### fastLink - unsupervised machine learning
- fastLink is an R package that uses **unsupervised machine learning** to link datasets. 
- We adapt the code that accompanies the fastLink CRAN package to link our datasets – all credit goes to the fastLink developers and all questions should be directed to them unless they are specific to the data we’ve used or our changes to the code.
- adapted [fastLink code]
- [fastLink CRAN]
- [fastLink GitHub]

## [Data]
These scripts run on subsamples of two public Michigan voter registration files from 2015 and 2017. Our subsamples are available in this repo, the original files are accessible for download [here]. 

### Data Preparation
1.	We download two .lst files from [this website] - the full 2015 and 2017 voter registration files. 
2.	We keep a random 3 million records from each dataset, then a random 1 million with a match rate of 70% across datasets
3.	From these 1 million samples we restrict to individuals born in 1985 and 1986. 

## Team
- Elsa Augustine, CPL
- Charles Davis, CPL
- Vikash Reddy, CPL
- Jesse Rothstein, CPL

## Acknowledgements
- Enamorado, Ted, Benjamin Fifield, and Kosuke Imai. "fastLink: Fast Probabilistic Record Linkage." available through The Comprehensive R Archive Network (https://cran.r-project.org/web/packages/fastLink/index.html)  
- Dedupe - Forest Gregg and Derek Eder. 2018. Dedupe. https://github.com/dedupeio/dedupe. 


[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)

   [California Policy Lab]: <https://www.capolicylab.org/?>
   [Administrative Data Linking]: <LINK HERE>
   [Dedupe GitHub]: <https://github.com/dedupeio/dedupe>
   [Dedupe]: <https://github.com/dedupeio/dedupe>
   [fastLink GitHub]: <https://github.com/kosukeimai/fastLink>
   [fastLink]: <https://github.com/kosukeimai/fastLink>
   [fastLink CRAN]: <https://github.com/kosukeimai/fastLink>
   [here]: <http://michiganvoters.info/>
   [this website]: <http://michiganvoters.info/>
   [fastLink code]: <code/fastLink.R>
   [Dedupe code]: <code/dedupe.py>
   [Rules code]: <code/rules.sas>
   [Data]: <data>
   

