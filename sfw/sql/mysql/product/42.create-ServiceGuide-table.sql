	DROP TABLE IF EXISTS `ServiceGuide`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;



	CREATE TABLE `ServiceGuide` (

	  `ServiceGuideId` 	bigint 				NOT NULL UNIQUE
	, `Level`				smallint 		NOT NULL 
	, `SeqId`				bigint 			NOT NULL 
   , `LeftRank`			bigint			NOT NULL
 	, `RightRank`			bigint			NOT NULL
 	, `LogicalOrder`		varchar(30) 	NOT NULL
	, `Status`	 			varchar(12) 		DEFAULT NULL
	, `Prio` 				smallint 			DEFAULT NULL
	, `Name` 				varchar(200) 		NOT NULL
	, `Description` 		varchar(4000) 		DEFAULT NULL
	, `SrcCode`		 		varchar(4000) 		DEFAULT NULL
	, `UpdateTime` 		datetime 			DEFAULT NULL
	, `FileType` 			varchar(10) 		DEFAULT NULL
	 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;


	
	CREATE TRIGGER `trgOnInsertServiceGuideUpdateTime` BEFORE INSERT ON  `ServiceGuide` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 
	


	DROP TRIGGER IF EXISTS `trgOnUpdateServiceGuideUpdateTime` ;
	CREATE TRIGGER `trgOnUpdateServiceGuideUpdateTime` BEFORE UPDATE ON  `ServiceGuide` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'ServiceGuide';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='ServiceGuide' ; 



/*
-- VersionHistory
1.0.1. -- 2014-06-29 19:41:18 -- ysg -- removed attributes
1.0.0. -- 2014-07-19 09:43:38 -- ysg -- init 

*/
