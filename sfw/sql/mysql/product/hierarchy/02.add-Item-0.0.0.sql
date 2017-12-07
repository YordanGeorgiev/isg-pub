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
--
SELECT '== START == adding the first top most item ' AS '' ; 
INSERT INTO Item values ( 0 , 0 , NULL , 1 , 1 , 2 , '0.0.0' );
SELECT '== STOP  == added the first top most item ' AS '' ; 
SELECT '... and check: ' AS '';
SELECT * FROM Item order by ItemId ; 
