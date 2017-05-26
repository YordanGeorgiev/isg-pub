	DROP TABLE IF EXISTS `ProtoItem`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	/* Some description for the table : ProtoItem */
  CREATE TABLE `ProtoItem` (

	  `ProtoItemId` bigint 			NOT NULL UNIQUE	/* a technical id - OBLIGATORY */
	, `Name`					varchar(50) 		NOT NULL /* the name of the item is used as the heading in ui - OBLIGATORY */
	, `Description`		varchar(1000)		NOT NULL /* the description is used as the paragraphs - OBLIGATORY */

	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	DROP TRIGGER IF EXISTS `trgOnInsertProtoItemUpdateTime` ;

	-- now check that the table exists 
	SHOW TABLES LIKE 'ProtoItem';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='ProtoItem' ; 



/*
-- VersionHistory
1.0.0. -- 2015-01-06 20:48:52 -- init 

*/
