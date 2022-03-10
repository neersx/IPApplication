-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateFirstUseDetails									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateFirstUseDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateFirstUseDetails.'
	Drop procedure [dbo].[csw_UpdateFirstUseDetails]
End
Print '**** Creating Stored Procedure csw_UpdateFirstUseDetails.'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[csw_UpdateFirstUseDetails]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pdtEventDate		datetime        = null,
	@psPlaceFirstUsed       nvarchar(254)   = null,
	@psProposedUse          nvarchar(254)   = null,
	@pdtOldEventDate        datetime        = null,
	@psOldPlaceFirstUsed    nvarchar(254)   = null,
	@psOldProposedUse       nvarchar(254)   = null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_UpdateFirstUseDetails
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the FirstUse details in CASEEVENT and PROPERTY Tables, if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 22 Sep 2009	PA	RFC8044	1	Procedure created
-- 09 APR 2014  MS  R31303  2   Added LastModifiedDate to csw_UpdateCaseEvent call
-- 23 Nov 2016	DV	R62369	3	Remove concurrency check when updating case events 


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @pnRowCount	int
Declare @pnEventKey   int
Declare @pnOldEventKey	int
Declare @pnOldEventCycle smallint
Declare @pnEventCycle	smallint
Declare @pnCycle smallint
Declare @dtLastModifiedDate datetime

-- Initialise variables
Set	@nErrorCode      = 0
Set @pnRowCount	= @@RowCount
Set @pnRowCount = 0
	
If @nErrorCode = 0
Begin
	Select @pnEventKey = COLINTEGER
	From SITECONTROL
	Where CONTROLID = 'First Use Event'
End

-- Update Event Date       
If @pnEventKey is not null 
Begin
    if exists(SELECT 1 from CASEEVENT Where CASEID = @pnCaseKey and CYCLE = 1 and EVENTNO = @pnEventKey)
    Begin                                
			exec @nErrorCode= dbo.csw_UpdateCaseEvent
				@pnUserIdentityId = @pnUserIdentityId,
				@pnCaseKey = @pnCaseKey,
				@pnEventKey = @pnEventKey,
				@pnEventCycle = 1,
				@pdtEventDate = @pdtEventDate,
				@pbIsEventDateInUse = 1
    End
    Else 
    Begin
	   exec @nErrorCode= dbo.csw_InsertCaseEvent
				@pnUserIdentityId = @pnUserIdentityId,
				@pnCaseKey = @pnCaseKey,
				@pnEventKey = @pnEventKey,
				@pdtEventDate = @pdtEventDate,
				@pnCycle = 1
     End
End

-- Update Property
If @nErrorCode = 0
Begin	
if exists(SELECT 1 from PROPERTY 
            Where CASEID = @pnCaseKey)
Begin
	set @sSQLString = "UPDATE PROPERTY
		set PLACEFIRSTUSED = @psPlaceFirstUsed,
		PROPOSEDUSE = @psProposedUse
		where CASEID = @pnCaseKey
		and PLACEFIRSTUSED = @psOldPlaceFirstUsed
		and PROPOSEDUSE = @psOldProposedUse"

	 exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey            int,
			 @psPlaceFirstUsed     nvarchar(254),
			 @psProposedUse       nvarchar(254),
			 @psOldPlaceFirstUsed  nvarchar(254),
			 @psOldProposedUse    nvarchar(254)',
			 @pnCaseKey              = @pnCaseKey,
			 @psPlaceFirstUsed     = @psPlaceFirstUsed,
			 @psProposedUse       = @psProposedUse,
			 @psOldPlaceFirstUsed  = @psOldPlaceFirstUsed,
			 @psOldProposedUse    = @psOldProposedUse
End
Else 
    Begin
	   set @sSQLString = "Insert into PROPERTY(CASEID,PLACEFIRSTUSED,PROPOSEDUSE)
		   Values (@pnCaseKey,@psPlaceFirstUsed,@psProposedUse)"

	 exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey            int,
			 @psPlaceFirstUsed     nvarchar(254),
			 @psProposedUse       nvarchar(254)',
			 @pnCaseKey              = @pnCaseKey,
			 @psPlaceFirstUsed     = @psPlaceFirstUsed,
			 @psProposedUse       = @psProposedUse
     End
	                                        
 End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateFirstUseDetails to public
GO


