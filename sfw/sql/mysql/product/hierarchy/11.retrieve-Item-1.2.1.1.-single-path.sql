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
SELECT '== START == get item 1.2.1.1 single-path' AS '' ; 
SELECT @pItemId := '6' ; 
SELECT parent.name
FROM Item AS node,
Item AS parent
WHERE node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
AND node.ItemId = @pItemId
ORDER BY parent.LeftRank;

SELECT '== STOP  == get item 1.2.1.1 single-path' AS '' ; 
