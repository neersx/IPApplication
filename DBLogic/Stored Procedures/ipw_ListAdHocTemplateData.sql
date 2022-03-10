-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListAdHocTemplateData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListAdHocTemplateData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListAdHocTemplateData.'
	Drop procedure [dbo].[ipw_ListAdHocTemplateData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListAdHocTemplateData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListAdHocTemplateData
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psAlertCode		nvarchar(10)	-- Mandatory
)
as
-- PROCEDURE:	ipw_ListAdHocTemplateData
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the AdHocTemplateData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Dec 2005	TM	RFC2939	1	Procedure created
-- 14 Aug 2006	LP	RFC4235	2	Add RowKey column in the result set
-- 02 Dec 2011	DV	RFC996	3	Add logic to return additional fields from ALERTTEMPLATE table. 
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  A.ALERTTEMPLATECODE 	as AlertCode,
		A.ALERTMESSAGE		as Message,
		A.DELETEALERT		as DaysDelete,
		A.STOPALERT		as DaysStopReminders,
		A.DAYSLEAD		as DaysLead,
		A.DAILYFREQUENCY	as RepeatIntervalDays,
		A.MONTHSLEAD		as MonthsLead,
		A.MONTHLYFREQUENCY	as RepeatIntervalMonths,	
		A.SENDELECTRONICALLY	as IsElectronicReminder,
		A.EMAILSUBJECT		as EmailSubject,
		A.IMPORTANCELEVEL	as ImportanceLevelKey,
		A.EMPLOYEEFLAG		as IsStaff,
		A.CRITICALFLAG		as IsCriticalList,
		A.SIGNATORYFLAG		as IsSignatory,
		A.NAMETYPE			as NameTypeKey, 
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
				+ " as NameType,
		A.RELATIONSHIP		as RelationshipKey, 
		A.EMPLOYEENO		as NameKey,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) 
					as Name,
		"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as ImportanceLevelDescription,
		A.ALERTTEMPLATECODE	as RowKey
	from ALERTTEMPLATE A
	left join IMPORTANCE I 	on (I.IMPORTANCELEVEL = A.IMPORTANCELEVEL)	
	left join NAME N		on (N.NAMENO = A.EMPLOYEENO)
	left join NAMETYPE NT	on (NT.NAMETYPE = A.NAMETYPE)
	where A.ALERTTEMPLATECODE = @psAlertCode"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@psAlertCode	nvarchar(10)',
			  @psAlertCode	= @psAlertCode

	Set @pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListAdHocTemplateData to public
GO
