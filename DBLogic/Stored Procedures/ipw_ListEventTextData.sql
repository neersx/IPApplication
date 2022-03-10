-- Creation of ipw_ListEventTextData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListEventTextData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListEventTextData.'
	Drop procedure [dbo].[ipw_ListEventTextData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListEventTextData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListEventTextData
(
	@pnUserIdentityId	int,		-- Mandatory
	@pnCaseKey		int, 		-- Mandatory
	@pnEventKey		int,		-- Mandatory
	@pnCycle		int,		-- Mandatory
	@pnEventTextType	smallint	= null
	
)
as
-- PROCEDURE:	ipw_ListEventTextData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the Event Text of an Event.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Aug 2006	LP	RFC4234	1	Procedure created
-- 25 Sep 2011  DV      R10273  2       Return Case reference in the result
-- 24 Oct 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.
-- 03 Mar 2015	MS	R43203	4	Return event text from EVENTTEXT table
-- 09 Mar 2015	MS	R45373	5	Added @pnEventTextType parameter to search notes based on event text type

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	  
		CE.EVENTNO					as EventKey,
		CE.CASEID					as CaseKey,
		CE.CYCLE					as Cycle,
		C.IRN                                           as CaseRef,
		ETF.EVENTTEXT					as EventText,
		cast(CE.CASEID as nvarchar(11)) + '^'
			+ cast(CE.EVENTNO as nvarchar(11)) + '^'
			+ cast(CE.CYCLE as nvarchar(10)) 	as RowKey
	from CASEEVENT CE
	join CASES C on (C.CASEID = CE.CASEID)
	left join (Select ET.EVENTTEXT, CET.CASEID, CET.EVENTNO, CET.CYCLE
				from EVENTTEXT ET
				Join CASEEVENTTEXT CET	on (CET.EVENTTEXTID = ET.EVENTTEXTID)
				where ((ET.EVENTTEXTTYPEID is null and @pnEventTextType is null) or ET.EVENTTEXTTYPEID = @pnEventTextType))
			as ETF on (ETF.CASEID = CE.CASEID and ETF.EVENTNO = CE.EVENTNO and ETF.CYCLE = CE.CYCLE)
	where 	CE.EVENTNO		= @pnEventKey
	and 	CE.CASEID	 	= @pnCaseKey
	and 	CE.CYCLE		= @pnCycle"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnEventKey		int,
			 @pnCaseKey		int,
			 @pnCycle		int,
			 @pnEventTextType	smallint',
			 @pnEventKey		= @pnEventKey,
			 @pnCaseKey		= @pnCaseKey,
			 @pnCycle		= @pnCycle,
			 @pnEventTextType	= @pnEventTextType
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListEventTextData to public
GO
