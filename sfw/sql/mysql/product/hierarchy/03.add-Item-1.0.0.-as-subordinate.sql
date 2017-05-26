--+-----------+--------------+------+-----+---------+-------+
--| Field     | Type         | Null | Key | Default | Extra |
--+-----------+--------------+------+-----+---------+-------+
--| ItemId    | bigint(20)   | NO   | PRI | NULL    |       |
--| Level     | smallint(6)  | NO   |     | NULL    |       |
--| SeqId     | bigint(20)   | YES  |     | NULL    |       |
--| DocId	  | bigint(20)   | YES  |     | NULL    |       |
--| LeftRank  | bigint(20)   | NO   |     | NULL    |       |
--| RightRank | bigint(20)   | NO   |     | NULL    |       |
--| Name      | varchar(200) | NO   |     | NULL    |       |
--+-----------+--------------+------+-----+---------+-------+

SELECT '== START == adding item 1.0.0' AS '' ; 
--
-- lock the table 
LOCK TABLE Item write ;


--  
-- set the parent if bellow which to add the node
SELECT @pParentItemId := '0' ; 


-- get the point to shift 
SELECT @pLeftRank := LeftRank from Item where ItemId = @pParentItemId ; 


--
-- shift the shiftable left ranks by two positions
UPDATE Item set RightRank = ( RightRank + 2 ) where RightRank > @pLeftRank; 
UPDATE Item set LeftRank = ( LeftRank + 2 ) where LeftRank > @pLeftRank; 


INSERT into Item VALUES ( 1 , 1 , NULL , 1 , @pLeftRank+1 , @pLeftRank+2,'1.0.0' ) ;


-- tell the user 
SELECT '== STOP == adding item 1.0.0' AS '' ;
--
-- verify the result 
SELECT 'AND CHECK ' AS '' ; 
SELECT * FROM Item ; 
--
--allow others to write to the table as well 
UNLOCK TABLES ; 
