	DROP TABLE IF EXISTS `SourceField`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	CREATE TABLE `SourceField` (

		  `SourceFieldId` bigint 			NOT NULL UNIQUE
		, `Level`			int 				NOT NULL
		, `SeqId`			bigint			NOT NULL
		, `LeftRank`		bigint			NOT NULL
		, `RightRank`		bigint			NOT NULL
 	   , `LogicalOrder`  varchar(30) 	NOT NULL
		, `TableName`	   varchar(50)		NOT NULL
		, `Name`				varchar(50) 	NOT NULL 
		, `DataType`		varchar(50)		NOT NULL
		, `IsNull`			smallint			NOT NULL
		, `Source`			varchar(100)	NOT NULL
		, `Description`	varchar(1000)	NOT NULL
		, `DoUse`			smallint			NOT NULL
		, `DwTable`			varchar(50) 	NOT NULL 
		, `DwColumn`		varchar(50) 	NOT NULL 
		, `UpdateTime`		datetime			NOT NULL 

	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertSourceFieldUpdateTime` ;

	CREATE TRIGGER `trgOnInsertSourceFieldUpdateTime` BEFORE INSERT ON  `SourceField` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 


	DROP TRIGGER IF EXISTS `trgOnUpdateSourceFieldUpdateTime` ;
	
	CREATE TRIGGER `trgOnUpdateSourceFieldUpdateTime` BEFORE UPDATE ON  `SourceField` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'SourceField';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='SourceField' ; 




/*
-- VersionHistory
1.0.0. -- 2014-11-14 22:58:03 -- init 

*/
