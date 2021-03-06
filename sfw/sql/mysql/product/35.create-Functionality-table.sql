DROP TABLE IF EXISTS `Functionality`;

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Functionality` (

   `FunctionalityId`       bigint NOT NULL UNIQUE
 , `Level`				smallint 		NOT NULL 
 , `SeqId`				bigint 			NOT NULL 
 , `LeftRank`			bigint			NOT NULL
 , `RightRank`			bigint			NOT NULL
 , `LogicalOrder`		varchar(30) 	NOT NULL
 , `Status`   			varchar(20) 	NOT NULL
 , `Name`            varchar(200) 	NOT NULL
 , `Description`     varchar(4000) 	NOT NULL
 , `Weight`          smallint DEFAULT NULL
 , `FileType`        varchar(10) DEFAULT NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;


	-- now check that the table exists 
	SHOW TABLES LIKE 'Functionality';
	
	SELECT FOUND_ROWS() AS 'FOUND'  ;

	-- NOW CHECK THE COLUMNS
	SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
	AS 'TABLE.COLUMNS'
	from information_schema.COLUMNS
	WHERE 1=1
	AND TABLE_SCHEMA=DATABASE()
	AND TABLE_NAME='Functionality' ; 
