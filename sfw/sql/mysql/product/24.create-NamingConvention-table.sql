	DROP TABLE IF EXISTS `NamingConvention`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	/* Some description for the table : NamingConvention */
  CREATE TABLE `NamingConvention` (

	  `NamingConventionId` bigint 		NOT NULL UNIQUE	/* a technical id - OBLIGATORY */
	, `Level`				smallint 		NOT NULL /* models the level in the doc hierarchy in gui - OBLIGATORY */
	, `SeqId`				bigint 			NOT NULL /* defines the logical order of the items in gui - OBLIGATORY */
	, `DocId`				bigint 			NOT NULL	/* defines to which document this record belongs to - OBLIGATORY */ 
	, `LeftRank`			bigint			NOT NULL /* nestet set model - OBLIGATORY */
	, `RightRank`			bigint			NOT NULL /* nestet set model - OBLIGATORY */
 	, `LogicalOrder`	   varchar(30) 	NOT NULL /* nestet set model - OBLIGATORY */
	, `Name`					varchar(50) 	NOT NULL /* the name of the item is used as the heading in ui - OBLIGATORY */
	, `Pattern`				varchar(1000) 	NOT NULL /* the priority for this item ( OPTIONAL ) */
	, `Description`		varchar(1000)	NOT NULL /* the description is used as the paragraphs - OBLIGATORY */
	, `UpdateTime`			datetime			NOT NULL /* the update time for this record - OBLIGATORY */

	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertNamingConventionUpdateTime` ;

	CREATE TRIGGER `trgOnInsertNamingConventionUpdateTime` BEFORE INSERT ON  `NamingConvention` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 


	DROP TRIGGER IF EXISTS `trgOnUpdateNamingConventionUpdateTime` ;
	
	CREATE TRIGGER `trgOnUpdateNamingConventionUpdateTime` BEFORE UPDATE ON  `NamingConvention` 
	FOR EACH ROW 
	SET NEW.UpdateTime = NOW()
	; 

	-- now check that the table exists 
	SHOW TABLES LIKE 'NamingConvention';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='NamingConvention' ; 



/*
-- VersionHistory
1.0.0. -- 2015-01-06 20:48:52 -- init 

*/
