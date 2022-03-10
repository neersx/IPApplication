-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ConvertOpportunity									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ConvertOpportunity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ConvertOpportunity.'
	Drop procedure [dbo].[crm_ConvertOpportunity]
End
Print '**** Creating Stored Procedure dbo.crm_ConvertOpportunity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_ConvertOpportunity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey              int,            -- Mandatory
	@pnClientNameKey        int,            -- Mandatory
	@pnCRMCaseStatusKey     int
)
as
-- PROCEDURE:	crm_ConvertOpportunity
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Convert the Opportunity by defaulting associated names and status
--              This is normally called after the Client has already been created.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 25 Aug 2008	LP	RFC5751	1	Procedure created
-- 04 Sep 2008	AT	RFC5726	2	Modified insert CRM Case Status call
-- 23 Mar 2009	AT	RFC7244	3	Modified Convert Name Types Site Control Name.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sNameTypeKeys          nvarchar(508)
Declare @nCRMCaseStatusKey      int

-- Initialise variables
Set @nErrorCode = 0

Select @sNameTypeKeys = COLCHARACTER from SITECONTROL where CONTROLID = 'CRM Convert Client Name Types'

-- Set Name Type Classification of client
If @nErrorCode = 0 and @sNameTypeKeys is not null
Begin
        exec @nErrorCode = dbo.naw_ToggleNameTypes	@pnUserIdentityId	= @pnUserIdentityId,	
						        @psCulture		= @psCulture,	
						        @pbCalledFromCentura    = @pbCalledFromCentura,
						        @psNameKeys             = @pnClientNameKey,
						        @psNameTypeKeys         = @sNameTypeKeys,
						        @pbIsAllowed	        = 1	
End

-- Deselect Name Type Classification for inactive Prospect
If @nErrorCode = 0
Begin
        Set @sSQLString = "
        Update NTC
        set NTC.ALLOW = 0
        FROM CASENAME CN1 
        LEFT JOIN CASENAME CN2 ON (CN2.CASEID != CN1.CASEID
                                   AND CN2.NAMENO = CN1.NAMENO
                                   AND CN2.NAMETYPE = CN1.NAMETYPE)
        LEFT JOIN NAMETYPECLASSIFICATION NTC ON (NTC.NAMENO = CN1.NAMENO
                                                  AND NTC.NAMETYPE = CN1.NAMETYPE)
        where CN1.NAMETYPE = N'~PR'
        AND CN1.CASEID = @pnCaseKey
        AND CN2.NAMENO IS NULL"
        
        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int',
					  @pnCaseKey	= @pnCaseKey
End

-- Deselect Name Type Classification for inactive Leads
If @nErrorCode = 0
Begin
        Set @sSQLString = "
        Update NTC
        set NTC.ALLOW = 0
        FROM CASENAME CN1 
        LEFT JOIN CASENAME CN2 ON (CN2.CASEID != CN1.CASEID
                                   AND CN2.NAMENO = CN1.NAMENO
                                   AND CN2.NAMETYPE = CN1.NAMETYPE)
        LEFT JOIN NAMETYPECLASSIFICATION NTC ON (NTC.NAMENO = CN1.NAMENO
                                                  AND NTC.NAMETYPE = CN1.NAMETYPE)
        where CN1.NAMETYPE = N'~LD'
        AND CN1.CASEID = @pnCaseKey
        AND CN2.NAMENO IS NULL"
        
        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int',
					  @pnCaseKey	= @pnCaseKey        
End

-- Update Status
If @nErrorCode = 0
Begin
        exec @nErrorCode = dbo.crm_InsertCRMCaseStatusHistory   @pnUserIdentityId 	= @pnUserIdentityId,
							        @pnCaseKey		= @pnCaseKey,
	                                                        @pnCRMCaseStatusKey	= @pnCRMCaseStatusKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ConvertOpportunity to public
GO