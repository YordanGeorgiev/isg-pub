-- MySQL dump 10.15  Distrib 10.0.26-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: futu_fone_en
-- ------------------------------------------------------
-- Server version	10.0.26-MariaDB-1~xenial

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Git`
--

DROP TABLE IF EXISTS `Git`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Git` (
  `GitId` 			bigint(20) NOT NULL,
  `Level` 			smallint(6) NOT NULL,
  `SeqId` 			bigint(20) NOT NULL,
  `LeftRank` 		bigint(20) NOT NULL,
  `RightRank` 		bigint(20) NOT NULL,
  `Status` 			varchar(12) DEFAULT NULL,
  `Type` 			varchar(14) DEFAULT NULL,
  `Prio` 			smallint(6) DEFAULT NULL,
  `Name` 			varchar(200) NOT NULL,
  `Description` 	varchar(4000) DEFAULT NULL,
  `SrcCode` 		varchar(4000) DEFAULT NULL,
  `UpdateTime` 	datetime DEFAULT NULL,
  `FileType` 		varchar(10) DEFAULT NULL,
  UNIQUE KEY 		`GitId` (`GitId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

-- now check that the table exists 
SHOW TABLES LIKE 'Git';

SELECT FOUND_ROWS() AS 'FOUND'  ;

-- NOW CHECK THE COLUMNS
SELECT CONCAT ( TABLE_NAME  , '.' , COLUMN_NAME  )
AS 'TABLE.COLUMNS'
from information_schema.COLUMNS
WHERE 1=1
AND TABLE_SCHEMA=DATABASE()
AND TABLE_NAME='Git' ; 
