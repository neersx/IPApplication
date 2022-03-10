-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteFilesIn									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteFilesIn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteFilesIn.'
	Drop procedure [dbo].[naw_DeleteFilesIn]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteFilesIn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteFilesIn
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@psCountryCode		nvarchar(3),	-- Mandatory
	@psOldNotes		nvarchar(254)	= null,
	@pbIsNotesInUse		bit	 	= 0
)
as
-- PROCEDURE:	naw_DeleteFilesIn
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete FilesIn if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 11 Apr 2006	IB	RFC3762	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from FILESIN
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @pnNameKey and
		COUNTRYCODE = @psCountryCode"

	Set @sAnd = " and "

	If @pbIsNotesInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"NOTES = @psOldNotes"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
				@pnNameKey	int,
				@psCountryCode	nvarchar(3),
				@psOldNotes	nvarchar(254)',
				@pnNameKey	 = @pnNameKey,
				@psCountryCode	 = @psCountryCode,
				@psOldNotes	 = @psOldNotes


End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteFilesIn to public
GO

