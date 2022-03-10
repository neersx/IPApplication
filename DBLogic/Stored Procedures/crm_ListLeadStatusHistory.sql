-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ListLeadStatusHistory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ListLeadStatusHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ListLeadStatusHistory.'
	Drop procedure [dbo].[crm_ListLeadStatusHistory]
End
Print '**** Creating Stored Procedure dbo.crm_ListLeadStatusHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_ListLeadStatusHistory
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey				int		-- Mandatory
)
as
-- PROCEDURE:	crm_ListLeadStatusHistory
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	list the status history of a Lead

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Jul 2008	SF	6535	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer
-- 04 Nov 2015	KR	R53910	3	Adjust formatted names logic (DR-15543)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare	@dtToday				datetime
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString 				nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
		CAST(LSH.NAMENO as nvarchar(11))+'^'+CAST(LSH.LEADSTATUSID as nvarchar(11))		
											as RowKey,
		LSH.NAMENO							as NameKey,
		LSH.LEADSTATUSID					as LeadStatusKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',
							@sLookupCulture,@pbCalledFromCentura) +
		"									as LeadStatusDescription,
		LSH.LOGDATETIMESTAMP				as LastModified,
		N.NAMENO							as StaffNameKey,"+char(10)+
		-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
		-- fn_FormatName, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
		"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
		"			as 'StaffName',"+CHAR(10)+  
		"N.NAMECODE		as 'StaffNameCode'
	from	LEADSTATUSHISTORY LSH
	join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 501, default, @dtToday) LeadItems on (LeadItems.IsAvailable=1)
	left join	TABLECODES TC	on (TC.TABLECODE = LSH.LEADSTATUS)
	left join	USERIDENTITY UI		on (UI.IDENTITYID = LSH.LOGIDENTITYID)
	left join	NAME N				on (N.NAMENO = UI.NAMENO)
	left join	COUNTRY NN			on (NN.COUNTRYCODE = N.NATIONALITY) 
		
	where		LSH.NAMENO = @pnNameKey
	order by LastModified desc"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey			int,
					@pnUserIdentityId	int,
					@dtToday			datetime',
				@pnNameKey			= @pnNameKey,
				@pnUserIdentityId	= @pnUserIdentityId,
				@dtToday			= @dtToday
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ListLeadStatusHistory to public
GO
