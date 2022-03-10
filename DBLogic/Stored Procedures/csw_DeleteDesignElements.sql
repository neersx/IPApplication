-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteDesignElements
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteDesignElements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteDesignElements.'
	Drop procedure [dbo].[csw_DeleteDesignElements]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteDesignElements...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_DeleteDesignElements
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,	        -- Mandatory
	@pnSequenceKey		int,	        -- Mandatory
	@pbDeleteImage          bit,            -- Mandatory
	@psFirmElementID        nvarchar(20)    = null, 
	@pdtLastModifiedDate	datetime = null
)
as
-- PROCEDURE:	csw_DeleteDesignElements
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Design Element

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Jun 2011	DV	RFC4086	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
        If @pbDeleteImage = 0 and @psFirmElementID is not null
        Begin
              Set @sSQLString = "UPDATE CASEIMAGE
                Set FIRMELEMENTID = null
		where	CASEID		 = @pnCaseKey
		and	FIRMELEMENTID	 = @psFirmElementID"  
		
	      exec @nErrorCode=sp_executesql @sSQLString,
      		                N'
	                @pnCaseKey		int,	               
	                @psFirmElementID	nvarchar(20)',
	                @pnCaseKey		= @pnCaseKey,
	                @psFirmElementID	= @psFirmElementID
        End
        Else If @psFirmElementID is not null
        Begin 
              Set @sSQLString = "Delete from CASEIMAGE                
		where	CASEID		 = @pnCaseKey
		and	FIRMELEMENTID	 = @psFirmElementID" 
		
	      exec @nErrorCode=sp_executesql @sSQLString,
      		                N'
	                @pnCaseKey		int,	               
	                @psFirmElementID	nvarchar(20)',
	                @pnCaseKey		= @pnCaseKey,
	                @psFirmElementID	= @psFirmElementID
        End
        
        
        If @nErrorCode = 0
        Begin
                Set @sSQLString = "Delete from DESIGNELEMENT
	                where	CASEID		 = @pnCaseKey
	                and	SEQUENCE	 = @pnSequenceKey
	                and	LOGDATETIMESTAMP = @pdtLastModifiedDate"

                exec @nErrorCode=sp_executesql @sSQLString,
      		                N'
	                @pnCaseKey		int,
	                @pnSequenceKey		int,
	                @pdtLastModifiedDate	datetime',
	                @pnCaseKey		= @pnCaseKey,
	                @pnSequenceKey		= @pnSequenceKey,
	                @pdtLastModifiedDate	= @pdtLastModifiedDate
        End

End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteDesignElements to public
GO

