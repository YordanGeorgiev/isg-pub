	DROP TABLE IF EXISTS `Idea`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


  CREATE TABLE `Idea` (

	  `IdeaId` bigint 			NOT NULL UNIQUE
	, `Level`				smallint 		NOT NULL 
	, `SeqId`				bigint 			NOT NULL 
	, `LeftRank`			bigint			NOT NULL
	, `RightRank`			bigint			NOT NULL
	, `LogicalOrder`		varchar(50) 		NOT NULL /* */
	, `Status` 			varchar(12) 	DEFAULT NULL
	, `Name`				varchar(50) 		NOT NULL /* the name of the url param as written in the address field */
	, `Prio`				smallint 			NOT NULL /* the name of the url param as written in the address field */
	, `Description`	varchar(1000)		NOT NULL
	, `UpdateTime`		datetime				NOT NULL 

	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertIdeaUpdateTime` ;

	CREATE TRIGGER `trgOnInsertIdeaUpdateTime` BEFORE INSERT ON  `Idea` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 


	DROP TRIGGER IF EXISTS `trgOnUpdateIdeaUpdateTime` ;
	
	CREATE TRIGGER `trgOnUpdateIdeaUpdateTime` BEFORE UPDATE ON  `Idea` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'Idea';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='Idea' ; 



/*
-- VersionHistory
1.0.0. -- 2015-01-01 22:58:03 -- init 

*/
