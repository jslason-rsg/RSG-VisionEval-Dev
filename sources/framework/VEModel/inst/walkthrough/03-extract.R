### 03-extract.R
#   Examples of retrieving raw data from a finished model run

require(VEModel) # just in case it's not already out there...
mwr <- openModel("VERSPM-run") # Run Install.R to install/run that model

# Before you leap into extracting raw model results, consider using
# queries to do extraction and unit conversion. See "05-queries.R"
# later in this walkthrough.

##########################  
# EXTRACTING MODEL RESULTS
##########################

# "Exporting" or "Extracting" results means pulling out some or all of the raw data
# generated by a VisionEval model. If you want to get summary performance metrics from a
# model's results, look at the separate walkthrough, "05-queries.R". Generally, you'll
# "extract" the results if you plan to work with them in R. To move the results out of R
# for analysis in another program, use the "export" function. you can export to CSV
# (comma-separated values), SQLite, or any database accessible through R DBI format such
# as SQLite or MySQL. It is also possible to export directly into Excel. Additional
# formats are under development.

# make sure the model has been run
print(mwr$run())

# Dump all of a model's results (notice the print is the same as the previous print
results <- mwr$results()
print(results)

# You can use the "run" function to get results, or the "results" function
results <- mwr$run()

# You can get a list of all the results in the "Datastore" (where
# VisionEval puts its computations)
datastore.list <- results$list() # default is to show the Group/Table/Name list
print(length(datastore.list))    # number of fields in the results

# To see the full set of metadata, get the list with namesOnly=FALSE
datastore.list <- results$list(namesOnly=FALSE)

# There are a lot of fields, so we'll just show a sample.
# Run this command multiple times to see a different sample each time.
print(datastore.list[sample(length(datastore.list),10)])

# Here is all the information available to describe each field
# (see how to use it below in DisplayUnits example in 03A-advanced-export.R)
datastore.full.list <- results$list(details=TRUE)
print(names(datastore.full.list))
print(datastore.full.list[sample(nrow(datastore.full.list),10),])

# Remember that you can open (or extract) the model results even if something went wrong during a
# run - the results list will show you the subset of data that got computed before the model
# crashed. Look for the section on "debugging" at https://visioneval.org/docs

# Here's the basic extraction of everything in each Reportable model stage
all.the.data <- results$extract() # return a list of data.frames, invisibly, one for each table in each stage
class(all.the.data)      # a list
names(all.the.data)      # the names are the tables of extracted data
class(all.the.data[[1]]) # each table is a data.frame
rm(all.the.data)         # it's huge, so we'll put it in the garbage

# More 
results$export()      # generate the default output (directory tree of CSV files in "results/outputs"
mwr$dir(output=TRUE)  # Just shows the sub-directory names holding outputs

outputs <- mwr$dir(output=TRUE,all.files=TRUE) # Lists all the extracted output files
print(outputs)

# Inspect the Metadata file. Metadata is very basic: just the field
# group/table/name plus description and units (plus display units if those are different, see below)
outputs <- mwr$dir(output=TRUE,all.files=TRUE,shorten=FALSE) # full path name on files
metadata.file <- grep("Metadata\\.csv",outputs,value=TRUE)[1] # subscript to avoid problems if run multiple times
metadata <- read.csv( file=metadata.file )
metadata[1:10,]

####################################
# SELECTING CERTAIN TABLES OR FIELDS
####################################

# You can select certain Groups (e.g. just the Years), Tables and Files rather than
# extracting everything.

# First, just show what's out there
# The Group can be an actual Year, otherwise "Year" will expand to all the Years
# for which the model was run.
wkr <- results$find(Group="Year",Table="Worker")
print(wkr)
print(wkr$fields()) # same...

# Provide a list of table names to find
# Can also do that with Group or Field
# Will get both tables in all Groups (unless you select a specific Group)
wkr.veh <- results$find(Table=c("Worker","Vehicle"))
print(wkr.veh)

sl <- results$select( wkr ) # filters results on selected fields
print(sl) # Just the Worker tables selected

sl <- results$select( wkr.veh )
print(sl) # Worker and Vehicle tables

sl <- results$select()$all() # clear selection (selects all)
print(sl) # Everything selected again

# "all-in-one" instruction to find and select fields at once
sl <- results$find(Group="Year",Table=c("Worker","Vehicle"),select=TRUE)
print(sl) # Just the Worker tables selected

results$export() # uses selection "sl" implicitly due to select=TRUE
results$export(selection=results$find(Group="Year",Table="Worker")) # exports using an explicit selection

# There are much more nuanced selection features available, see https://visioneval.org/docs

###################
# CLEARING EXTRACTS
###################

# Here are instructions for cleaning up old extracts from within R
# You can always delete them using regular operating system commands (File Explorer / Finder)

mwr$dir(outputs=TRUE) # Show all the output folders we created by extracting above
mwr$clear()           # By default, will offer to clear any outputs; can also clear current or saved model results
# Choose "all" to delete all outputs, or you can select them by number or range.
# You will probably need to choose "all" multiple times since it only does 10 at a time.
mwr$dir(outputs=TRUE,all.files=TRUE) # in case you forgot what is in each extraction folder... Maybe nothing left

###################################
# EXPORTING TO AN EXTERNAL DATABASE
###################################

# We saw the CSV (default) export above.
# There are additional export choices (see "visioneval.org/docs" for more details)
# You can change the default output from CSV to SQLite for example

results <- mwr$results() # or mwr$run()
results$export("sql") # goes into an SQLite database in the "outputs" folder
# Note that using "sql" export format puts a Timestamp on each table name

exporter <- results$export("sqlite",connection=list(Database="My-SQLite-Database"))
# Using the "sqlite" export format puts a Timestamp on the database filename

# See the databases
print(mwr$dir(outputs=TRUE))

# Note that R keeps the SQLite databases open until the exporter is
# "garbage collected" or until you exit the R session. If you create
# an SQLite database, be sure to "turn it off" in one of those ways
# before opening it from the outside.

# You can save the exporter configuration:
exporter$save("My-SQLite-Database") # makes a .VEexport file

# in another session, you can reopen the exporter like this:
mwr <- openModel("VERSPM-run")
exporter <- mwr$exporter(file="My-SQLite-Database")

# and you can bring the exported data back into R (organized in the
# same tables as the database):

list.of.data.frames <- exporter$data()
print(names(list.of.data.frames)) # same names as the tables
rm(list.of.data.frames)

list.of.data.tables <- exporter$data(format="data.table")
rm(list.of.data.tables)
rm(exporter)

# See "03A-advanced-extract.R" for more export capabilities