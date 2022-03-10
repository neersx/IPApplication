-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateOffice
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateOffice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateOffice.'
	Drop procedure [dbo].[ipw_UpdateOffice]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateOffice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateOffice
(
	@pnUserIdentityId		int,		        -- Mandatory
	@psCulture			nvarchar(10) 	        = null,	
	@pnOfficeKey			int,			-- Mandatory
        @psOfficeDescription            nvarchar(80),           -- Mandatory
	@psCountryCode			nvarchar(3)		= null,
	@pnLanguageCode			int		        = null,
        @psUserCode		        nvarchar(10)		= null,
	@psCPACode		        nvarchar(3)		= null,
	@psIRNCode			nvarchar(3)		= null,
	@pnResourceCode		        int		        = null,
	@pnRegionCode			int     		= null,
	@pnOrgCode	                int     		= null,
	@psItemPrefix   		nvarchar(2)		= null,
	@pnItemNoFrom			decimal(10,0)		= null,
	@pnItemNoTo			decimal(10,0)		= null,
        @pdModifiedDate                 datetime                = null,
        @pbCalledFromCentura	        bit			= 0
)
as
-- PROCEDURE:	ipw_UpdateOffice
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update record in OFFICE

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Dec 2010	MS	RFC8297	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
Declare @sAlertXML	nvarchar(1000)
Declare @nRowCount      int

-- Initialise variables
Set @nErrorCode = 0

-- Check for Office name existence
If @nErrorCode = 0
Begin
	if exists(Select 1 from OFFICE WHERE DESCRIPTION = @psOfficeDescription and OFFICEID <> @pnOfficeKey) 				
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP126', 'Duplicate Office. Please ensure that each Office Description must be unique.', 
                     null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
	End
End

If @psItemPrefix is not null and @psItemPrefix <> ''
Begin
        -- Check for Item No prefix existence
        If @nErrorCode = 0
        Begin
	        if exists(Select 1 from OFFICE WHERE ITEMNOPREFIX = @psItemPrefix and OFFICEID <> @pnOfficeKey) or 
                (Select COLCHARACTER from SITECONTROL where CONTROLID='DRAFTPREFIX') = @psItemPrefix				
	        Begin
		        Set @sAlertXML = dbo.fn_GetAlertXML('IP124', 'Duplicate Prefix. Please ensure that prefix for each office must be unique and should not match with value of site control “DRAFTPREFIX”.', 
                             null, null, null, null, null)
			        RAISERROR(@sAlertXML, 12, 1)
			        Set @nErrorCode = @@ERROR
	        End
        End

        -- Check for Item Nos range existence
        If @nErrorCode = 0
        Begin
	        if exists(Select 1 from OPENITEM WHERE OPENITEMNO like @psItemPrefix + '%' and @pnItemNoTo <= CAST(dbo.fn_StripNonNumerics(OPENITEMNO)as DECIMAL))         
	        Begin
		        Set @sAlertXML = dbo.fn_GetAlertXML('IP125', 'All the debit note numbers in the specified range have already been used. Please extend the range or use another prefix.', 
                             null, null, null, null, null)
			        RAISERROR(@sAlertXML, 12, 1)
			        Set @nErrorCode = @@ERROR
	        End
        End	
End	
Else
Begin
        Set @psItemPrefix = null
End

-- Construct the query
If @nErrorCode = 0
Begin
	Set @sSQLString = "UPDATE OFFICE
                           SET  DESCRIPTION             = @psOfficeDescription,
			        USERCODE                = @psUserCode,
			        COUNTRYCODE             = @psCountryCode,
			        LANGUAGECODE            = @pnLanguageCode,
			        CPACODE                 = @psCPACode,
			        IRNCODE                 = @psIRNCode,
			        RESOURCENO              = @pnResourceCode,
			        REGION                  = @pnRegionCode,
			        ORGNAMENO               = @pnOrgCode,
			        ITEMNOPREFIX            = @psItemPrefix,
			        ITEMNOFROM              = @pnItemNoFrom,
			        ITEMNOTO                = @pnItemNoTo			
			WHERE OFFICEID = @pnOfficeKey
                        AND (CAST(LOGDATETIMESTAMP as nvarchar(20)) = CAST(@pdModifiedDate as nvarchar(20))
                                or (LOGDATETIMESTAMP is null and @pdModifiedDate is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnOfficeKey	                int,
				  @psOfficeDescription 	        nvarchar(80),
				  @psUserCode	                nvarchar(10),
				  @psCountryCode	        nvarchar(3),
				  @pnLanguageCode	        int,
				  @psCPACode		        nvarchar(3),
				  @psIRNCode		        nvarchar(3),
				  @pnResourceCode               int,				  
				  @pnRegionCode 	        int,
				  @pnOrgCode	                int,
				  @psItemPrefix 	        nvarchar(2),
				  @pnItemNoFrom 	        decimal(10,0),
				  @pnItemNoTo   	        decimal(10,0),
                                  @pdModifiedDate               datetime',
				  @pnOfficeKey   	        = @pnOfficeKey,
				  @psOfficeDescription 	        = @psOfficeDescription,
				  @psUserCode	                = @psUserCode,
				  @psCountryCode	        = @psCountryCode,
				  @pnLanguageCode	        = @pnLanguageCode,
				  @psCPACode		        = @psCPACode,
				  @psIRNCode		        = @psIRNCode,
				  @pnResourceCode	        = @pnResourceCode,
				  @pnRegionCode	                = @pnRegionCode,
				  @pnOrgCode	                = @pnOrgCode,
				  @psItemPrefix	                = @psItemPrefix,
				  @pnItemNoFrom	                = @pnItemNoFrom,
				  @pnItemNoTo	                = @pnItemNoTo,
                                  @pdModifiedDate               = @pdModifiedDate
	
        Set @nRowCount = @@rowcount
End

If @nErrorCode = 0
Begin
        If @nRowCount = 0
        Begin	
	        Set @sAlertXML = dbo.fn_GetAlertXML('IP127', 'Concurrency violation. Office may have been updated or deleted. Please reload and try again.',
				        null, null, null, null, null)
	        RAISERROR(@sAlertXML, 14, 1)
	        Set @nErrorCode = @@ERROR
        End
        ELSE If @nRowCount = 1
        Begin	
                Set @sSQLString = "
                        SELECT  OFFICEID as OfficeKey, 
                        LOGDATETIMESTAMP as LogDateTimeStamp 
                from OFFICE
                where OFFICEID = @pnOfficeKey"

                exec @nErrorCode=sp_executesql @sSQLString,
                        N'@pnOfficeKey   int',
                        @pnOfficeKey     = @pnOfficeKey 
        	
        End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateOffice to public
GO
