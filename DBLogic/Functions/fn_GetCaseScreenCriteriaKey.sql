-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCaseScreenCriteriaKey
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCaseScreenCriteriaKey') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetCaseScreenCriteriaKey'
	Drop function [dbo].[fn_GetCaseScreenCriteriaKey]
End
Print '**** Creating Function dbo.fn_GetCaseScreenCriteriaKey...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetCaseScreenCriteriaKey
(
	@pnCaseKey	int,
	@psPurposeCode	nvarchar(1),
	@psProgramKey	nvarchar(8),
	@pnProfileKey	int
) 
RETURNS int
AS
-- Function :	fn_GetCaseScreenCriteriaKey
-- VERSION :	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the Case Screen Control Criteria number for an existing Case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2013	LP	DR-53	1	Function created
-- 23 Jul 2013  SW  DR-643  2   Added filter on CaseKey to return not null existing criteriakey for the case 
-- 31 Dec 2013	DV	R29580	3	Get the Programekey from the profile if it is null	     

Begin
	declare @nResult int
	set @nResult = null
	
	If @psProgramKey is null and @pnProfileKey is not null
	Begin 
		Select @psProgramKey = P.ATTRIBUTEVALUE
			from PROFILEATTRIBUTES P
			where P.PROFILEID = @pnProfileKey
			and P.ATTRIBUTEID = 2 -- Default Case Program			
	End
	
	If @psProgramKey is not null
	Begin
		SELECT @nResult = dbo.fn_GetCriteriaNo(@pnCaseKey, @psPurposeCode, case when CS.CRMONLY=1 then SCRM.COLCHARACTER else @psProgramKey end, null, @pnProfileKey)
		from CASES C
		join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)
		join SITECONTROL SC on (SC.CONTROLID = 'Case Screen Default Program')
		join SITECONTROL SCRM on (SCRM.CONTROLID = 'CRM Screen Control Program')
		where C.CASEID = @pnCaseKey
	End
	Else
	Begin
		SELECT @nResult = dbo.fn_GetCriteriaNo(@pnCaseKey, @psPurposeCode, case when CS.CRMONLY=1 then SCRM.COLCHARACTER else SC.COLCHARACTER end, null, @pnProfileKey)
		from CASES C
		join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)
		join SITECONTROL SC on (SC.CONTROLID = 'Case Screen Default Program')
		join SITECONTROL SCRM on (SCRM.CONTROLID = 'CRM Screen Control Program')
		where C.CASEID = @pnCaseKey
	End	
		
	return @nResult
End
GO

grant execute on dbo.fn_GetCaseScreenCriteriaKey to public
go
