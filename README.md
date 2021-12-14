# DHIS2 Metadata Asssessment Tool

## Purpose of this tool

Management of metadata integrity should be a primary concern for DHIS2 implementers.
The DHIS2 API enforces a number of restrictions on various objects and their 
relationships, but under certain circumstances, metadata objects may become
corrupted. This may become especially apparent on DHIS2 systems which have been
running for a number of years, and which have undergone extensive changes to the 
systems metadata.

Another common problem is the creation of metadata or analytic objects
which are no longer in use (or perhaps never were). In order to keep the 
system tidy and with good performance, it may be appropriate to regularly
review the metadata in the DHIS2 database and determine if it should be removed
due to lack of use.

There are a number of integrity checks which are available in DHIS2 which help
to diagnose various metadata problems. This tool is intended to serve
as a compliment to those checks, as well as providing additional guidance to 
DHIS2 implementers on how to fix these problems in their system.


## About this tool

This tool kit consists of a series of SQL queries which have been created
by the DHIS2 Implementation and Development Teams to identify potential metadata issues in 
DHIS2 databases. The metadata checks in this tool have been organized in a series of YAML
files. YAML is a user-friendly data serialization language which can be 
parsed by a number of different programming languages. It is also exceptionally
easy to read.  Each check included in this tool has a separate YAML file, 
which consists of a number of key value pairs. Each of these keys will be explained below. 

- *summary_uid*: A predefined DHIS2 UID which is used to identify the 
summary SQL query for this check.
- *name*: The name of the SQL query. This name should be relatively short but descriptive. It should also
be written in snake case so that a valid database view name can be created using this field.
- *description*: A short description of the issue.
- *section*: Used in the R-markdown report to group related issues together. 
Generally these are related metadata objects like indicators or data elements.
- *section_order*: Used in the R-markdown report to order issues within a section.
- *summary_sql*: An SQL query which is used to produce a single row which summarizes
the particular issue. Each query should return four columns and one row.
     - indicator: This should be the same as the `name` field above.
     - count: This should return total number of object which are flagged 
       by the particular check. The field should be returned as      a `vachar`. 
     - percent: Where possible this field should calculate the percentage of 
       the objects flagged by this particular test versus the 
       total number of objects in the same class.
     - description: A brief description of the the issue, probably the same as 
       the description field above.
- *details_sql*: An SQL query which should return one or more rows of all 
metadata objects which violate this particular metadata check. At the very least,
the query should consist of the UID and name of the object, and in certain cases
may contain other fields which will make the identification of the specific object easier in order to rectify the problem. 
- *severity*: This field is used to indicate the overall severity of a particular problem. 
    - INFO: Indicates that this is for information only.
    - WARNING: A warning indicates that this may be a problem, but not 
    necessarily an error. It is however recommended to triage these issues.
    - SEVERE: An error which should be fixed, but which may not necessarily lead to
    the system not functioning. 
    - CRITICAL: An error which must be fixed, and which may lead to end-user
    error or system crashes.
- *introduction*: A brief synopsis of the problem including its significance and origin.
- *recommendation*: A recommended procedure of how to address the issue is included in this field. 


An R Markdown report has been included to run all of 
the queries and organize them into an HTML report. More information on
how to run the R Markdown report can be found in the next section.  

It is also possible to run the queries individually directly on the DHIS2 database, 
if you are looking to isolate and address a particular problem. You can simply
copy and the `details_query` from the particular YAML file of interest, and 
either create an SQL View in DHIS2 and view the results there. Alternatively,
if you have access to the DHIS2 database, you could retrieve the results
directly from a database console.

## How to use the R Markdown report

- [Download](https://www.r-project.org/) and install a version of R for your 
operating system. 
- [Download](https://www.rstudio.com/products/rstudio/download/) and install
R Studio for your operating system. 
- [Download](https://git-scm.com/downloads) and install the git source control management software for your operating system.
- Clone the [source](https://github.com/dhis2/metadata-assessment) of this repository to your system. 
- Install all dependencies for the markdown report by invoking the following commands
in the R console.

```R
if (!require("pacman")) install.packages("pacman")
pacman::p_load(jsonlite, httr,purrr,knitr,magrittr,ggplot2,
DT,dplyr,yaml,knitr,rmarkdown,dplyr,readr)
```

- Create a file called `.Rprofile` in the top level directory of the cloned git repository.
This should only be done on a private computer, since you will need to store authentication 
details in this file. Alternatively, you can execute the commands in the R 
console, if you are not comfortable storing authentication details in a 
text file. The file should contain the following commands. 

```R
Sys.setenv(baseurl="http://localhost:8080/")
Sys.setenv(username="admin")
Sys.setenv(password="district")
Sys.setenv(cleanup_views = FALSE)
Sys.setenv(dhis2_checks = TRUE)
```

You should replace each of the variables with your particular details. 

- *baseurl*: This should be the URL of your server. Please take note of using 
https instead of http. Also, the URL should end with a final "/".
- *username*: Username of the user used to authenticate with the DHIS2 instance. 
This user should at least have the ability to create SQL views. 
- *password*: Password of the user which will connect to DHIS2. Take note
that this password will be stored in clear text, so you should not  store
this on a shared computer environment.
- *cleanup_views*: If set to `TRUE` the SQL Views created during the generation
of the report will be deleted after the report completes.
- *dhis2_checks*: If set to `TRUE`, results from the DHIS2 data integrity
checks will also be integrated into the report. Please take note, that 
these integrity checks may take a very long time to run on larger databases. 


Once you have completed each of these steps, open up the file `dhis2_metadata_assessment.Rmd`
in RStudio. Press the "Knit" button, and wait for the report to complete. The report 
will upload and create a series of SQL Views on your DHIS2 instance, and then 
retrieve each of the results to combine them into a single HTML page. 

The report is organized into a series of sections. The first section is a summary
table which contains an overview of the results of each query. The second
section presents summary figures and graphs related to users. The third section
contains essentially the same information as the summary table, but also includes
written guidance which helps explain the particular details of the problem, as well
as a recommended approach of how to solve them. The last optional section of the 
report contains the results of the DHIS2 integrity checks, if you chose to enable
them during the generation of the report.