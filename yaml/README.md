SQL files for the metadata assessment report should consist of a pair of queries.
These queries are meant to be able to be used in both the metadata assessment
report as well as interactively on the database by copying and pasting. 
However, in order to ensure that the queries can be imported as metadata
into DHIS2, a semi-structued text file is used to provide necessary 
bits of information. 

The header of each set of queries should contain the following formatted text. 

An example is provided below. 

--type: summary
--uid: U5DK7LdyJre
--name: abandoned_dashboards_S
--description: Dashboards with 1 or fewer views over the past three years
--detail_uid: Dfjw69AKQln


Note that these are SQL comments, which ensures that the content of each SQL
file can be easily copy and pasted when using the queires directly 
with a database. 

A description of each field is provided below. 

- type: Should be either "summary" or "details"
- uid: A DHIS2 uid used to indentify the query. 
- name: Should consist of a snake-cased name which provides a succint description
of the action of the query. The name should end in either "_S" for a summary
query or "_D" for a details query. 
- description: A short human readable description of the issue which 
the query identifies. 
- detail_uid: Only applicable to summary queries. This should provide the uid
of the details query which is related to each summary query. 