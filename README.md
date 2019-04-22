# Matrix condenser
## Purpose
This tool aids in the preparation of a dataset for population genomics using RAD-seq.

In my experience, it is really hard to ensure even coverage between samples prepared with ddRAD, and a lot of the missing data in the dataset can be removed by excluding a few samples that end up with with little coverage and setting a minimum number of samples per locus. In a sense, to condense the matrix to remove some of its empty space! The optimal number of samples, loci and missing data depends on the application, so it is nice to be able to visualize the matrix.

I have mostly used [ipyrad](https://github.com/dereneaton/ipyrad) to assemble RAD data, which has the option to exclude some samples and/or set a minimum coverage by locus when generating a final dataset. These options can be used to generate a dataset maximizing the number of samples while minimizing missing data.

I wrote this app as a graphical interface to help me visualize the effects of excluding samples with poor coverage and changing the minimum number of samples for a locus. This can be done interactively here, making it quicker to preview what a matrix will look like for different combinations of sample removal / minimum coverage for a locus. It turns out other people found it useful to visualize phylogenetic structure in sequenced loci.

## Usage
This app can be run locally using R. There is also a web version hosted at https://bmedeiros.shinyapps.io/matrix_condenser. The app is hosted on a Shiny server with a free account, so the usage quota that might be exceeded if too many people access it or the dataset is too big. In case it does not work online, simply download the repository and run locally on your computer. The following command should work to run it locally in R:
```r
if (!require("shiny")) install.packages("shiny")
library(shiny)
runGitHub("brunoasm/matrix_condenser")
```

### Input file types

This app can take three kinds of input:
1. [Occupancy Matrix](#occupancy-matrix)
2. [VCF files](#vcf-files)
3. [`*.loci` output from ipyrad](#loci-output-from-ipyrad)

### Occupancy Matrix (sample in rows)

This is a comma-separated text file with the following format:
 * First row containing locus names 
   - **The names will be largely ignored, but this row must have the same number of columns as other rows!**
 * First column containing sample names
 * Other columns indicating whether a locus is present or absent. This could be accomplished in three ways:
   - Using the words TRUE or FALSE to indicate whether a gene is present
   - Using T or F as shorthand for true and false
   - Using 1 to indicate presence and 0 to indicate absence

Examples of acceptable files (all three have the same information):
```
"","locus_1","locus_2","locus_3","locus_4"
"BdM1590",TRUE,TRUE,TRUE,TRUE
"BdM1711",TRUE,FALSE,FALSE,TRUE
"BdM1723",TRUE,FALSE,FALSE,TRUE
"BdM1735",TRUE,TRUE,FALSE,TRUE
"BdM1743",TRUE,FALSE,FALSE,TRUE
"BdM1744",TRUE,TRUE,FALSE,FALSE
"BdM1745",TRUE,FALSE,FALSE,FALSE
"BdM1746",TRUE,TRUE,FALSE,FALSE
"BdM1639",FALSE,TRUE,FALSE,TRUE
"BdM1656",FALSE,TRUE,FALSE,TRUE
"BdM1662",FALSE,TRUE,TRUE,TRUE
"BdM1689",FALSE,TRUE,FALSE,TRUE
"BdM1705",FALSE,TRUE,FALSE,TRUE
"BdM1710",FALSE,TRUE,FALSE,TRUE
"BdM1712",FALSE,TRUE,FALSE,TRUE
"BdM1720",FALSE,TRUE,FALSE,TRUE
"BdM1739",FALSE,TRUE,FALSE,TRUE
```
```
,locus,names,are,ignored
BdM1590,1,1,1,1
BdM1711,1,0,0,1
BdM1723,1,0,0,1
BdM1735,1,1,0,1
BdM1743,1,0,0,1
BdM1744,1,1,0,0
BdM1745,1,0,0,0
BdM1746,1,1,0,0
BdM1639,0,1,0,1
BdM1656,0,1,0,1
BdM1662,0,1,1,1
BdM1689,0,1,0,1
BdM1705,0,1,0,1
BdM1710,0,1,0,1
BdM1712,0,1,0,1
BdM1720,0,1,0,1
BdM1739,0,1,0,1
```
```
,locus_1,locus_2,locus_3,locus_4
BdM1590,T,T,T,T
BdM1711,T,F,F,T
BdM1723,T,F,F,T
BdM1735,T,T,F,T
BdM1743,T,F,F,T
BdM1744,T,T,F,F
BdM1745,T,F,F,F
BdM1746,T,T,F,F
BdM1639,F,T,F,T
BdM1656,F,T,F,T
BdM1662,F,T,T,T
BdM1689,F,T,F,T
BdM1705,F,T,F,T
BdM1710,F,T,F,T
BdM1712,F,T,F,T
BdM1720,F,T,F,T
BdM1739,F,T,F,T
```

### Occupancy Matrix (locus in rows)

Same as previous format, but with loci in rows and samples in columns


### VCF files

VCF is a common file format for SNPs, produced by most pipelines. For more information about the format, see [this website](http://www.internationalgenome.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version-40/).

We use [vcfR](https://github.com/knausb/vcfR) to parse vcf files:

Knaus BJ and Grünwald NJ (2017). VCFR: a package to manipulate and visualize variant
call format data in R. _Molecular Ecology Resources_, **17**(1): 44-53. doi:[10.1111/1755-0998](12549http://dx.doi.org/10.1111/1755-0998.12549)

When parsing VCF files, each SNP will be considered a locus, regardless of their linkage.

### `*.loci` output from ipyrad

To parse a loci file from ipyrad into an occupancy matrix, before uploading select `ipyrad *.loci` from the drop down menu.

Parsing takes a while. When it is done, a button with the option to download the occupancy matrix in csv format appears. Download this file if you intend to use the tool again with the same dataset. It can be uploaded as *Occupancy matrix* to speed things up. Keep in mind that the matrix is downloaded considering all filters imposed, so if you want the original matrix do not use any filter before downloading.

Downloading might also be useful to generate publication-quality figures. Look into the following options to do that in R from an occupancy matrix:

 * R base graphics: [image](https://www.rdocumentation.org/packages/graphics/versions/3.5.1/topics/image). This is what I use here, `image` can handle a matrix directly.
 
 * Package `ggplot2`: [geom_tile](https://ggplot2.tidyverse.org/reference/geom_tile.html). You will first need to use [gather](https://tidyr.tidyverse.org/reference/gather.html) from package `tidyr` to create a `data.frame` in the format that ggplot likes.
 

Usually, I run ipyrad from steps 1-7, keeping all loci shared by at least 4 samples. I then upload the `*.loci` file obtained in this first run as input in this web app to get an idea of what minimum coverage I should use and which samples I should exclude to obtain a dataset with less missing data.


### Options to condense matrix

After the input file is parsed, the user has several options to remove samples and loci from the dataset. After selecting the desired criteria, just click on the button "Generate Graph". If any criterion is changed, the button has to be pressed again to generate the new graph.

1. Select specific samples to be removed and then a minimum number of samples per loci
  
   To select specific sampels for removal, one has to open a dialog box using the button **Choose which samples to remove from dataset** and choose which samples to remove. Then use the slider to select a minimum number of samples per locus. Opening the dialogue overrides any values selected in the slider to remove bad samples and the option to remove loci first.
  
2. Use criteria of minimum coverage to determine which samples and loci to remove
  
   To remove samples with lowest number of loci, one has simply to select the desired values for minimum samples for a locus and number of bad samples to remove in the sliders. If the slider for number of bad samples is moved, it overrides any sample selection done with the dialog box.
  
If **Remove loci prior to samples** is checked, then we will first apply the minimum coverage per locus and then remove the selected number of samples with fewest loci in this reduced matrix. Otherwise, samples are removed based on the number of loci recovered for the full dataset. This should only make a difference in datasets in which some sets of samples share sets of loci with each other (for example, if there are two species with several populations each, and severe locus dropout between species in RAD-seq). If loci are missing randomly due to differences in sequencing coverage, removing loci or samples first should make little difference.

### Output tabs
#### Matrix Occupancy 
This plots a graph with samples on rows and loci on columns. By default, samples are ordered according to number of loci and loci are ordered according to number of samples. If a locus was obtained for a given sample, the cell is painted black. It is painted white otherwise.

Users can choose to reorder samples and loci independently. This can make it easier to observe if different samples shared some set of loci. In RAD data, this can arise from relatedness between samples or due to methodological artifacts, such as differences in size selection. The four options available to sort are:
 1. **Decreasing (default):** loci are sorted from those present in highest number of samples to those in lowest. Conversely, samples are sorted from those with highest number of loci to those with lowest number.
 
 2. **Increasing:** the inverse of previous option.
 
 3. **Divergent:** a PCA is done behind the scenes to sort loci/samples while maximizing their differences. Very useful for a quick glance at deterministic differences between loci in sets of samples.
 
 4. **Original:** matrix is not reordered, keeping the order in input. This wasn't widely tested yet, please let me know if you run into problems.

Users can control the height of the matrix by using the slider on the top right. Sizes that are too small might result in an error message. If that happens, one simply needs to increase the size and generate the graph again.

#### Histogram
This shows a histogram of the number of loci obtained by sample. Red ticks at the bottom correspond to individual samples.

#### Missing Data
This shows a table with the proportion of missing loci per sample. It can be reordered by sample ID or amount of missing data.

#### Excluded Samples
This outputs a text box with excluded sample names and another one with included sample names. This text can be easily copied and pasted to make a branch in ipyrad or a similar use in other program.

## Author information and citation
Bruno A. S. de Medeiros, Harvard University
https://brunodemedeiros.me
If you like and use this app, please cite the first publication in which I used it:

de Medeiros BAS, Farrell BD. (2018) Whole-genome amplification in double-digest RADseq results in adequate libraries but fewer sequenced loci. PeerJ 6:e5089 https://doi.org/10.7717/peerj.5089



