-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListRelatedCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListRelatedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListRelatedCases'
	drop procedure [dbo].[wa_ListRelatedCases]
	print '**** Creating procedure dbo.wa_ListRelatedCases...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListRelatedCases]
	@pnCaseId	int
AS
-- PROCEDURE :	wa_ListRelatedCases
-- VERSION :	4
-- DESCRIPTION:	Returns a list of Related Cases for a given Case passed as a parameter.
-- CALLED BY :	

-- MODIFICTION HISTORY
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	AF			Procedure created	
-- 03/08/2001	MF			Only display details if the user has the correct access rights
-- 02/01/2001	MF	SQA7321		The related case details returned should also return relationships 
--					that reference the Official Number, Country and date directly.
-- 24 Jul 2009	MF	SQA16548 11	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.

begin
	-- disable row counts
	set nocount on

	declare @ErrorCode	int

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId

	If @ErrorCode=0
	Begin
	
		SELECT		CR.RELATIONSHIPDESC,
				R.RELATEDCASEID,
				C.IRN,
	   			isnull(C.CURRENTOFFICIALNO, R.OFFICIALNUMBER) as CURRENTOFFICIALNO,
				CT.COUNTRY,
		  		isnull(CE.EVENTDATE, R.PRIORITYDATE) as PRIORITYDATE,
				CR.EVENTNO
		FROM		RELATEDCASE R
		join		CASERELATION CR on (CR.RELATIONSHIP=R.RELATIONSHIP
						and CR.SHOWFLAG    =1)
		left join 	CASES	C       on (C.CASEID       =R.RELATEDCASEID)
		left join 	COUNTRY CT	on (CT.COUNTRYCODE =isnull(C.COUNTRYCODE, R.COUNTRYCODE))
		left join 	CASEEVENT CE   	on (CE.CASEID      =C.CASEID
                		          	and CE.EVENTNO     =isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
						and CE.CYCLE       =1)
		WHERE		R.CASEID = @pnCaseId
		order by 	CR.RELATIONSHIPDESC, 6, 5, 4

		set @ErrorCode=@@Error
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListRelatedCases] to public
go
