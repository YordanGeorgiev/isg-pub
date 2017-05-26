-- @SCHEMA_NAME define nice date and number formatting
-- enable printing 
set serveroutput on format wrapped;
set feedback off ;   
Begin
  Dbms_Output.Put_Line('START RUNNING script : /path/to/sql/script.sql');
  Dbms_Output.Put_Line('SETTING YYYY-MM-DD HH24:MI:SS date format and Finnish numeric chars formatting');
  Dbms_Output.Put_Line('START CREATING THE TABLE_NAME TABLE');
  Dbms_Output.Put_Line('------------------------------------------------------');
End;
/

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
Alter Session Set Nls_Numeric_Characters=', ';
set feedback on ; 
 
/* 
Run all by : Ctrl + A, F5 in Sql Developer 
DROP THE TABLE IF IT EXISTS 
*/
declare
   c int; 
begin
   select count(*) into c from user_tables where table_name = upper('TABLE_NAME'); 

   if c = 1 then
      execute immediate 'DROP TABLE TABLE_NAME'; 

   end if; 
end; 
/
--------------------------------------------------------
--  DDL for Table TABLE_NAME
--------------------------------------------------------
CREATE TABLE "TABLE_NAME" (
  "TABLE_NAME_ID"         NUMBER (15,0) NOT NULL
 , "DWRUNTIME" DATE NOT NULL ENABLE
 , CONSTRAINT "TABLE_NAME_RECEIPT_NUMBER_PK" PRIMARY KEY ("TABLE_NAME_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS NOLOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TABLE_SPACE"  ENABLE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS NOLOGGING
  STORAGE(INITIAL 2097152 NEXT 2097152 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TABLE_SPACE" 
  ;


/*
-- COMMENT ON COLUMN "TABLE_NAME"."ALKUPVM" IS                                                          
-- 'the first load date o'                                                                                            
-- ; 
-- SELECT AND RUN THIS SNIPPET TO GENERATE THE COMMENTING SQL SNIPPETS 
SELECT  ';
COMMENT ON COLUMN "' || TABLE_NAME || '"."' || COLUMN_NAME || '" IS 
''COMMENT'' ' AS SELECT_CODE  
FROM ALL_TAB_COLUMNS WHERE 1=1 
and TABLE_NAME LIKE '%TABLE_NAME%'
--AND COLUMN_NAME LIKE '%AMOUNT%'
ORDER BY TABLE_NAME , COLUMN_ID  

 ; */

                                                                                                    


select  tc.column_name ,      cc.comments ,      tc.data_type || 
   case when tc.data_type = 'NUMBER' and tc.data_precision is not null then '(' || tc.data_precision || ',' || tc.data_scale || ')'
   when tc.data_type like '%CHAR%' then '(' || tc.data_length || ')'
   else null
   end type
from   user_col_comments cc
join   user_tab_columns  tc on  cc.column_name = tc.column_name
                            and cc.table_name  = tc.table_name
where  cc.table_name = upper('TABLE_NAME') ; 

COMMIT ; 

/
Set Feedback Off ;
Begin
  Dbms_Output.Put_Line('GRANTING THE SELECT TO THE TABLE_NAME TABLE TO THE TO SCHEMA_NAME ACCOUNT');
  Dbms_Output.Put_Line('------------------------------------------------------');
End ;
/

Grant Select On SCHEMA_NAME.TABLE_NAME To SCHEMA_NAME
; 
/

Set Feedback Off ; 
-- SELECT  AS "ACTION_PERFORMED" FROM DUAL ;
Begin
  Dbms_Output.Put_Line('CHECKING THAT THE TABLE TABLE_NAME HAS BEEN CREATED');
  Dbms_Output.Put_Line('------------------------------------------------------');
End;
/

Select TABLE_NAME From ALL_TABLES 
Where 1=1
AND TABLE_NAME = 'TABLE_NAME'
; 

Set Feedback Off ; 
-- SELECT  AS "ACTION_PERFORMED" FROM DUAL ;
Begin
  Dbms_Output.Put_Line('CHECKING the data of the TABLE_NAME TABLE');
  Dbms_Output.Put_Line('------------------------------------------------------');
End;
/

Select * From SCHEMA_NAME.TABLE_NAME
; 

Set Feedback Off ; 
Begin
  Dbms_Output.Put_Line('STOP RUNNING FILE : /path/to/sql/script.sql');
End;
/
Set Feedback On ; 
