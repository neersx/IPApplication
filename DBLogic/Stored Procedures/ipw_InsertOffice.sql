-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertOffice
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertOffice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertOffice.'
	Drop procedure [dbo].[ipw_InsertOffice]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertOffice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertOffice
(
	@pnUserIdentityId		int,		        -- Mandatory
	@psCulture			nvarchar(10) 	        = null,	
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
        @pbCalledFromCentura	        bit			= 0
)
as
-- PROCEDURE:	ipw_InsertOffice
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert new records in Office

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Dec 2010	MS	RFC8297	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @nOfficeKey     int
Declare @sAlertXML		nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

-- Check for Office name existence
If @nErrorCode = 0
Begin
	if exists(Select 1 from OFFICE WHERE DESCRIPTION = @psOfficeDescription) 				
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
	        if exists(Select 1 from OFFICE WHERE ITEMNOPREFIX = @psItemPrefix and @psItemPrefix is not null) or 
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
                if exists(Select 1 from OPENITEM WHERE @psItemPrefix is not null and
                        OPENITEMNO like @psItemPrefix + '%' and @pnItemNoTo <= CAST(dbo.fn_StripNonNumerics(OPENITEMNO)as DECIMAL))         
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

If @nErrorCode = 0
Begin
-- Get the next available ID
exec @nErrorCode = dbo.ip_GetLastInternalCode
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@psTable		= N'OFFICE',
				@pnLastInternalCode	= @nOfficeKey OUTPUT	
			
End

-- Construct the query
If @nErrorCode = 0
Begin
	Set @sSQLString = "INSERT INTO OFFICE(
			OFFICEID,
                        DESCRIPTION,
			USERCODE,
			COUNTRYCODE,
			LANGUAGECODE,
			CPACODE,
			IRNCODE,
			RESOURCENO,
			REGION,
			ORGNAMENO,
			ITEMNOPREFIX,
			ITEMNOFROM,
			ITEMNOTO)			
			VALUES(
			@nOfficeKey, 
			@psOfficeDescription,
			@psUserCode,
			@psCountryCode, 
			@pnLanguageCode,
			@psCPACode, 
			@psIRNCode,
			@pnResourceCode, 
			@pnRegionCode,			
			@pnOrgCode, 
			@psItemPrefix, 
			@pnItemNoFrom,
			@pnItemNoTo
		)"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nOfficeKey	                int,
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
			  @pnItemNoTo   	        decimal(10,0)',
			  @nOfficeKey   	        = @nOfficeKey,
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
			  @pnItemNoTo	                = @pnItemNoTo
	
	
        Set @sSQLString = "
                SELECT  OFFICEID as OfficeKey, 
                LOGDATETIMESTAMP as LogDateTimeStamp 
        from OFFICE
        where OFFICEID = @nOfficeKey"

        exec @nErrorCode=sp_executesql @sSQLString,
                N'@nOfficeKey   int',
                @nOfficeKey     = @nOfficeKey 
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertOffice to public
GO
