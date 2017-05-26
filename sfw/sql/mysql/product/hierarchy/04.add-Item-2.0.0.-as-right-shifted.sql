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
--
SELECT '== START == adding item 2.0.0' AS '' ; 
SELECT '== START == adding an item on the right of existing item' AS '' ; 
--
-- lock the table 
LOCK TABLE Item write ;
--  
-- the point to shift to right is the last sibling's id
SELECT @pRightRank := RightRank from Item where ItemId=1 ;
--
-- shift the shiftable left ranks by two positions
UPDATE Item set LeftRank = ( LeftRank + 2 ) where LeftRank > @pRightRank; 
--
-- shift the shiftable right rannks by two positions
UPDATE Item set RightRank = ( RightRank + 2 ) where RightRank > @pRightRank ; 
--
-- perform the addition of the the new item
INSERT into Item VALUES ( 2 , 1 , NULL , 1 , @pRightRank+1 , @pRightRank+2,'2.0.0' ) ;
--
-- tell the user 
SELECT '== STOP == adding item 2.0.0' AS '' ;
--
-- verify the result 
SELECT 'AND CHECK ' AS '' ; 
SELECT * FROM Item ; 
--
--allow others to write to the table as well 
UNLOCK TABLES ; 
