# Notes on development steps

# 1. Create repository in GitHub

Created a new public repo on GitHub page: https://github.com/centralstatz/hospital_readmissions_explorer

# 2. Create new local RStudio project

Source project from GitHub (https://github.com/centralstatz/hospital_readmissions_explorer.git) with a new RStudio project to initialize with version control.

# 3. Create app file structure

Using `global.R`, `server.R`, `ui.R` setup

# 4. Built datasets needed for visuals

This is done in `global.R`

## a. Hospital data

I'm using the following datasets from the [CMS Provider Data Catalog]():

* [Hospital General Information](https://data.cms.gov/provider-data/dataset/xubh-q36u): Provides information about hospitals, such as name and address
* [Hospital Readmissions Reduction Program](https://data.cms.gov/provider-data/dataset/9n3s-kdb3): Provides the measure results from the [HRRP](), including the predicted/expected readmission rates and excess readmission ratio for each hospital.

I used the [`pdc_read`](https://github.com/zajichek/carecompare/blob/b1fa89382adfe77bd5f230f4162b03767ece10ea/R/FUNCTIONS.R#L99) function which is from a development R package I worked on a while back (but never finished...). This was pasted into `global.R`.

## b. Geocoded zip codes

Extracted zip codes for Wisconsin from `tigris::zctas`, and mapped them to their zip code centroids (based on the respective geometry) for plotting hospitals on a map via lat/lon (ideally we'd geocode to the exact address but this is for demo purposes, so hospitals will show up in a common zip code with some random jitter).

## c. Final datasets

I then cleaned up two final datasets to use:

* `hospitals`: Gives the name, location and plotting coordinates for each hospital
* `hrrp`: For each hospital, gives the measure values (excess, predicted, expected) for each disease category in long format (with cleaned up labels)

# 5. Install packages to interact with LLM's

Installed the [`querychat`](https://github.com/posit-dev/querychat/tree/main/r-package) package. I also already have [`ellmer`](https://ellmer.tidyverse.org/) and [`shinychat`](https://posit-dev.github.io/shinychat/index.html) installed.

```
pak::pak("posit-dev/querychat/r-package")
```

This also installs `duckdb` for the SQL engine in the backend.

# 6. Develop app layout and design

I'm starting with normal Shiny functionality (manual user interaction) in order to get the visuals working how I want before driving them with LLM's. So first I'm creating a dropdowns for the different variables to start.

I have the filters on the left side, then added a chat pane from `querychat_ui` on the right pane.

Ultimately, I'll try to enable the use of both: 

* Use the manual filters directly, OR
* Use the chat, which in turn dynamically updates the filters as well as the visuals

# 7. Visual Output

## Map

The map should display the hospitals on the map colored by the excess readmission ratio (and differentiated by size and color). It will filter based on the selected hospitals, the disease category, and the ranges of measures selected.

## Scatter plots

There are two plots:

* One shows the predicted versus expected readmission rates
* Another shows the expected readmission rate versus the excess readmission ratio

For the given hospitals selected, it displays points for all diagnosis groups to compare rates across cohorts

## KPI's

These show

* The number of hospitals in the current selection
* The number (and percent) of hospitals in current selection that have excess readmissions for the selected diagnosis group

# 8. Dynamic input updates

The inputs should update in real time with the selections made in other inputs. For example, if I selected a given zip code, then my only hospital choices should be those in that zip code.

I used the [`datamods`](https://dreamrs.github.io/datamods/reference/select-group.html) package to facilitate this. You have to supply the `id` values for the columns as the column names themselves, then it dynmaically updates the selections simulataneously. 

The only problem is that with the chat functionality, I don't see how this is going to work given the way in which the SQL engine filters the data. One approach may be to initialize the chat with `querychat_init` in the server itself based on the dynamically filtered hospital set, then you only ask questions about the metrics.

We'll just move forward with the assumption that hospitals are chosen manually, and then the metric selectors are what get updated.

## Metric selectors

The metric inputs should update with the ranges of the current selections.

# 8. Chat functionality

There is a "chat mode" feature now in the main sidebar. You can toggle back and forth between manual and chat mode.

## Dynamically update reactive dataset

After the hospitals are selected manually with the dynamic selector inputs, the chat is going to allow querying of that subset _before_ it filters to specific diagnosis, so you can ask questions like:

_"What hospitals in Wausau had excess readmissions for heart failure?"_

_"What disease category had the highest average excess readmission ratio?"_

So we'll assume the user filtered to a group of hospitals of interest, then asks questions of those

## Display output

We'll just have a separate tab where the results of query will be shown.

# 5/21/2025

* Made a single master dataset that combines hospitals with program metrics (so one row per hospital/disease group combo). This will be entered into the querychat configuration.

## Useful prompts:

* "Show me the hospitals with top 5 largest excess readmission ratio across all diagnosis groups"
* "Show me hospitals that had excess readmissions > 1 for heart failure"
* "Show me hospitals in Marathon county that who had more predicted readmissions than expected"
* "Which hospital had the largest discrepancy in predicted vs. expected readmission rate for CABG?" (Chat response)
* "What is the average predicted readmission rate for each diagnosis group?" (Chat response)
* "Show me the top 10 best hospitals for knee or hip"

## Data description

* Made a file called `data_description.md` which I can describe my dataset, then import it into the `querychat_init`
* Make system prompt file to describe the dataset, capital words, how it is structured (e.g., if we have everything in one dataset, it must understand how to query it).
