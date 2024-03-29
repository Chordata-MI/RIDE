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
