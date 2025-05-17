# Created: 2025-05-15
# Author: Alex Zajichek
# Project: Hospital Readmissions LLM Explorer (Shiny app to interact with readmission data in natural language)
# Description: Handles user interactions

server <- 
  function(input, output, session) {
    
    # Filter to the current hospitals (based on group of location filters)
    current_hospitals_temp <- 
      
      # Filters the dataset at once
      select_group_server(
        id = "hospitals",
        data = reactive(hospitals),
        vars = reactive(c("FacilityName", "City", "County", "Zip"))
      )
    
    # Filter to current hospitals (with metric criteria)
    current_hospitals <- 
      reactive({
        
        current_hospitals_temp() |>
          
          # Join to get excess ratio
          inner_join(
            y =
              hrrp |>
              
              # Filter to the specified metric ranges
              filter(
                DiagnosisCategory == input$diagnosis,
                Excess >= min(input$excess), Excess <= max(input$excess),
                Predicted >= min(input$predicted), Predicted <= max(input$predicted),
                Expected >= min(input$expected), Expected <= max(input$expected)
              ),
            by = "FacilityID"
          )
        
      })
    
    # Display the map contents
    output$hospital_map <- renderLeaflet({base_map})
    observe({
      
      leafletProxy("hospital_map") |>
        clearMarkers() |>
        
        # Add points to map
        addCircleMarkers(
          data = 
            current_hospitals() |>
            
            # Filter to the focus diagnosis group
            filter(DiagnosisCategory == input$diagnosis), 
          
          lng = ~lon,
          lat = ~lat,
          label = ~paste0(FacilityName, " (click for info)"),
          popup = 
            ~paste0(
              "Hospital: ", FacilityName, 
              "<br>Address: ", Address,
              "<br>City: ", City,
              "<br>County: ", County,
              "<br>Zip Code: ", Zip,
              "<br>Excess Readmission Ratio: ", Excess,
              "<br>Predicted Readmission Rate: ", round(Predicted, 2), "%",
              "<br>Expected Readmission Rate: ", round(Expected, 2), "%"
            ),
          color = ~pal(-1*Excess),
          radius = ~scale(Excess)[,1] + 5,
          fillOpacity = 1
        )
      
    })
    
    # Print displayed group
    output$what_diagnosis <- renderText({paste0("Focus Diagnosis Group: ", input$diagnosis)})
    
    # Scatterplot: predicted vs. expected
    output$scatter_plot <-
      renderHighchart({
        
        hrrp |>
          
          # Filter to hospitals in current set
          filter(FacilityID %in% current_hospitals()$FacilityID) |>
          
          # Make a highchart scatterplot
          hchart(
            "scatter",
            hcaes(
              x = Predicted,
              y = Expected,
              group = DiagnosisCategory
            )
          )
        
      })
    
    # Scatterplot: Deviation of predicted from expected
    output$deviation_plot <-
      renderHighchart({
        
        hrrp |>
          
          # Filter to hospitals in current set
          filter(FacilityID %in% current_hospitals()$FacilityID) |>
          
          # Make a highchart scatterplot
          hchart(
            "scatter",
            hcaes(
              x = Expected,
              y = Excess,
              group = DiagnosisCategory
            )
          ) |>
          
          # Reference line at y = 1
          hc_yAxis(
            plotLines = 
              list(
                list(
                  color = "#252525",
                  width = 2,
                  value = 1
                )
              )
          )
        
      })
    
    # Display the selected hospital county
    output$hospital_count <- 
      renderText({
        
        # Count the number of unique hospitals represented
        n_distinct(current_hospitals()$FacilityID)
        
      })
    
    # Display count of those in excess
    output$excess_count <- 
      renderUI({
        
        temp_count <- 
          current_hospitals() |>
          
          # Filter to hospitals in excess
          filter(
            DiagnosisCategory == input$diagnosis,
            Excess > 1
          ) |>
          
          # Row count
          nrow()
        
        temp_count <- paste0(temp_count, " (", round(100 * temp_count / n_distinct(current_hospitals()$FacilityID)), "%)")
        
        HTML(paste0(temp_count, "<span style='font-size:14px'>for ", input$diagnosis))
        
      })
    
  }
