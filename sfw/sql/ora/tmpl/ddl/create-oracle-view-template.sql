-- @SCHEMA_NAME define nice date and number formatting
-- enable printing 
set serveroutput on format wrapped;
set feedback off ;   
Begin
  Dbms_Output.Put_Line('START RUNNING script : /path/to/sql/script.sql');
  Dbms_Output.Put_Line('SETTING YYYY-MM-DD HH24:MI:SS date format and Finnish numeric chars formatting');
  Dbms_Output.Put_Line('START CREATING THE VIEW_NAME VIEW');
  Dbms_Output.Put_Line('------------------------------------------------------');
End;
/

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
Alter Session Set Nls_Numeric_Characters=', ';
set feedback on ; 
 
Create or replace View SCHEMA_NAME.VIEW_NAME 
As
SELECT ' BOO' FROM DUAL ; 

; 
/
Set Feedback Off ;
Begin
  Dbms_Output.Put_Line('GRANTING THE SELECT TO THE VIEW_NAME VIEW TO THE TO SCHEMA_NAME ACCOUNT');
  Dbms_Output.Put_Line('------------------------------------------------------');
End ;
/

Grant Select On SCHEMA_NAME.VIEW_NAME To SCHEMA_NAME
; 
/

Set Feedback Off ; 
-- SELECT  AS "ACTION_PERFORMED" FROM DUAL ;
begin
  Dbms_Output.Put_Line('CHECKING THAT THE VIEW VIEW_NAME HAS BEEN CREATED');
  Dbms_Output.Put_Line('------------------------------------------------------');
End;
/

Select View_Name From All_Views
Where 1=1
AND VIEW_NAME = 'VIEW_NAME'
; 

Set Feedback Off ; 
-- SELECT  AS "ACTION_PERFORMED" FROM DUAL ;
Begin
  Dbms_Output.Put_Line('CHECKING the data of the VIEW_NAME VIEW');
  Dbms_Output.Put_Line('------------------------------------------------------');
End;
/

Select * From SCHEMA_NAME.VIEW_NAME
; 

Set Feedback Off ; 
Begin
  Dbms_Output.Put_Line('STOP RUNNING FILE : /path/to/sql/script.sql');
End;
/
Set Feedback On ; 
