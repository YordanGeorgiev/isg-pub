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
SELECT '== START == apply the logical sequence ... ' AS ''; 
--
SET @rank:=0 ;
update Item
set SeqId=@rank:=@rank+1 
order by LeftRank 
; 

SELECT 'AND CHECK ' AS ''
; 
SELECT * from Item order by SeqId  
; 
SELECT '== STOP  == apply the logical sequence ' AS '' ; 
--
--allow others to write to the table as well 
