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
SELECT '== START == display the tree hierarchy' AS '' ; 
	SELECT CONCAT( REPEAT('  ', COUNT(parent.Name) - 1), node.name) AS name
	FROM 
	Item AS node,
	Item AS parent
	WHERE 1=1 
	AND node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
	AND parent.ItemId=0
	GROUP BY node.name
	ORDER BY node.LeftRank
 ;
SELECT '== STOP  == display the tree hierarchy' AS '' ; 
