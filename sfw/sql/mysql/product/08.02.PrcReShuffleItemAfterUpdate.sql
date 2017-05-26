DELIMITER //

DROP PROCEDURE prcReShuffleItemAfterUpdate ; 

CREATE PROCEDURE prcReShuffleItemAfterUpdate
(
 	IN pSeqId bigint
 ,	IN pItemId bigint 

)
BEGIN
	 -- If an item exist and its SeqId has NOT changed do nothing  
    IF EXISTS (SELECT 1 FROM Item WHERE Item.SeqId = pSeqId AND Item.ItemId = pItemId) THEN
	 	SELECT 0 ; 
	 -- If an item DOES NOT exist RESHUFFLE
    ELSE
      -- UPDATE ext_words_count SET word_count = word_count + 1 WHERE word = NEW.word;
		set @i=0;
		set @icount = 0 ; 
		set @pParentItemId = 0 ; 

		SELECT count(*) from Item INTO @icount ; 

		while @i < @icount do
			DECLARE dLevel int ; 
			DECLARE dItemId int ; 
		SELECT ItemId from Item WHERE 1=1 AND Item.SeqId >= @i INTO dItemId LIMIT 1 ; 
		SELECT Level from Item WHERE 1=1 AND Item.ItemId = dItemId ;
		-- push the duplicate one SeqId up
		UPDATE Item SET SeqId = Seqid + 1 WHERE SeqId = @i AND ItemId <> dItemId ; 

			CASE dLevel
				-- the 
				WHEN 0 THEN
					-- if this is the root item
    				IF EXISTS (SELECT 1 FROM Item WHERE Item.ItemId = pItemId AND Item.ItemId =  0) THEN
						UPDATE Item SET Level = 0, SeqId = 1 , LeftRank =  1 , RightRank = 2 
						WHERE 1=1 and Item.ItemId = 0 ; 
					ELSE 
						UPDATE Item SET Level = 0, SeqId = 2 WHERE 1=1 and Item.Itemid = 1  ; 
					END IF ; 
				WHEN dLevel = 1 THEN 
					-- lock the table 
					LOCK TABLE Item write ;

					--  
					-- set the parent if bellow which to add the node
					SELECT @pParentItemId := '0' ; 


					-- get the point to shift 
					SELECT @pLeftRank := LeftRank from Item where ItemId = @pParentItemId ; 


					--
					-- shift the shiftable left ranks by two positions
					UPDATE Item set RightRank = ( RightRank + 2 ) where RightRank > @pLeftRank; 
					UPDATE Item set LeftRank = ( LeftRank + 2 ) where LeftRank > @pLeftRank; 


					UPDATE Item set VALUES ( 1 , 1 , NULL , 1 , @pLeftRank+1 , @pLeftRank+2,'1.0.0' ) ;
					UNLOCK TABLES ; 
					-- stop check the level

				ELSE 
					SELECT 0

			END CASE ; 

		-- case 1 -- the 0 item 
		


		set @i= @i+1;
		end while;
    END IF;
END //
	DELIMITER ;


/*

DELIMITER $$
CREATE TRIGGER trgOnUpdateOnItem AFTER UPDATE ON Item
FOR EACH ROW
  BEGIN
	 -- is this the updated row ?!
    IF EXISTS (SELECT 1 FROM Item WHERE Item.SeqId = NEW.SeqId) THEN
		Update Item set SeqId = NEW.SeqId + 1 
		WHERE 1=1
		AND SeqId > NEW.SeqId ;
    ELSE
      -- UPDATE ext_words_count SET word_count = word_count + 1 WHERE word = NEW.word;
		update Item set SeqId = 1 where 1=1 and Item.SeqId < -1 ; 
    END IF;
  END $$
DELIMITER ;
*/

/*

-- http://stackoverflow.com/questions/28088663/mysql-update-trigger-how-to-compare-a-new-value-to-another-piece-of-data-in?rq=1
drop procedure if exists prcIssueAfterUpdate ; 

DELIMITER //
CREATE PROCEDURE prcIssueAfterUpdate
(
 	IN pSeqId bigint
 ,	IN pIssueId bigint 

)
BEGIN

	-- WHILE START

	-- case 1 the SeqId has not changed => do nothing

	-- case 2 the SeqId for this IssueId has changed => 
	-- get the prev item sequence id 
	-- -- case 2.1 
	-- -- added when item's parent does not have children
	-- -- needs the parent id as parameter
	-- -- if the current_level > previous_level
	-- -- sub doAddItemToParentWithoutChildren 
	-- -- case 2.2
	-- -- if the current_level < previous_level
	-- -- sub doAddItemToParentWithChildren 


	-- shift the shiftable left ranks by two positions
	UPDATE Issue set LeftRank = ( LeftRank + 1 ) where LeftRank > ( 
		SELECT LeftRank  from Item where 1=1  AND SeqId = pSeqId - 1
	) ; 


	-- shift the shiftable left ranks by two positions
	UPDATE Issue set RightRank = ( RightRank + 2 ) where RightRank > ( 
		SELECT LeftRank  from Item where 1=1  AND SeqId = pSeqId - 1
	) ; 

	-- WHILE STOP

END //
DELIMITER ;

*/

/*

BEGIN
	SELECT MONTH(CURDATE()) INTO @curmonth;
	SELECT MONTHNAME(CURDATE()) INTO @curmonthname;
	SELECT DAY(LAST_DAY(CURDATE())) INTO @totaldays;
	SELECT FIRST_DAY(CURDATE()) INTO @checkweekday;
	SELECT DAY(@checkweekday) INTO @checkday;
	SET @daycount = 0;
	SET @workdays = 0;

	WHILE(@daycount < @totaldays) DO
		IF (WEEKDAY(@checkweekday) < 5) THEN
			SET @workdays = @workdays+1;
		END IF;
		
		SET @daycount = @daycount+1;
		SELECT ADDDATE(@checkweekday, INTERVAL 1 DAY) INTO @checkweekday;
	END WHILE;
END


*/
