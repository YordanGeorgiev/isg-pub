	DROP TABLE IF EXISTS `VersionHistory`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	/* Some description for the table : VersionHistory */
  CREATE TABLE `VersionHistory` (

	  `VersionHistoryId` bigint 			NOT NULL UNIQUE	/* a technical id - OBLIGATORY */
	, `Level`				smallint 		NOT NULL /* models the level in the doc hierarchy in gui - OBLIGATORY */
	, `SeqId`				bigint 			NOT NULL	/* defines the logical order of the items in gui - OBLIGATORY */
	, `LeftRank`			bigint			NOT NULL
	, `RightRank`			bigint			NOT NULL
 	, `LogicalOrder`	   varchar(30) 	NOT NULL
	, `Version`				varchar(50) 	NOT NULL /* the version num */
	, `Name`					varchar(50) 	NOT NULL /* the name of the item is used as the heading in ui - OBLIGATORY */
	, `Author`				varchar(50) 	NOT NULL /* the author of the version - OBLIGATORY */
	, `Description`		varchar(1000)	NOT NULL /* the description is used as the paragraphs - OBLIGATORY */
	, `Package`				varchar(100)	NOT NULL /* the description is used as the paragraphs - OBLIGATORY */
	, `UpdateTime`			datetime			NOT NULL /* the update time for this record - OBLIGATORY */

	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertVersionHistoryUpdateTime` ;

	CREATE TRIGGER `trgOnInsertVersionHistoryUpdateTime` BEFORE INSERT ON  `VersionHistory` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 


	DROP TRIGGER IF EXISTS `trgOnUpdateVersionHistoryUpdateTime` ;
	
	CREATE TRIGGER `trgOnUpdateVersionHistoryUpdateTime` BEFORE UPDATE ON  `VersionHistory` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'VersionHistory';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='VersionHistory' ; 



/*
-- VersionHistory --
1.0.0. -- 2015-01-06 20:48:52 -- init 

*/
