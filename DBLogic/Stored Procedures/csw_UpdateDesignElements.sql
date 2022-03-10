-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateDesignElements
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateDesignElements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateDesignElements.'
	Drop procedure [dbo].[csw_UpdateDesignElements]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateDesignElements...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_UpdateDesignElements
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,            -- Mandatory
	@pnSequence		int,            -- Mandatory
	@psFirmElementId	nvarchar(20),   -- Mandatory
	@psElementDesc          nvarchar(254)   = null,
	@psClientElementId       nvarchar(20)    = null,
	@pbRenewalFlag          bit             = 0,
	@pnTypeFace             int,            -- Mandatory
	@psOfficialElementId    nvarchar(20)    = null,
	@psRegistrationNo       nvarchar(36)    = null,
	@pdtLastModifiedDate	datetime	= null OUTPUT

)
as
-- PROCEDURE:	csw_UpdateDesignElements
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update a Design Element

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Jun 2011	DV	RFC6563	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)
Declare @dToday			datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dToday = getDate()

If @nErrorCode = 0
Begin

	Set @sSQLString = "UPDATE DESIGNELEMENT SET
                        FIRMELEMENTID           = @psFirmElementId, 
                        ELEMENTDESC             = @psElementDesc, 
                        CLIENTELEMENTID         = @psClientElementId, 
			RENEWFLAG             = @pbRenewalFlag, 
			TYPEFACE                = @pnTypeFace, 
			OFFICIALELEMENTID       = @psOfficialElementId,
			REGISTRATIONNO          = @psRegistrationNo
		where	CASEID	        = @pnCaseKey
		and	SEQUENCE	= @pnSequence
		and     LOGDATETIMESTAMP = @pdtLastModifiedDate
		
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	DESIGNELEMENT
		where	CASEID	        = @pnCaseKey
		and	SEQUENCE	= @pnSequence
			"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnCaseKey		int,
		@pnSequence		int,
		@psFirmElementId	nvarchar(20),   
	        @psElementDesc          nvarchar(254),
	        @psClientElementId       nvarchar(20),
	        @pbRenewalFlag          bit,
	        @pnTypeFace             int,
	        @psOfficialElementId    nvarchar(20),
	        @psRegistrationNo       nvarchar(36),
		@pdtLastModifiedDate	datetime output',
		@pnCaseKey		= @pnCaseKey,
		@pnSequence		= @pnSequence,
		@psFirmElementId        = @psFirmElementId,
		@psElementDesc          = @psElementDesc,
	        @psClientElementId       = @psClientElementId,
	        @pbRenewalFlag          = @pbRenewalFlag,
	        @pnTypeFace             = @pnTypeFace,
	        @psOfficialElementId    = @psOfficialElementId,
	        @psRegistrationNo       = @psRegistrationNo,
		@pdtLastModifiedDate	= @pdtLastModifiedDate output

        Select @pdtLastModifiedDate as LastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateDesignElements to public
GO