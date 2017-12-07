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
SELECT '== START == adding item 1.2.1.2' AS '' ; 
--


-- lock the table 
LOCK TABLE Item write ;
--  
-- get the point to shift 
-- OBS !!! on which node on the right to shift
SELECT @pRightRank := RightRank from Item where ItemId=6 ; 
--
-- shift the shiftable left ranks by two positions
UPDATE Item set LeftRank = ( LeftRank + 2 ) where LeftRank > @pRightRank; 
--
-- shift the shiftable right rannks by two positions
UPDATE Item set RightRank = ( RightRank + 2 ) where RightRank > @pRightRank ; 
--
-- perform the addition of the the new item
-- OBS !!! the id 
INSERT into Item VALUES ( 7 , 1 , NULL , 1 , @pRightRank+1 , @pRightRank+2,'1.2.1.2' ) ;

SET @rank:=0 ;
update Item
set SeqId=@rank:=@rank+1 
order by LeftRank 
; 
--
-- tell the user 
--
-- verify the result 
SELECT 'AND CHECK by id ordering' AS '' ; 
SELECT * FROM Item ORDER BY LeftRank; 
--
SELECT '== STOP == adding item 1.2.1.2' AS '' ;
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
FROM Item AS node,
Item AS parent
WHERE node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
GROUP BY node.name
ORDER BY node.LeftRank;
SELECT '== STOP  == display the tree hierarchy' AS '' ; 
--
--allow others to write to the table as well 
