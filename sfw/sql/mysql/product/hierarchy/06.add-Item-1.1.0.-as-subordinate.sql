--+-----------+--------------+------+-----+---------+-------+
--| Field     | Type         | Null | Key | Default | Extra |
--+-----------+--------------+------+-----+---------+-------+
--| ItemId    | bigint(20)   | NO   | PRI | NULL    |       |
--| Level     | smallint(6)  | NO   |     | NULL    |       |
--| SeqId     | bigint(20)   | YES  |     | NULL    |       |
--| LeftRank  | bigint(20)   | NO   |     | NULL    |       |
--| RightRank | bigint(20)   | NO   |     | NULL    |       |
--| Name      | varchar(200) | NO   |     | NULL    |       |
--+-----------+--------------+------+-----+---------+-------+
SELECT '== START == adding item 1.1.0' AS '' ; 
--
-- lock the table 
LOCK TABLE Item write ;
--  
-- the point to shift is the parent id previous level
-- Obs get parent item by its id !!!
SELECT @pLeftRank := LeftRank from Item where ItemId=1;
--
-- shift the shiftable left ranks by two positions
UPDATE Item set LeftRank = ( LeftRank + 2 ) where LeftRank > @pLeftRank; 
--
-- shift the shiftable right rannks by two positions
UPDATE Item set RightRank = ( RightRank + 2 ) where RightRank > @pLeftRank ; 
--
-- perform the addition of the the new item
INSERT into Item VALUES ( 3 , 2 , NULL , 1 , @pLeftRank+1 , @pLeftRank+2,'1.1.0' ) ;
--
-- tell the user 
SELECT '== STOP == adding item 1.1.0' AS '' ;
--
-- verify the result 
SELECT 'AND CHECK by id ordering' AS '' ; 
SELECT * FROM Item ORDER BY ItemId; 
--
-- sort the items 
SELECT 'AND CHECK by Logical ordering ' AS '' ; 
SELECT * FROM Item ORDER BY Name ; 
SELECT * FROM Item AS Node, Item AS parent 
WHERE Node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank 
AND parent.ItemId = '0'
ORDER BY Node.LeftRank asc
	;
--
--allow others to write to the table as well 
UNLOCK TABLES ; 
