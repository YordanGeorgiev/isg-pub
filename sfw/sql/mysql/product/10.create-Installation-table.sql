	DROP TABLE IF EXISTS `Installation`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;



	CREATE TABLE `Installation` (

	  `InstallationId` 	bigint 				NOT NULL UNIQUE
	, `Level`				smallint 		NOT NULL 
	, `SeqId`				bigint 			NOT NULL 
   , `LeftRank`			bigint			NOT NULL
 	, `RightRank`			bigint			NOT NULL
	, `Status`	 			varchar(12) 		DEFAULT NULL
	, `Type` 				varchar(14) 		DEFAULT NULL
	, `Prio` 				smallint 			DEFAULT NULL
	, `Name` 				varchar(200) 		NOT NULL
-- , `DeadLine` 			datetime 			DEFAULT NULL
--	, `Hours` 				varchar(3) 			DEFAULT NULL
	, `Description` 		varchar(4000) 		DEFAULT NULL
	, `SrcCode`		 		varchar(4000) 		DEFAULT NULL
	, `UpdateTime` 		datetime 			DEFAULT NULL
	, `FileType` 			varchar(10) 		DEFAULT NULL
	 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;


	
	CREATE TRIGGER `trgOnInsertInstallationUpdateTime` BEFORE INSERT ON  `Installation` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 
	


	DROP TRIGGER IF EXISTS `trgOnUpdateInstallationUpdateTime` ;
	CREATE TRIGGER `trgOnUpdateInstallationUpdateTime` BEFORE UPDATE ON  `Installation` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'Installation';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='Installation' ; 



/*
-- VersionHistory
1.0.1. -- 2014-06-29 19:41:18 -- ysg -- removed attributes
1.0.0. -- 2014-07-19 09:43:38 -- ysg -- init 

*/
