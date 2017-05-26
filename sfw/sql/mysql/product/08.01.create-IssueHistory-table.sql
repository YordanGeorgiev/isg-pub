	DROP TABLE IF EXISTS `IssueHistory`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	CREATE TABLE `IssueHistory` (
		`IssueHistoryId` 			bigint 			NOT NULL UNIQUE
	,	`IssueId` 			bigint 			NOT NULL UNIQUE
	 , `Level`				smallint 		NOT NULL 
	 , `SeqId`				decimal 			NOT NULL -- because there must be order !!!
	 , `LeftRank`			bigint			NOT NULL
	 , `RightRank`			bigint			NOT NULL
	 , `LogicalOrder`		varchar(30) 	NOT NULL
	 , `Prio`				smallint 		NOT NULL DEFAULT '0'
	 , `Status` 			varchar(12) 	DEFAULT NULL
	 , `Type` 				varchar(14) 	DEFAULT NULL
	 , `Name` 				varchar(200) 	NOT NULL
	 , `Description` 		varchar(4000) 	DEFAULT NULL
	 , `SrcCode` 			varchar(4000) 	DEFAULT NULL
--	 , `AllocatedCredit` bigint 			DEFAULT NULL
--	 , `UtilizedCredit` 	bigint	 		DEFAULT NULL
--	 , `Owner` 				varchar(50) 	DEFAULT 'ysg'
--	 , `DeadLine` 			datetime 		DEFAULT NULL
	 , `UpdateTime` 		datetime 		DEFAULT NULL	
	 , `FileType` 			varchar(10) 	DEFAULT NULL
	 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertIssueHistoryUpdateTime` ;

	CREATE TRIGGER `trgOnInsertIssueHistoryUpdateTime` BEFORE INSERT ON  `IssueHistory` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 


	DROP TRIGGER IF EXISTS `trgOnUpdateIssueHistoryUpdateTime` ;
	
	CREATE TRIGGER `trgOnUpdateIssueHistoryUpdateTime` BEFORE UPDATE ON  `IssueHistory` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'IssueHistory';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='IssueHistory' ; 




/*
-- VersionHistory
1.0.2. -- 2014-11-27 09:37:45 -- ysg -- added DocId
1.0.1. -- 2014-06-29 19:41:18 -- ysg -- removed attributes
1.0.0. -- 2014-07-19 09:43:38 -- ysg -- init 

*/
