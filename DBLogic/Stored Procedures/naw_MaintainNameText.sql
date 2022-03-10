-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_MaintainNameText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_MaintainNameText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_MaintainNameText.'
	Drop procedure [dbo].[naw_MaintainNameText]
End
Print '**** Creating Stored Procedure dbo.naw_MaintainNameText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_MaintainNameText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory	
	@psTextTypeKey		nvarchar(2),	-- Mandatory
	@pbIsNew		tinyint,	-- Mandatory
	@ptText			ntext		= null,
	@pdtLastModified	datetime	= null	
)
as
-- PROCEDURE:	naw_MaintainNameText
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Maintain free-form text against a Name.  It adds, updates and deletes text.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 SEP 2006	SF	4331	1	Procedure created
-- 02 SEP 2009	NG	7465	2	Update EXTENDEDNAMEFLAG when name text of text type Extended Name is saved.
-- 12 Sep 2013  MS      DR913   3       Check LogDateTimeStamp rather than old text

-- Row counts required by the data adapter
SET NOCOUNT OFF

SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
and @pbIsNew = 0
Begin
	-- Update the text if original text is the same as the one in the database. 
	Set @sSQLString = " 
	update 	NAMETEXT
	set	TEXT 	 = @ptText
	where	NAMENO	 = @pnNameKey
	and	TEXTTYPE = @psTextTypeKey	
	and (LOGDATETIMESTAMP = @pdtLastModified or (LOGDATETIMESTAMP is null and @pdtLastModified is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psTextTypeKey	nvarchar(2),
					  @ptText		ntext,					 
					  @pdtLastModified 	datetime',
					  @pnNameKey		= @pnNameKey,
					  @psTextTypeKey	= @psTextTypeKey,
					  @ptText		= @ptText,					
					  @pdtLastModified	= @pdtLastModified			
End
Else
Begin
	
	-- If it is new, insert the text
	Set @sSQLString = " 
	insert 	into NAMETEXT
		(NAMENO, 
		 TEXTTYPE, 		 
		 TEXT)
	values	(@pnNameKey,
		 @psTextTypeKey, 		
		 @ptText)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psTextTypeKey	nvarchar(2),					 
					  @ptText		ntext',
					  @pnNameKey		= @pnNameKey,
					  @psTextTypeKey	= @psTextTypeKey,
					  @ptText		= @ptText	

End

If @nErrorCode = 0 and @psTextTypeKey = 'N' and @ptText is not null
Begin
	If exists (select * from NAME N where N.NAMENO = @pnNameKey and 
				(N.EXTENDEDNAMEFLAG is null or N.EXTENDEDNAMEFLAG = 0))
	Begin
		Update NAME
		Set EXTENDEDNAMEFLAG = 1 
		where NAMENO = @pnNameKey
	End
End


Return @nErrorCode
GO

Grant execute on dbo.naw_MaintainNameText to public
GO
