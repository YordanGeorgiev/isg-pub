	DROP TABLE IF EXISTS `Item`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	CREATE TABLE `Item` (
		`ItemId` 			bigint 			NOT NULL UNIQUE
	 , `Level`				smallint 		NOT NULL 
	 , `SeqId` 				bigint 			NULL 
	 , `LeftRank`			bigint			NOT NULL
	 , `RightRank`			bigint			NOT NULL
	 , `Name` 				varchar(200) 	NOT NULL
	 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;

	-- now check that the table exists 
	SHOW TABLES LIKE 'Item';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='Item' ; 




/*
-- VersionHistory

*/
