-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteFileLocation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteFileLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteFileLocation.'
	Drop procedure [dbo].[csw_DeleteFileLocation]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteFileLocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteFileLocation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pdtWhenMoved			datetime,	-- Mandatory	
	@pdtLogDateTimeStamp		datetime	= null
)
as
-- PROCEDURE:	csw_DeleteFileLocation
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete FileLocation if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jul 2006	SW	RFC2307	1	Procedure created
-- 24 Jun 2011  MS      RFC8363 2       Removed Old and in use parameters and added LogDateTimeStamp

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Delete from CASELOCATION
		where CASEID = @pnCaseKey and 
		WHENMOVED = @pdtWhenMoved
                and LOGDATETIMESTAMP = @pdtLogDateTimeStamp"	

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@pdtWhenMoved		datetime,
				@pdtLogDateTimeStamp	datetime',
				@pnCaseKey	 	= @pnCaseKey,
				@pdtWhenMoved	 	= @pdtWhenMoved,				
				@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteFileLocation to public
GO
