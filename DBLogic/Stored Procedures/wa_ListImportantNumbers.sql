-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListImportantNumbers
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListImportantNumbers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListImportantNumbers'
	drop procedure [dbo].[wa_ListImportantNumbers]
	print '**** Creating procedure dbo.wa_ListImportantNumbers...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListImportantNumbers]
	@pnCaseId 	int
AS
-- PROCEDURE :	wa_ListImportantNumbers
-- VERSION :	2.2.0
-- DESCRIPTION:	Selects a list of official numbers and associated event date
--				for a given CaseID
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	AF	Procedure created
-- 21/08/2001	MF	Get the Official Number and related Event using details specified on the 
--			NumberTypes table.

begin
	-- disable row counts
	set nocount on
	
	declare @ErrorCode	int

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId

	If @ErrorCode=0
	Begin
		
		select	NT.DESCRIPTION, 
			O.OFFICIALNUMBER, 
			isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) as EVENTDESCRIPTION,
			CE.EVENTDATE
		from OFFICIALNUMBERS O
		     join NUMBERTYPES NT	on (NT.NUMBERTYPE=O.NUMBERTYPE)
		left join CASEEVENT CE		on (CE.CASEID    =O.CASEID
						and CE.EVENTNO   =NT.RELATEDEVENTNO
						and CE.CYCLE     =1)
		left join EVENTS E		on (E.EVENTNO    =CE.EVENTNO)
		left join EVENTCONTROL EC	on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
						and EC.EVENTNO   =CE.EVENTNO)
		where O.CASEID=@pnCaseId
		and   O.ISCURRENT=1
		and   NT.ISSUEDBYIPOFFICE=1
		order by NT.DISPLAYPRIORITY, O.OFFICIALNUMBER desc

		Set @ErrorCode=@@Error
	End

	return @ErrorCode
end
go

grant execute on [dbo].[wa_ListImportantNumbers] to public
go
