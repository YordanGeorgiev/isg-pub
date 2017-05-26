
	DROP TABLE IF EXISTS `Error`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	CREATE TABLE `Error` (
		`ErrorId` bigint NOT NULL UNIQUE
	 , `Level`				smallint 		NOT NULL 
	 , `SeqId`				bigint 			NOT NULL 
	 , `DocId`				bigint 			NOT NULL 
    , `LeftRank`			bigint			NOT NULL
 	 , `RightRank`			bigint			NOT NULL
 	 , `LogicalOrder`					varchar(30) 	NOT NULL
	 , `Type` varchar(14) DEFAULT NULL
	 , `Name` varchar(200) NOT NULL
	 , `Description` varchar(4000) DEFAULT NULL
	 , `UpdateTime` datetime DEFAULT NULL
	 , `FileType` varchar(10) DEFAULT NULL
	 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;


	-- now check that the table exists 
	SHOW TABLES LIKE 'Error';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='Error' ; 


