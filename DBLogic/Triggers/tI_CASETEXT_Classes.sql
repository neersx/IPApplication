/******************************************************************************************************************/
/*** Create trigger tI_CASETEXT_Classes										***/
/******************************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tI_CASETEXT_Classes')
   begin
    PRINT 'Refreshing trigger tI_CASETEXT_Classes...'
    DROP TRIGGER tI_CASETEXT_Classes
   end
  go

CREATE TRIGGER tI_CASETEXT_Classes on CASETEXT AFTER INSERT NOT FOR REPLICATION 
as
-- TRIGGER :	tI_CASETEXT_Classes
-- VERSION :	1
-- DESCRIPTION:	When a CASETEXT row for TEXTTYPE='G' is inserted
--		automatically delete any existing row for the same
--		Class that has no text stored in it.  The row being
--		deleted is a place holder to allow class searches and
--		is no longer required.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Jan 2014	MF	R30024	1	Trigger created

Begin
	----------------------------------------------
	-- Delete a CASETEXT row that currently has no
	-- text if a new CASETEXT row is being created
	-- for the same Class.
	----------------------------------------------
	delete CT
	from inserted i
	join CASETEXT CT on (CT.CASEID  =i.CASEID
			 and CT.TEXTTYPE=i.TEXTTYPE
			 and CT.CLASS   =i.CLASS)
	where i.TEXTTYPE='G'
	and (i.LONGFLAG=1 or i.SHORTTEXT is not null or i.LANGUAGE is not null)
	and CT.LONGFLAG=0
	and CT.SHORTTEXT is null
	and CT.LANGUAGE  is null
End
go
