-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteOffice
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteOffice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteOffice.'
	Drop procedure [dbo].[ipw_DeleteOffice]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteOffice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteOffice
(
	@pnUserIdentityId		int,		        -- Mandatory
	@psCulture			nvarchar(10) 	        = null,	
	@pnOfficeKey			int,			-- Mandatory        
        @pdModifiedDate                 datetime                = null,
        @pbCalledFromCentura	        bit			= 0
)
as
-- PROCEDURE:	ipw_DeleteOffice
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete record from OFFICE

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Dec 2010	MS	RFC8297	  1	Procedure created
-- 22 Mar 2011  MS      RFC100492 2     Added check for Office Key existence in TABLEATTRIBUTES

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
Declare @sAlertXML	nvarchar(1000)
Declare @nRowCount      int

-- Initialise variables
Set @nErrorCode = 0

-- Construct the query
If exists (	Select 1
		from OFFICE O
		join TABLEATTRIBUTES TA on (TA.TABLETYPE = 44 and TA.TABLECODE = O.OFFICEID and TA.PARENTTABLE = 'NAME')
	  )
BEGIN
	Set @sAlertXML = dbo.fn_GetAlertXML('IP123', 'The requested Office cannot be deleted as it is essential to other existing information.',
				                null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
END
ELSE
BEGIN

        Set @sSQLString = "DELETE OFFICE                           	
			        WHERE OFFICEID = @pnOfficeKey
                                AND (CAST(LOGDATETIMESTAMP as nvarchar(20)) = CAST(@pdModifiedDate as nvarchar(20))
                                        or (LOGDATETIMESTAMP is null and @pdModifiedDate is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
			        N'@pnOfficeKey	                int,				 
                                  @pdModifiedDate               datetime',
			          @pnOfficeKey   	        = @pnOfficeKey,				
                                  @pdModifiedDate               = @pdModifiedDate
        	
        	
        Set @nRowCount = @@rowcount
END

If @nErrorCode = 0 and @nRowCount = 0
Begin	
	Set @sAlertXML = dbo.fn_GetAlertXML('IP127', 'Concurrency violation. Office may have been updated or deleted. Please reload and try again.',
				null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteOffice to public
GO

