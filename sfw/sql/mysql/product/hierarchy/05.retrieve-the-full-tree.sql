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
SELECT '== START == retrieve the full tree of the table' AS '' ; 

	SELECT node.Name
	FROM Item AS node,
	Item AS parent
	WHERE 1=1
	AND node.LeftRank 
		BETWEEN parent.LeftRank AND parent.RightRank
	-- the branch bellow to retrieve all the branches
	AND parent.ItemId = '0'
	ORDER BY node.LeftRank
 ;




SELECT '== STOP  == retrieve the full tree of the table' AS '' ; 
