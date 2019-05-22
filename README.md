# RIDE
Source Files
All the source files and the extract text files used in this development are all available in the git repository https://github.com/ra-hyde/RIDE.git

Assumptions
That you have either a neo4j Community or Enterprise edition server up and running
That you have the suitable rights to extract the SQL views
The script to import data into neo4j was run on a linux server

The main steps 

Extract SQL Meta Data
 The first step is to extract the data in a suitable format. This is done using 2 queries provided in the RIDE_sql.sql

1. The 1st extracts database structures down to field level in the format
Database
Schema
Table/View
Column


SELECT 
c.TABLE_CATALOG, 
c.TABLE_SCHEMA, 
c.TABLE_NAME, 
c.COLUMN_NAME
from INFORMATION_SCHEMA.COLUMNS c;


note that I have deliberately included Views even though foreign key are not linked to them.

2. The 2nd extract lists the foreign keys and the respective table.columns from and to in the format
Foreign Key Name
From Schema Name
From Table Name
From Column Name
To Schema Name
To Table Name
To Column Name


SELECT obj.name AS FK_NAME,
sch1.name AS [schema_name],
tab1.name AS [table],
col1.name AS [column],
sch2.name AS [referenced_schema],
tab2.name AS [referenced_table],
col2.name AS [referenced_column]
FROM sys.foreign_key_columns fkc
INNER JOIN sys.objects obj
ON obj.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tab1
ON tab1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas sch1
ON tab1.schema_id = sch1.schema_id
INNER JOIN sys.columns col1
ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
INNER JOIN sys.tables tab2
ON tab2.object_id = fkc.referenced_object_id
INNER JOIN sys.schemas sch2
ON tab2.schema_id = sch2.schema_id
INNER JOIN sys.columns col2
ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id;
The output from these 2 queries are saved, in this example, as RIDE_TabCol.txt and RIDE_RefInt.txt respectively as tab delimited files.

Load Meta Data into neo4j

Place the 2 tab delimited files in to the import directory of neo4j 
Ensure neo4j is running
Run the command highlighted (again, please note this is a linux command line. Mac and Windows implementations will vary) which runs RIDE_Build.cypher 

Note – the first line in this script deletes ALL nodes and relationships from the neo4j instance. Remove or comment out the line if you have other data loaded previously that is to be kept

cat ~/Apps/neo4j-community-3.4.9/import/RIDE_Build.cypher | ~/Apps/neo4j-community-3.4.9/bin/cypher-shell -u neo4j -p ******** --format plain

RIDE_Build.cypher
match (n) detach delete n;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///RIDE_TabCol.txt" AS row FIELDTERMINATOR '\t'
MERGE (db:Database {DatabaseName: row.TABLE_CATALOG})
MERGE (sch:Schema {SchemaName: row.TABLE_SCHEMA})
MERGE (sch)-[s:SCHEMA_OF]->(db)
MERGE (tab:Table {TableName: row.TABLE_NAME})
MERGE (tab)-[t:TABLE_OF]->(sch)
CREATE (col:Column {ColumnName: row.COLUMN_NAME})
CREATE (col)-[c:COLUMN_OF]->(tab);


USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///RIDE_RefInt.txt" AS row FIELDTERMINATOR '\t'
MATCH (fromtab:Table {TableName: row.table})
MATCH (fromcol:Column {ColumnName: row.column})
MATCH (fromcol)-[c:COLUMN_OF]->(fromtab)
MATCH (totab:Table {TableName: row.referenced_table})
MATCH (tocol:Column {ColumnName: row.referenced_column})
MATCH (tocol)-[tc:COLUMN_OF]->(totab)
MERGE (fromcol)-[ri:ForeignKey {FK_Name:row.FK_NAME} ]->(tocol);

Fire up the neo4j browser
Run the following query to return all nodes and relationships

MATCH (n) RETURN n;

