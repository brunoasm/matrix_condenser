
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyUI(fluidPage(

  # Application title
  titlePanel("Matrix condenser"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      selectInput("filetype","Choose a file type before uploading:",
                  choices = c("Occupancy Matrix", "ipyrad *.loci")),
      fileInput("locifile", label = "Choose file to upload"),
      helpText("After file upload, wait for sliders to appear before pressing GENERATE GRAPH"),
      uiOutput("downloadOutput"), #button to download occupancy matrix
      uiOutput("mincovInput"), #slide bar with minCov, limits depend on file chosen
      uiOutput("NremoveInput"), #slide bar with number of bad samples to remove, limits depend on file chosen
      actionButton("go", "Generate graph"),
      tags$div(class="header", checked=NA, tags$p(),
               tags$p("Source code and manual on github:", tags$a(href="https://github.com/brunoasm/matrix_condenser", "brunoasm/matrix_condenser", target="_blank")))
    ),

    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Matrix Occupancy", 
                 fluidRow(column(helpText('Black: locus present, White: locus absent'),
                                 width = 6,
                                 offset = 0.5),
                          column(uiOutput("graphExpansion"),width = 4,offset = 1.5)),
                 verbatimTextOutput("matOccText"),
                 plotOutput("matrixOccupancy")),
        tabPanel("Histogram", plotOutput("covHist"),
                 helpText("Each red tick represents one sample")),
        tabPanel("Missing Data", dataTableOutput(outputId="missingTable")),
        tabPanel("Samples included and excluded",
                 helpText("Here you can find a list of samples to be included and excluded from the final dataset.\nYou can copy and paste them to use in another program."),
                 h5("Included samples"),
                 verbatimTextOutput("includedSamples"),
                 h5("Excluded samples"),
                 verbatimTextOutput("excludedSamples")
                 ) 
      )
      
    )
  )
))
