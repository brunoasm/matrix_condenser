
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

if (!require("shiny")) install.packages("shiny")
if (!require("plyr")) install.packages("plyr")
if (!require("vcfR")) install.packages("vcfR")

library(shiny)
library(plyr)
library(vcfR)

options(shiny.maxRequestSize=10000*1024^2) 


# The following function parses a *.loci file generated by pyRAD
# It outputs a matrix of samples x loci, showing which loci where recovered for each sample
parseLociFile <- function(input_path){
  
  #first, get number of lines in file to report progress
  f <- file(input_path, open="rb")
  nlines <- 0L
  while (length(chunk <- readBin(f, "raw", 65536)) > 0) {
    nlines <- nlines + sum(chunk == as.raw(10L))
  }
  close(f)
  #now, read the file
  input_connection = file(input_path, "r")
  locus = 1
  loci = list()
  loci[[locus]] = logical()
  seqlines = character()
  n_lines_per_chunk = 1000000
  n_chuncks = ceiling(nlines/n_lines_per_chunk)
  withProgress(message = 'Reading *.loci file',
               value = 0,
               min = 0, 
               max = n_chuncks+1,
               expr = {
                 
                 while (TRUE){
                   incProgress(0.5)
                   lines = readLines(input_connection, n_lines_per_chunk)
                   if ( length(lines) == 0 ){break}
                   for (line in lines){
                     
                     if (!(grepl("//",line))){
                       #sample = strsplit(line,'\\s+')[[1]][1]
                       seqlines = c(seqlines,line)
                     } else {
                       samples = gsub('\\s.*$','',seqlines)
                       samples = samples[samples != ''] #sometimes ipyrad makes blank lines, this removes them
                       loci[[locus]] = rep(TRUE,length(samples))
                       names(loci[[locus]]) = samples
                       
                       locus = locus + 1
                       loci[[locus]] = logical()
                       seqlines = character()
                       }
                     }
                   incProgress(0.5)
                   
                 }
                 
                 close(input_connection)
                 
                 loci = loci[1:(length(loci)-1)]
                 
                 occmat = ldply(loci, function(x){t(data.frame(x))})
                 incProgress(0.5)
                 occmat[is.na(occmat)] = FALSE
                 occmat = t(occmat)
                 occmat = as.matrix(occmat)
                 colnames(occmat) = paste('locus',1:dim(occmat)[2],sep='_')
                 incProgress(0.5)
               })
  return(occmat)
}

parseOccMat <- function(input_path, transpose_mat = F){
 validate(
    need(
      try({
        occmat = as.matrix(read.csv(file = input_path, header = T, row.names = 1, as.is = T))
        if (transpose_mat){
          occmat = t(occmat)
        } else {
          occmat = occmat
        }
        }), 
      'Error reading input. Check if properly formatted occupancy matrix.'
    )
  )
  
  
  validate(
    need({dim(occmat)[2] > 0}, message = "Input not an occupancy matrix, check file type.")
  )
  samples = row.names(occmat)
  occmat = apply(occmat,2,as.logical)
  row.names(occmat) = samples
  return(occmat)
}

parseHybPip <- function(input_path){
  validate(
    need(
      try({
        occmat = as.matrix(read.csv(file = input_path, header = T, row.names = 1, as.is = T, sep="\t")[-1,]) > 0
      }), 
      'Error reading input. Check if properly formatted occupancy matrix.'
    )
  )
  
  
  validate(
    need({dim(occmat)[2] > 0}, message = "Input not an occupancy matrix, check file type.")
  )
  samples = row.names(occmat)
  occmat = apply(occmat,2,as.logical)
  row.names(occmat) = samples

  return(occmat)
}

parseVCF <- function(input_path){
  withProgress({
    validate(
      need(
        try({vcf = read.vcfR(input_path,convertNA = F)}), message = "Error parsing VCF, check file type."
      )
    )
    vcf = apply(vcf@gt[,-1],
                c(2,1),
                function(x){!grepl('^\\./\\.',x)})
  },
  message = 'Parsing VCF file',value = 1)

  return(vcf)
}

shinyServer(function(input, output) {
  #v will store values used accross reactive expressions, starting by plotting indicator
  v <- reactiveValues(doPlot = FALSE, reduced_matrix = matrix(NA,nrow = 1,ncol=1), checkedSamples = c())
  
  # first, open and parse input file.
  # this is a reactive, so it will only be done once for each input file
  filetype <- reactive({
    switch(input$filetype,
           "Occupancy Matrix (sample in rows)" = "occmatrixw",
           "Occupancy Matrix (locus in rows)" = "occmatrixl",
           "ipyrad *.loci" = "ipyrad_loci",
           "VCF" = "vcf",
           "Hybpiper seq_lengths.tsv file" = "hybpiper")
  })
  
  samples_vs_loci <- reactive({
    if (filetype() == "ipyrad_loci"){
      parseLociFile(input$locifile$datapath)
    } else if (filetype() == c("occmatrixw")){
      parseOccMat(input$locifile$datapath, transpose_mat = F)
    } else if (filetype() == c("occmatrixl")){
      parseOccMat(input$locifile$datapath, transpose_mat = T)
    } else if(filetype() == "vcf"){
      parseVCF(input$locifile$datapath)
    } else if(filetype() == "hybpiper"){
      parseHybPip(input$locifile$datapath)
    }
  })
  
  #Offer option to download occupancy matrix
  output$downloadMatrix <- downloadHandler(
    filename = 'occupancy_matrix.csv',
    content = function(file){
      if(identical(v$reduced_matrix,matrix(NA,nrow = 1,ncol=1))){
        write.csv(samples_vs_loci(),file,row.names = T,col.names = T)
      } else {
        write.csv(v$reduced_matrix,file,row.names = T,col.names = T)
      }
      
      }
  )
  
  
  #Then, generate output button and sliders for mincov and number of samples to remove
  output$downloadOutput <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    downloadButton("downloadMatrix","Download occupancy matrix")
  })
  
  output$NremoveInput <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    sliderInput("nremove", "Number of bad samples to remove:", 0, dim(samples_vs_loci())[1], 0, step = 1)
  })
  
  output$mincovInput <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    if (length(v$last_value)){init = v$last_value} else {init = 1}
    sliderInput("mincov", "Minimum number of samples in a locus:", 1, dim(samples_vs_loci())[1]-input$nremove, min(init, dim(samples_vs_loci())[1]-input$nremove), step = 1)
  })
  
  output$whatRemoveInput <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    checkboxInput("whatRemove", "Remove loci prior to samples", value = TRUE)
  })
  
  output$removeSpecific <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    actionButton("removeSpecific","Choose which samples to remove")
  })
  
  output$graphExpansion <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    sliderInput("graphExpansion", "Graph Expansion:", 5, 100, 80, step = 1, post = ' %', ticks = FALSE)
  })
  
  output$sampleSort <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    selectInput("sampleSort","Sample sorting:",
                choices = c("Decreasing", "Increasing", "Divergent", "Original"))
  })
  
  output$lociSort <- renderUI({
    if (is.null(input$locifile)) return(NULL)
    selectInput("lociSort","Locus sorting:",
                choices = c("Decreasing", "Increasing", "Divergent", "Original"))
  })
  
  #create reactives to make action button work
  
  observeEvent(input$go, {
    v$doPlot <- input$go
  })
  
  observeEvent(input$nremove, {
    v$checkedSamples <- c()
    v$doPlot <- FALSE
  })
  
  observeEvent(input$mincov, {
    v$doPlot <- FALSE
    v$last_value <- input$mincov
  })
  
  observeEvent(input$whatRemove, {
    v$doPlot <- FALSE
    v$loci_first <- input$whatRemove
  })
  
  observeEvent(input$removeSpecific, {
    showModal(modalDialog(
      title = "Choose which samples to remove from dataset:",
      "Attention: this overrides removal of bad samples!",
      checkboxGroupInput("checkboxRemove",
                    "Check samples to be removed:",
                    choices = sort(rownames(samples_vs_loci())),
                    selected = v$checkedSamples), #gives all samples as options
      easyClose=FALSE
    ))
  })
  
  observeEvent(input$checkboxRemove,{
    v$checkedSamples <- input$checkboxRemove
    v$doPlot <- FALSE
  })
  
  
  observeEvent(input$graphExpansion, {
    v$doPlot <- FALSE
    v$graphExpansion <- input$graphExpansion
  })
  
  observeEvent(input$lociSort, {
    v$doPlot <- FALSE
    v$lociSort <- input$lociSort
  })
  
  observeEvent(input$sampleSort, {
    v$doPlot <- FALSE
    v$sampleSort <- input$sampleSort
  })
  
  #Generate a reactive for reducing matrix
  reduce_matrix <- reactive({withProgress({
    if (length(v$checkedSamples)){
      #if user selected specific samples for removal, do that and then remove loci according to slider value
      samples_to_remove <- v$checkedSamples
      
      reduced_matrix <-samples_vs_loci()[is.na(match(rownames(samples_vs_loci()), samples_to_remove)), ]
      loci_to_keep <- apply(reduced_matrix, 2, sum) >= input$mincov
      reduced_matrix <- reduced_matrix[,loci_to_keep]
      
    } else if (v$loci_first){ #if no specific samples selected and loci first, remove loci and then samples according to sliders
      #first, remove loci below mincov
      loci_to_keep <- apply(samples_vs_loci(), 2, sum) >= input$mincov
      reduced_matrix <- samples_vs_loci()[,loci_to_keep]
      
      #then check which samples have the least number of in loci in common
      samples_to_remove <- sort(rownames(reduced_matrix)[rank(apply(reduced_matrix, 1, sum),ties.method="max") <= input$nremove])
      
      #now, remove those samples from the full matrix and set mincov again
      reduced_matrix <-samples_vs_loci()[is.na(match(rownames(samples_vs_loci()), samples_to_remove)), ]
      loci_to_keep <- apply(reduced_matrix, 2, sum) >= input$mincov
      reduced_matrix <- reduced_matrix[,loci_to_keep]
    }
    else { #if none of the above, remove first samples and then loci according
      #first, remove the worst samples (or specific samples, if selected by user)
      reduced_matrix = samples_vs_loci()

      samples_to_remove <- sort(rownames(reduced_matrix)[rank(apply(reduced_matrix, 1, sum),ties.method="max") <= input$nremove])
      
      
      reduced_matrix <-samples_vs_loci()[is.na(match(rownames(samples_vs_loci()), samples_to_remove)), ]
      loci_to_keep <- apply(reduced_matrix, 2, sum) >= input$mincov
      reduced_matrix <- reduced_matrix[,loci_to_keep]
    }
    samples_to_include <- sort(setdiff(rownames(reduced_matrix),samples_to_remove))
    
    
    
    if (v$lociSort == "Divergent" | v$sampleSort == "Divergent"){
      pca = prcomp(t(reduced_matrix))
    }
    
    if (v$lociSort == "Divergent"){
      loci_order = order(pca$x[,1])
    } else if(v$lociSort == "Decreasing"){
      loci_order = order(apply(reduced_matrix,2,sum),decreasing = T)
    } else if(v$lociSort == "Increasing"){
      loci_order = order(apply(reduced_matrix,2,sum))
    } else {
      loci_order = 1:dim(reduced_matrix)[2]
    }
    
    if (v$sampleSort == "Divergent"){
      sample_order = order(pca$rotation[,1])
    } else if(v$sampleSort == "Decreasing"){
      sample_order = order(apply(reduced_matrix,1,sum))
    } else if(v$sampleSort == "Increasing"){
      sample_order = order(apply(reduced_matrix,1,sum), decreasing = T)
    } else {
      sample_order = 1:dim(reduced_matrix)[1]
    }
      
      reduced_matrix = reduced_matrix[sample_order,loci_order]
    
    
    #now save variables to be used by other expressions
    v$samples_to_remove <- samples_to_remove
    v$samples_to_include <- samples_to_include
    v$reduced_matrix <- reduced_matrix
    v$loci_to_keep <- colnames(reduced_matrix)
    
  },value = 1, message = 'Rendering output')
  })
  
  #Plot graph when action button is pressed
  observe({
    if (v$doPlot == FALSE | is.null(input$locifile)){
      output$matrixOccupancy <- renderPlot({plot.new()})
    } else{
      output$matrixOccupancy <- renderPlot({
        isolate({
          reduce_matrix()
          #plot
          par('mar'= c(1,7.1,0,2.1))
          image(x = 1:dim(v$reduced_matrix)[2], y = 1:dim(v$reduced_matrix)[1], t(!v$reduced_matrix), col = c("black", "white"), yaxt='n', xaxt='n', xlab=NA, ylab=NA)
          axis(2,at = seq(1,dim(v$reduced_matrix)[1],1), rownames(v$reduced_matrix), tick = FALSE, las=1)
        })},
        height = v$graphExpansion/100*20*dim(v$reduced_matrix)[1])
      
    }
    
    
  })
  
  
  
  output$covHist <- renderPlot({
    if (v$doPlot == FALSE) return()
    isolate({
      reduce_matrix()
      #plot
      locus_counts <- apply(v$reduced_matrix, 1 ,sum)
      hist(locus_counts, xlab= "Number of loci in final dataset", main= "Number of loci per sample")
      axis(1,at = locus_counts,lwd = 0, lwd.ticks = 0.8, col.ticks = 'red', labels = FALSE, line = -.5)
    })})
  # And render texts and tables
  output$matOccText <- renderText({
    if (v$doPlot == FALSE) return()
    isolate({
      reduce_matrix()
      dims = dim(v$reduced_matrix)
      paste('Number of samples: ',dims[1],
            '\nNumber of loci: ',dims[2],
            '\nTotal missing data: ',sprintf('%2.2f',100*sum(!v$reduced_matrix)/(prod(dims))),'%', collapse = "")
    })
  })
  
  
  output$excludedSamples <- renderText({
    if (v$doPlot == FALSE) return()
    isolate({
      reduce_matrix()
      dims = dim(v$reduced_matrix)
      paste(v$samples_to_remove, collapse = " ")
    })
  })
  
  output$includedSamples <- renderText({
    if (v$doPlot == FALSE) return()
    isolate({
      reduce_matrix()
      paste(v$samples_to_include, collapse = " ")
    })
  })
  
  output$includedLoci <- renderText({
    if (v$doPlot == FALSE) return()
    isolate({
      reduce_matrix()
      paste(v$loci_to_keep, collapse = " ")
    })
  })
  
  output$missingTable <- renderDataTable({
    if (v$doPlot == FALSE) return()
    isolate({
      reduce_matrix()
      missing_table <- data.frame(samples= rownames(v$reduced_matrix),
                                  pmissing= 100-apply(v$reduced_matrix,1,function(x){mean(x)*100}))
      names(missing_table) <- c("Sample IDs", "Loci missing (%)")
      return(missing_table)
    })
  })
  
  
})
