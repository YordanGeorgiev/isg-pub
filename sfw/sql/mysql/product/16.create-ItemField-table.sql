	DROP TABLE IF EXISTS `ItemField`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	CREATE TABLE `ItemField` (
		`ItemFieldId` 		bigint 			NOT NULL UNIQUE
	 , `Level`				smallint 		NOT NULL 
	 , `SeqId`				bigint 			NOT NULL 
	 , `DocId`				bigint 			NOT NULL 
    , `LeftRank`			bigint			NOT NULL
 	 , `RightRank`			bigint			NOT NULL
 	 , `LogicalOrder`					varchar(30) 	NOT NULL
-- , `OrdinalNumber`	smallint 		NOT NULL 
	 , `SourceSystem`		varchar(20)	 	NOT NULL
--	 , `DatabaseName`		varchar(50)	 	NOT NULL
	 , `TableName` 		varchar(50)	 	NOT NULL
	 , `Name` 				varchar(50) 	NOT NULL
--	 , `IsNullable` 		smallint		 	DEFAULT NULL
--	 , `DataType` 			varchar(20) 	DEFAULT NULL
--	 , `MaxLength` 		smallint		 	DEFAULT NULL
--	 , `OctetLength` 		smallint		 	DEFAULT NULL
--	 , `Precision` 		smallint		 	DEFAULT NULL
--	 , `Scale` 				smallint		 	DEFAULT NULL
	 , `Description` 		varchar(4000) 	DEFAULT NULL
	 , `UpdateTime` 		datetime 		DEFAULT NULL	
	 , `FileType` 			varchar(10) 	DEFAULT NULL
	 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertItemFieldUpdateTime` ;

	CREATE TRIGGER `trgOnInsertItemFieldUpdateTime` BEFORE INSERT ON  `ItemField` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 


	DROP TRIGGER IF EXISTS `trgOnUpdateItemFieldUpdateTime` ;
	
	CREATE TRIGGER `trgOnUpdateItemFieldUpdateTime` BEFORE UPDATE ON  `ItemField` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'ItemField';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='ItemField' ; 




/*
-- VersionHistory
1.0.0. -- 2014-11-14 22:58:03 -- init 

*/
