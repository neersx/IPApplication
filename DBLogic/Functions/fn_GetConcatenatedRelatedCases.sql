-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedRelatedCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedRelatedCases') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedRelatedCases.'
	drop function dbo.fn_GetConcatenatedRelatedCases
	print '**** Creating function dbo.fn_GetConcatenatedRelatedCases...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION [dbo].[fn_GetConcatenatedRelatedCases]
	(
		@pnCaseId		int,
		@psRelationship		nvarchar(3),
		@psSeparator		nvarchar(10)
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetConcatenatedRelatedCases
-- VERSION :	1
-- DESCRIPTION:	Returns all related cases in a formatted string showing:
--			CountryCode, Official Number, Priority Date

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Mar 2016	CHPM		1	Created by Christopher Hip Po Man (Norton Rose)

AS
Begin
	Declare @sResult	nvarchar(max)

	select @sResult=isnull(nullif(@sResult+@psSeparator, @psSeparator), '')+
			isnull(C2.COUNTRYCODE, RC.COUNTRYCODE) + ', ' +
			isnull(COALESCE(O.OFFICIALNUMBER, C2.CURRENTOFFICIALNO, RC.OFFICIALNUMBER), '') + ', ' +
			isnull(convert(varchar(20), ISNULL(CE.EVENTDATE, RC.PRIORITYDATE), 103), '')
	from RELATEDCASE RC
	     join CASERELATION CR	on CR.RELATIONSHIP = RC.RELATIONSHIP
	left join CASES C2		on C2.CASEID = RC.RELATEDCASEID
	left join CASEEVENT CE		on (CE.EVENTNO = CR.EVENTNO
					and CE.CYCLE = 1
					and CE.CASEID = RC.RELATEDCASEID)
	left join OFFICIALNUMBERS O	on (O.CASEID = RC.RELATEDCASEID
					and O.NUMBERTYPE = 'A'
					and O.ISCURRENT = 1)
	left join CASES C		on C.CASEID = RC.CASEID
	where C.CASEID = @pnCaseId
	and RC.RELATIONSHIP = @psRelationship
	order by RC.RELATIONSHIPNO

Return @sResult
End
go

grant execute on dbo.fn_GetConcatenatedRelatedCases to public
GO

