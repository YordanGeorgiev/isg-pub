DROP PROCEDURE IF EXISTS resetLog ; 


Create Procedure resetLog() 
	BEGIN   
		 create table if not exists log (
		 	  ts timestamp default current_timestamp
			, msg varchar(2048)
		 ) 
			  engine = myisam ; 
		 truncate table log;
	END; 


	DROP PROCEDURE IF EXISTS doLog  ; 


	Create Procedure doLog(in logMsg nvarchar(2048))
		BEGIN  
			insert into log (msg) values(logMsg);
		END;


/*
	-- Usage in stored procedure:

	call dolog(concat_ws(': ','@simple_term_taxonomy_id',  @simple_term_taxonomy_id));
	-- usage of stored procedure:
	call resetLog ();
	call stored_proc();
	select * from log;

*/
