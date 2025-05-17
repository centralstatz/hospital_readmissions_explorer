# Created: 2025-05-15
# Author: Alex Zajichek
# Project: Hospital Readmissions LLM Explorer (Shiny app to interact with readmission data in natural language)
# Description: Creates the UI objects

ui <-
  page_sidebar(
    theme = bs_theme(bootswatch = "journal"),
    title = 
      tags$h2(
        class = "bslib-page-title", 
        style = "color:white;", 
        tags$img(
          src = "https://upload.wikimedia.org/wikipedia/commons/2/2a/Centers_for_Medicare_and_Medicaid_Services_logo.svg",
          height = "45px",
          width = "60px"
        ),
        "Excess Readmissions",
        tags$span(
          class = "h5",
          "HRRP 2025 Wisconsin"
        )
      ),
    window_title = "HRRP Program Results",
    
    # Sidebar holds configuration
    sidebar = 
      sidebar(
        open = TRUE,
        
        h2("Controls", style = "text-align:center"),
        
        # Hospital information
        accordion(
          open = FALSE,
          accordion_panel(
            title = "Hospital Information",
            icon = icon("hospital"),
            
            # Simultaneously filtering on hospital columns
            select_group_ui(
              id = "hospitals",
              params = 
                list(
                  list(inputId = "FacilityName", label = "Hospital"),
                  list(inputId = "City", label = "City"),
                  list(inputId = "County", label = "County"),
                  list(inputId = "Zip", label = "Zip")
                ),
              inline = FALSE
            )
            
          )
        ),
        
        # HRRP Measures
        accordion(
          open = FALSE,
          accordion_panel(
            title = "HRRP Measures",
            icon = icon("scale-unbalanced"),
            
            # Diagnosis category
            selectInput(
              inputId = "diagnosis",
              label = "Focus Diagnosis",
              choices = sort(unique(hrrp$DiagnosisCategory))
            ),
            
            ## Sliders for metrics
            
            # Excess
            sliderInput(
              inputId = "excess",
              label = "Excess Readmission Ratio",
              min = 0.65,
              max = 1.25,
              value = c(0.66, 1.22),
              step = 0.05
            ),
            
            # Predicted
            sliderInput(
              inputId = "predicted",
              label = "Predicted Readmission Rate",
              min = 2,
              max = 24,
              value = c(2, 24),
              step = 1
            ),
            
            # Expected
            sliderInput(
              inputId = "expected",
              label = "Expected Readmission Rate",
              min = 2,
              max = 22,
              value = c(2, 22),
              step = 1
            )
            
          )
        ),
        
        # Button to refresh application
        actionButton(
          inputId = "refresh",
          label = "Update",
          icon = icon("arrows-rotate")
        ),
        
        # Dataset sources
        HTML("<br><br>"),
        h3("Data Sources"),
        tags$a("Hospital Information", href = "https://data.cms.gov/provider-data/dataset/xubh-q36u"),
        tags$a("HRRP Measures", href= "https://data.cms.gov/provider-data/dataset/9n3s-kdb3")
        
      ),
    
    ### Main output
    
    # Big content columns
    layout_columns(
      col_widths = c(8, 4),
      
      # A column that takes up the first fraction of the page
      layout_column_wrap(
        width = 1,
        heights_equal = "row",
        
        # Map of hospitals
        card(
          card_header(
            div(
              icon("globe"),
              "Excess Readmissions Map"
            )
          ),
          
          # The map object
          leafletOutput(outputId = "hospital_map"),
          
          # Text to indicate diagnosis shown
          textOutput(outputId = "what_diagnosis"),
          
          full_screen = TRUE
        ),
        
        # KPI cards + graph across the top
        layout_column_wrap(
          width = 1/2,
          
          # Predicted vs. expected
          highchartOutput(outputId = "scatter_plot"),
          
          # Deviation plot from expected
          highchartOutput(outputId = "deviation_plot")
          
        )
        
      ),
      
      # Column containing chat pane
      layout_column_wrap(
        width = 1,
        heights_equal = "row",
        
        # Hospital count
        value_box(
          title = "Hospital Count",
          value = textOutput(outputId = "hospital_count"),
          showcase = icon("hospital", class = "fa-3x"),
          max_height = "200px",
          full_screen = TRUE
        ),
        
        # Metric summary
        value_box(
          title = "Hospitals with excess readmissions",
          value = htmlOutput(outputId = "excess_count"),
          showcase = icon("scale-unbalanced", class = "fa-3x"),
          theme_color = "danger",
          max_height = "200px",
          full_screen = TRUE
        ),
        
        # Make a chat UI to interact with
        card(
          card_header(
            div(
              icon("comment"),
              "Data Chat"
            )
          ),
          querychat_ui(id = "chat"),
          full_screen = TRUE
        )
        
      )
      
    )
    
  )
