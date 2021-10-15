SQL files for the metadata assessment report should consist of a pair of queries
defined in a YAML control file. 
These queries are meant to be able to be used in both the metadata assessment
report as well as interactively on the database by copying and pasting. 
However, in order to ensure that the queries can be imported as metadata
into DHIS2, a structured text file is used to provide necessary 
bits of information. 

Each YAML file should contain the following fields. 
- name: This will be the name of the view when created on the DHIS2 server.  
Names should be unique across all queries. 
- description: A description of the query. 
- section: This field can be used to group related queires in the report. 
- section_order: This field can be used to order query results within a section. 
- summary_uid: A UID which will be used to identify the summary query. 
- summary_sql: Each summary SQL query should return a single line and consist of four columns. 
    - indicator: Should be the same as the "name" field. 
    - value: Should be a number which provides the total number of issues.
    -  percent: Should be a character string consisting of the percentage of 
 issues compared to the overall possible number of issues. 
    - description: The same as the description field above. 
- details_uid: UID for the query which should provide a full list of all issues.
- details_sql: The SQL for listing all issues, consisting of two columns "uid" and "name"

Note that all YAML files must be terminated with a final empty line.
