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
SELECT '== START == deleting a leaf node item 1.2.1.1' AS '' ; 
--
-- lock the table 
LOCK TABLE Item write ;
-- 
SELECT @pLeftRank := LeftRank, @pRightRank := RightRank, @pWidth := RightRank - LeftRank + 1
FROM Item
WHERE ItemId=6 ; 


DELETE FROM Item WHERE LeftRank BETWEEN @pLeftRank AND @pRightRank;


UPDATE Item SET RightRank = RightRank - @pWidth WHERE RightRank > @pRightRank;
UPDATE Item SET LeftRank = LeftRank - @pWidth WHERE LeftRank > @pRightRank;
UNLOCK TABLES ; 
--
-- tell the user 
SELECT '== STOP == deleting a leaf node item 1.2.1.1' AS '' ;
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
FROM Item AS node,
Item AS parent
WHERE node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
GROUP BY node.name
ORDER BY node.LeftRank;
SELECT '== STOP  == display the tree hierarchy' AS '' ; 
--
--allow others to write to the table as well 
