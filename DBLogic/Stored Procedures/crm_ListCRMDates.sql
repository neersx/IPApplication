-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ListCRMDates									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ListCRMDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ListCRMDates.'
	Drop procedure [dbo].[crm_ListCRMDates]
End
Print '**** Creating Stored Procedure dbo.crm_ListCRMDates...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.crm_ListCRMDates
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	crm_ListCRMDates
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return dates for the CRM Other Details topic.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Jul 2008	AT	RFC5749	1	Procedure created
-- 17 Sep 2010	MF	RFC9777	2	Return the EVENTDESCRIPTION identified by the Controlloing Action
--					if it is available.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select 
		DISTINCT
		CE.EVENTNO		as 'RowKey',
		CE.CASEID		as 'CaseKey',
		CE.EVENTNO		as 'EventKey',
		isnull(EC.EVENTDESCRIPTION,E.EVENTDESCRIPTION)
					as 'EventDescription',
		CE.EVENTDATE		as 'EventDate',
		CE.EVENTDUEDATE		as 'EventDueDate'
		from CASEEVENT CE
		join EVENTS E on (E.EVENTNO = CE.EVENTNO)
		left join OPENACTION OA	on (OA.CASEID=CE.CASEID
					and OA.ACTION=E.CONTROLLINGACTION)
		left join EVENTCONTROL EC
					on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO   =CE.EVENTNO)
		where CE.CASEID = @pnCaseKey
		and E.EVENTNO in (-13, -14, -12210, -12211)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey		int',
			  @pnCaseKey	 = @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ListCRMDates to public
GO