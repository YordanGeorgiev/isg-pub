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
SELECT '== START == calculate the depths or Levels ' AS '';
SELECT node.name, (COUNT(parent.name) - (sub_tree.depth + 1)) AS depth
FROM Item AS node,
Item AS parent,
Item AS sub_parent,
(
	SELECT node.name, (COUNT(parent.name) - 1) AS depth
	FROM Item AS node,
	Item AS parent
	WHERE node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
	AND node.ItemId = 0
	GROUP BY node.name
	ORDER BY node.LeftRank
)AS sub_tree
WHERE node.LeftRank BETWEEN parent.LeftRank AND parent.RightRank
AND node.LeftRank BETWEEN sub_parent.LeftRank AND sub_parent.RightRank
AND sub_parent.name = sub_tree.name
GROUP BY node.name
ORDER BY node.LeftRank;
SELECT '== STOP  == calculate the depths or Levels ' AS '';
--allow others to write to the table as well 
