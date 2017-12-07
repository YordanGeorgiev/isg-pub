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
--
SELECT '== START == adding item 1.2.1.1' AS '' ; 
--
-- lock the table 
LOCK TABLE Item write ;
--  
-- get the point to shift 
-- Obs get parent item by its id !!! Since the 1.2.1 
-- is the subordinate of the  1.2.0 item
SELECT @pLeftRank := LeftRank from Item where ItemId=5 ; 
--
-- shift the shiftable left ranks by two positions
UPDATE Item set LeftRank = ( LeftRank + 2 ) where LeftRank > @pLeftRank; 
--
-- shift the shiftable right rannks by two positions
UPDATE Item set RightRank = ( RightRank + 2 ) where RightRank > @pLeftRank ; 
--
-- perform the addition of the the new item
-- OBS !!! check the id 
INSERT into Item VALUES ( 6 , 4 , NULL , 1 , @pLeftRank+1 , @pLeftRank+2,'1.2.1.1' ) ;
UNLOCK TABLES ; 
--
-- tell the user 
SELECT '== STOP == adding item 1.2.1.1' AS '' ;
--
-- verify the result 
SELECT 'AND CHECK by id ordering' AS '' ; 
SELECT * FROM Item ORDER BY ItemId; 
--
-- sort the items 
--SELECT 'AND CHECK by Logical ordering ' AS '' ; 
--SELECT * FROM Item ORDER BY Name ; 
--SELECT * FROM Item AS Node, Item AS parent 
--WHERE Node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank 
--AND parent.ItemId = '0'
--ORDER BY Node.LeftRank asc
--	;
SELECT '== START == display the tree hierarchy' AS '' ; 
	SELECT CONCAT( REPEAT('  ', COUNT(parent.Name) - 1), node.name) AS name
	FROM 
	Item AS node,
	Item AS parent
	WHERE 1=1 AND node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
	GROUP BY node.name
	ORDER BY node.LeftRank
 ;
SELECT '== STOP  == display the tree hierarchy' AS '' ; 
--
--allow others to write to the table as well 
