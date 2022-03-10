-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_GetLeadDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_GetLeadDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_GetLeadDetails.'
	Drop procedure [dbo].[crm_GetLeadDetails]
End
Print '**** Creating Stored Procedure dbo.crm_GetLeadDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_GetLeadDetails
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,	-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	crm_GetLeadDetails
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get Lead Details of a Lead.  Protected by Lead Item topic security.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 June 2008	SF	6535	1	Procedure created
-- 21 Aug 2008	AT	6894	2	Added Estimated Revenue Local
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode				int
Declare @bCanViewLeadItems		bit
Declare	@dtToday				datetime
Declare @sLookupCulture			nvarchar(10)
Declare @sSQLString 			nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@dtToday = getdate()

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
		cast(L.NAMENO as nvarchar(11))	as 'RowKey',
		L.NAMENO							as NameKey,"+char(10)+
		-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
		-- fn_FormatName, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
		"dbo.fn_FormatNameUsingNameNo(LN.NAMENO, COALESCE(LN.NAMESTYLE, LNN.NAMESTYLE, 7101))"+CHAR(10)+  	
		"			as 'Name',"+CHAR(10)+  
		"LN.NAMECODE		as 'NameCode',
		N.NAMENO							as LeadOwnerNameKey,"+char(10)+
		-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
		-- fn_FormatName, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
		"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
		"			as 'LeadOwnerName',"+CHAR(10)+  
		"N.NAMECODE		as 'LeadOwnerNameCode',"+CHAR(10)
		+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCLS',
							@sLookupCulture,@pbCalledFromCentura) +
		"					as LeadSourceDescription,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCLST',
							@sLookupCulture,@pbCalledFromCentura) +
		"					as LeadStatusDescription,
		isnull(L.ESTIMATEDREV,L.ESTIMATEDREVLOCAL) as EstimatedRevenue,
		case when L.ESTIMATEDREV IS NULL THEN NULL ELSE L.ESTREVCURRENCY END as EstimatedRevenueCurrencyCode,
		"+dbo.fn_SqlTranslatedColumn('LEADDETAILS','COMMENTS',null,'L',
							@sLookupCulture,@pbCalledFromCentura)+
		"					as Comments 
		from LEADDETAILS L
		join NAME LN on (LN.NAMENO = L.NAMENO)		
		left join COUNTRY LNN		on (LNN.COUNTRYCODE = LN.NATIONALITY)"+char(10)+
		-- get the (Lead Owner) RES of the smallest sequence for the Lead
		"left join (select NAMENO, MIN(SEQUENCE) as MinLeadOwner
					from	ASSOCIATEDNAME
					where	RELATIONSHIP = 'RES'
					group by NAMENO) RES on (RES.NAMENO = L.NAMENO)
		left join ASSOCIATEDNAME AN on (AN.NAMENO = RES.NAMENO 
					and		RELATIONSHIP = 'RES'
					and		SEQUENCE = RES.MinLeadOwner)					
		left join NAME N on (N.NAMENO = AN.RELATEDNAME)		
		left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY) 
		
		left join TABLECODES TCLS 	on (TCLS.TABLECODE 	= L.LEADSOURCE)"+char(10)+
		--- get the latest Lead Status for the Lead
		"left join (	select	NAMENO, 
							MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(LEADSTATUSID as nvarchar(11)) ) as [DATE]
				from LEADSTATUSHISTORY
				group by NAMENO	
				) LASTMODIFIED on (LASTMODIFIED.NAMENO = L.NAMENO)
		left join LEADSTATUSHISTORY	LSH	on (LSH.NAMENO = L.NAMENO
			and ( (convert(nvarchar(24),LSH.LOGDATETIMESTAMP, 21)+cast(LSH.LEADSTATUSID as nvarchar(11))) = LASTMODIFIED.[DATE]
				or LASTMODIFIED.[DATE] is null ))
		left join TABLECODES TCLST 	on (TCLST.TABLECODE 	= LSH.LEADSTATUS)"+char(10)+
		--- get the default currency if not specified
		"join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 501, default, @dtToday) LeadItems on (LeadItems.IsAvailable=1)
		where L.NAMENO = @pnNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@bCanViewLeadItems	bit				OUTPUT,
					@pnNameKey			int,
					@pnUserIdentityId	int,
					@dtToday			datetime',
				@bCanViewLeadItems	= @bCanViewLeadItems	OUTPUT,
				@pnNameKey			= @pnNameKey,
				@pnUserIdentityId	= @pnUserIdentityId,
				@dtToday			= @dtToday
End

Return @nErrorCode
GO

Grant execute on dbo.crm_GetLeadDetails to public
GO
