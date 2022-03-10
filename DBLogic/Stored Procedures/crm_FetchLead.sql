-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_FetchLead									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_FetchLead]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_FetchLead.'
	Drop procedure [dbo].[crm_FetchLead]
End
Print '**** Creating Stored Procedure dbo.crm_FetchLead...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_FetchLead
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 		= null,
	@pbCalledFromCentura	bit			= 0,
	@pnNameKey				int,		-- Mandatory
	@pbNewRow				bit			= 0,
	@psCountryCode			nvarchar(3) = null
)
as
-- PROCEDURE:	crm_FetchLead
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Lead business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18 Jun 2008	SF	RFC6508	1	Procedure created
-- 26 Jun 2008	SF	RFC6508	2	Enlarge Comments column to 4000 characters, 
--								Remove EMPLOYEENO and MODIFIEDDATE
-- 30 Jun 2008	SF	RFC6508	3	Remove print statement
-- 21 Aug 2008	AT	RFC6894 4	Add Estimated Revenue Local
-- 15 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString 				nvarchar(4000)

Declare @nDefaultStatusKey			int
Declare @sDefaultStatusDescription	nvarchar(160)
Declare @sDefaultEstRevCurrencyCode	nvarchar(3)
Declare @sDefaultEstRevCurrency		nvarchar(40)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	If @pbNewRow = 1
	Begin
		If @nErrorCode = 0 
		Begin
			Set @sSQLString = "
			Select
				@nDefaultStatusKey				= SCAC.COLINTEGER,
				@sDefaultStatusDescription		= "+
				dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',
							@sLookupCulture,@pbCalledFromCentura)+"
			from SITECONTROL SCAC	
			left join TABLECODES 	TCC 	on (TCC.TABLECODE 	= SCAC.COLINTEGER)

			where UPPER(SCAC.CONTROLID) 	= 'CRM DEFAULT LEAD STATUS'"

			exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@nDefaultStatusKey				int							output,
				@sDefaultStatusDescription		nvarchar(160)				output',
				@nDefaultStatusKey				= @nDefaultStatusKey		output,
				@sDefaultStatusDescription		= @sDefaultStatusDescription		output

		End

		Select
			@pnNameKey						as NameKey,
			@nDefaultStatusKey				as LeadStatusKey,
			@sDefaultStatusDescription		as LeadStatusDescription
	End
	Else
	Begin	
		Set @sSQLString = "Select
		CAST(L.NAMENO as nvarchar(11))		as RowKey,
		L.NAMENO							as NameKey,
		L.LEADSOURCE						as LeadSourceKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCLS',
							@sLookupCulture,@pbCalledFromCentura) +
		"					as LeadSourceDescription,
		LSH.LEADSTATUS						as LeadStatusKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCLST',
							@sLookupCulture,@pbCalledFromCentura) +
		"					as LeadStatusDescription,
		L.ESTIMATEDREVLOCAL					as EstimatedRevenueLocal,
		L.ESTIMATEDREV						as EstimatedRevenue,
		"+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',
							@sLookupCulture,@pbCalledFromCentura)+
		"					as EstimatedRevenueCurrency,
		L.ESTREVCURRENCY					as EstimatedRevenueCurrencyCode,
		"+dbo.fn_SqlTranslatedColumn('LEADDETAILS','COMMENTS',null,'L',
							@sLookupCulture,@pbCalledFromCentura)+
		"					as Comments 
		from LEADDETAILS L
		left join TABLECODES TCLS 	on (TCLS.TABLECODE 	= L.LEADSOURCE)		
		left join (	select	NAMENO, 
							MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(LEADSTATUSID as nvarchar(11)) ) as [DATE]
				from LEADSTATUSHISTORY
				group by NAMENO	
				) LASTMODIFIED on (LASTMODIFIED.NAMENO = L.NAMENO)
		left join LEADSTATUSHISTORY	LSH	on (LSH.NAMENO = L.NAMENO
			and ( (convert(nvarchar(24),LSH.LOGDATETIMESTAMP, 21)+cast(LSH.LEADSTATUSID as nvarchar(11))) = LASTMODIFIED.[DATE]
				or LASTMODIFIED.[DATE] is null ))
		left join TABLECODES TCLST 	on (TCLST.TABLECODE 	= LSH.LEADSTATUS)		
		left join CURRENCY CUR	on (CUR.CURRENCY 		= L.ESTREVCURRENCY)
		where L.NAMENO = @pnNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey	int',
				@pnNameKey		= @pnNameKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.crm_FetchLead to public
GO



