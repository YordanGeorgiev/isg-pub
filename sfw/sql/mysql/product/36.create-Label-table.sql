	DROP TABLE IF EXISTS `Label`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	CREATE TABLE `Label` (
		`LabelId` 			bigint 			NOT NULL UNIQUE
	 , `Level`				smallint 		NOT NULL 
	 , `SeqId`				bigint 			NOT NULL 
	 , `LeftRank`			bigint			NOT NULL
	 , `RightRank`			bigint			NOT NULL
	 , `LogicalOrder`		varchar(30) 	NOT NULL
	 , `Status` 			varchar(12) 	DEFAULT NULL
	 , `Name` 				varchar(200) 	NOT NULL
	 , `Description` 		varchar(4000) 	DEFAULT NULL
	 , `ItemName` 			varchar(4000) 	DEFAULT NULL
	 , `ItemId` 			bigint			NOT NULL DEFAULT 0
	 , `UpdateTime` 		datetime 		DEFAULT NULL	
	 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertLabelUpdateTime` ;
	
	/*
	CREATE TRIGGER `trgOnInsertLabelUpdateTime` BEFORE INSERT ON  `Label` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 
	*/


	DROP TRIGGER IF EXISTS `trgOnUpdateLabelUpdateTime` ;
	/*	
	CREATE TRIGGER `trgOnUpdateLabelUpdateTime` BEFORE UPDATE ON  `Label` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 
	*/
	-- now check that the table exists 
	SHOW TABLES LIKE 'Label';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='Label' ; 




/*
-- VersionHistory
1.0.2. -- 2014-11-27 09:37:45 -- ysg -- added DocId
1.0.1. -- 2014-06-29 19:41:18 -- ysg -- removed attributes
1.0.0. -- 2014-07-19 09:43:38 -- ysg -- init 

*/
