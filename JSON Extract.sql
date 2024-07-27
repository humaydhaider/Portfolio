

DECLARE @JSON_TABLE NVARCHAR(MAX);

-- Loading JSON Table into a variable 

SELECT @JSON_TABLE = BulkColumn
FROM OPENROWSET (BULK 'C:\Users\Humayd PC\Downloads\Dataset 2.json', SINGLE_CLOB) AS JSON;

-- Extracting Columns List, accounting for two "fields" in the JSON. 
WITH JSONFields AS (
    SELECT
		A.[Key],
        JSON_VALUE(B.value, '$.source.extract.column') AS ColumnName
    FROM
        OPENJSON(@JSON_TABLE, '$.recordSet') AS A
    CROSS APPLY OPENJSON(A.value, '$.field') AS B
)
SELECT 
	
    ColumnName
FROM
    JSONFields
WHERE
    ColumnName IS NOT NULL
ORDER BY [Key]  
