-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetTotalPotentialsForMarketingOpportunities
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetTotalPotentialsForMarketingOpportunities') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetTotalPotentialsForMarketingOpportunities'
	Drop function [dbo].[fn_GetTotalPotentialsForMarketingOpportunities]
End
Print '**** Creating Function dbo.fn_GetTotalPotentialsForMarketingOpportunities...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetTotalPotentialsForMarketingOpportunities
(
	@pnCaseKey	int
) 
RETURNS decimal(11,2)
AS
-- Function :	fn_GetTotalPotentialsForMarketingOpportunities
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the sum of all Opportunties's potential value linked to this Marketing Activity in local value.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Aug 2008	SF	RFC5760	1	Function created
-- 25 Aug 2008	SF	RFC5760	2	Change Opportunity Relationship from "OPT" to "~OP"

Begin
	declare @total decimal(11,2)

	Select @total = sum(O.POTENTIALVALUELOCAL)
	from OPPORTUNITY O
	join RELATEDCASE RC on (RC.RELATEDCASEID = O.CASEID and RC.RELATIONSHIP = '~OP')
	join MARKETING M on (RC.CASEID = M.CASEID)
	where M.CASEID = @pnCaseKey

	return @total
End
GO

grant execute on dbo.fn_GetTotalPotentialsForMarketingOpportunities to public
go
