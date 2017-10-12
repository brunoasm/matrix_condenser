# Matrix condenser
## Purpose
This tool aids in the preparation of a dataset for population genomics using RAD-seq.

In my experience, it is really hard to ensure even coverage between samples prepared with ddRAD, and a lot of the missing data in the dataset can be removed by excluding a few samples that end up with with little coverage and setting a minimum number of samples per loci for the remaining samples. In a sense, condense the matrix to remove some of its empty space! The optimal number of samples, loci and missing data depends on the application, so it is nice to be able to visualize the matrix.

My preferred assembler, ipyrad, has the option to exclude some samples and/or set a minimum coverage by locus when generating a final dataset, and these options can be used to generate a dataset maximizing the usage of sequenced samples while minimizing missing data.

I wrote this app with a user interface to help me visualize the effects of excluding samples with poor coverage and changing the minimum coverage by locus. I can do this interactively here so it is quick to preview what a matrix will look like for different combinations of sample removal / minimum coverage for a locus.

## Usage
This app can be run locally using Rstudio. There is also a web version hosted at https://bmedeiros.shinyapps.io/matrix_condenser. I use the free version of shiny, so I have some usage quota that might be exceeded if too many people use the app or the dataset is too big. In case it does not work online, simply download the repository and run locally on your computer. Apparently, if you have Rstudio and shiny package installed, you can use the command `runGitHub("brunoasm/matrix_condenser")` to download and run in your computer.

This app can take two kinds of input.

1. Occupancy Matrix.
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

2. `*.loci` output from ipyrad.
To parse a loci file from ipyrad into an occupancy matrix, before uploading select `ipyrad *.loci` from the drop down menu.

Parsing takes a while, so when it is done, a button with the option to download the occupancy matrix in csv format appears. Download this file if you intend to use the tool again with the same dataset. It can be uploaded as *Occupancy matrix* to speed things up.

Usually, I run ipyrad from steps 1-7, keeping all loci shared by at least 4 samples. I then upload the `*.loci` file obtained in this first run as input in this web app to get an idea of what minimum coverage I should use and which samples I should exclude to obtain a dataset with less missing data.


After the input file is parsed, the user has several options to remove samples and loci from the dataset:

**1. Select specific samples to be removed and then a minimum number of samples per loci**
  
  To select specific sampels for removal, one has to open a dialog box using the button **Choose which samples to remove from dataset** and choose which samples to remove. Then use the slider to select a minimum number of samples per locus. 
  Opening the dialogue overrides any values selected in the slider to remove bad samples and the option to remove loci first.
  
**2. Use criteria of minimum coverage to determine which samples and loci to remove**
  
   To remove samples with lowest number of loci, one has simply to select the desired values for minimum samples for a locus and number of bad samples to remove in the sliders. If the slider for number of bad samples is moved, it overrides any sample selection done with the dialog box.
  
  If **Remove loci prior to samples** is checked, then we will first apply the minimum coverage per locus and then remove the selected number of samples with fewest loci in this reduced matrix. Otherwise, samples are removed based on the number of loci recovered for the full dataset. This should only make a difference in datasets in which some sets of samples share sets of loci with each other (for example, if there are two species with several populations each, and severe locus dropout between species in RAD-seq). If loci are missing randomly due to differences in sequencing coverage, the result should be similar.

After selecting the desired values on the sliders, just click on the button "Generate Graph". If the sliders are moved, the button has to be pressed again to generate the new graph.

### Output tabs
#### Matrix Occupancy 
This plots a graph with samples on rows and loci on columns. By default, samples are ordered according to number of loci and loci are ordered according to number of samples. If a locus was obtained for a given sample, the cell is painted black. It is painted white otherwise.

Users can choose to reorder samples and loci by blocks of shared loci. This can make it easier to observe if different samples shared some set of loci. In RAD data, this can arise from locus dropout due to relatedness between samples or due to methodological artifacts, such as differences in size selection.

Users can control the height of the matrix by using the slider on the top right. Sizes there are too small might result in an error message. If that happens, one simply needs to increase the size and generate the graph again.

#### Histogram
This shows a histogram of the number of loci obtained by sample. Red ticks at the bottom correspond to individual samples.

#### Missing Data
This shows a table with the proportion of missing loci per sample. It can be reordered by sample ID or amount of missing data.

#### Excluded Samples
This outputs a text box with excluded sample names and another one with included sample names. This text can be easily copied and pasted to make a branch in ipyrad or a similar use in other program.

## Usage in datasets generated by other programs
If you havce an occupancy matrix as described above, the tool can read it and you can explore the effects of removing samples or changing the minimum number of samples per locus.

## Author information and citation
Bruno A. S. de Medeiros, Harvard University

For now I haven't used this tool in a publication yet, I will updated the information once it is done. If you find it useful for your paper, please cite the program directly:

```
de Medeiros, B. A. S. 2017. Matrix condenser. Retrieved from http:/github.com/brunoasm/matrix_condenser
```


http://scholar.harvard.edu/medeiros
