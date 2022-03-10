
/*********************************************************************************/
/**** DR-44495 Unable to locate the 'Case Client Access' case windows rule  ******/
/*********************************************************************************/
update CRITERIA set CASETYPE = 'A' where PROGRAMID = 'CASEEXT'  and CASETYPE is null
GO

