-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertDesignElements
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertDesignElements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertDesignElements.'
	Drop procedure [dbo].[csw_InsertDesignElements]
End
Print '**** Creating Stored Procedure dbo.csw_InsertDesignElements...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertDesignElements
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,            -- Mandatory
	@psFirmElementId	nvarchar(20),   -- Mandatory
	@psElementDesc          nvarchar(254)   = null,
	@psClientElementId       nvarchar(20)    = null,
	@pbRenewalFlag          bit             = 0,
	@pnTypeFace             int,            -- Mandatory
	@psOfficialElementId    nvarchar(20)    = null,
	@psRegistrationNo       nvarchar(36)    = null,
	@pnSequenceKey          int             = null OUTPUT,
	@pdtLastModifiedDate	datetime	= null	OUTPUT
)
as
-- PROCEDURE:	csw_InsertDesignElements
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a Design Element

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Jun 2011	DV	RFC4086	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
If @nErrorCode = 0
Begin
    Select @pnSequenceKey = IsNull(Max(SEQUENCE)+ 1,0) from  DESIGNELEMENT
        Where CASEID = @pnCaseKey   
End
If @nErrorCode = 0
Begin

	Set @sSQLString = "Insert into DESIGNELEMENT
			(CASEID, SEQUENCE, FIRMELEMENTID, ELEMENTDESC, CLIENTELEMENTID, 
			RENEWFLAG, TYPEFACE, OFFICIALELEMENTID, REGISTRATIONNO)
		values (@pnCaseKey, @pnSequenceKey, @psFirmElementId, @psElementDesc, @psClientElementId,
			@pbRenewalFlag, @pnTypeFace, @psOfficialElementId, @psRegistrationNo)
			
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	DESIGNELEMENT
		where	CASEID	= @pnCaseKey
		and	SEQUENCE = @pnSequenceKey
		"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnCaseKey		int,
		@pnSequenceKey		int output,
		@psFirmElementId	nvarchar(20),   
	        @psElementDesc          nvarchar(254),
	        @psClientElementId       nvarchar(20),
	        @pbRenewalFlag          bit,
	        @pnTypeFace             int,
	        @psOfficialElementId    nvarchar(20),
	        @psRegistrationNo       nvarchar(36),
		@pdtLastModifiedDate	datetime output',
		@pnCaseKey		= @pnCaseKey,
		@pnSequenceKey		= @pnSequenceKey output,
		@psFirmElementId        = @psFirmElementId,
		@psElementDesc          = @psElementDesc,
	        @psClientElementId       = @psClientElementId,
	        @pbRenewalFlag          = @pbRenewalFlag,
	        @pnTypeFace             = @pnTypeFace,
	        @psOfficialElementId    = @psOfficialElementId,
	        @psRegistrationNo       = @psRegistrationNo,
		@pdtLastModifiedDate	= @pdtLastModifiedDate output

	Select @pdtLastModifiedDate as LastModifiedDate, @pnSequenceKey as SequenceKey	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertDesignElements to public
GO