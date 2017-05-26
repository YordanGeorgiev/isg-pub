	DROP TABLE IF EXISTS `ShortCut`;
	/*!40101 SET @saved_cs_client     = @@character_set_client */;
	/*!40101 SET character_set_client = utf8 */;


	/* models a shortcut description */
	CREATE TABLE `ShortCut` (
		  ShortCutId			bigint					NOT NULL UNIQUE
		, Level					smallint					not null
		, SeqId					bigint					not null
		, DocId					smallint					not null
		, LeftRank 				bigint 					not null
		, RightRank				bigint					not null 
		, Weight					int 						not null
		, RunTime				varchar(50) 			not null
		, ShortcutSequence	varchar(50) 			not null
		, Name					varchar(100) 			not null /* the name of the shortcut / action to  be performed */
		, Description  		varchar(1000)			NOT NULL /* the description is used as the paragraphs - OBLIGATORY */


	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	/*!40101 SET character_set_client = @saved_cs_client */;
	
	
	-- now check that the table exists 
	SHOW TABLES LIKE 'ShortCut';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='ShortCut' ; 



/*

-- VersionHistory
-----------------------------------------------------------
1.0.0. -- 2015-03-17 08:28:57 

*/
