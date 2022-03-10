-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListCorrespondenceInstructionsData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListCorrespondenceInstructionsData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListCorrespondenceInstructionsData.'
	Drop procedure [dbo].[naw_ListCorrespondenceInstructionsData]
End
Print '**** Creating Stored Procedure dbo.naw_ListCorrespondenceInstructionsData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListCorrespondenceInstructionsData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListCorrespondenceInstructionsData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the NameCorrespondenceInstructionsData dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Aug 2009	MS	RFC8288	1	Procedure created
-- 18 Oct 2011  MS      R10177  2       removed USEDASFLAG check from where condition
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer
-- 12 Sep 2013  MS      DR913   4       Added ModifiedDate in resultset
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnNameKey 	as NameKey,
		dbo.fn_FormatNameUsingNameNo(@pnNameKey, NULL) as Name"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey	int',
					  @pnNameKey	= @pnNameKey
End

-- Populating Correspondence Instructions result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select cast(@pnNameKey as nvarchar(11)) + '^-1' as RowKey,
		@pnNameKey 		as NameKey,
		'-1'			as TextTypeKey,		
		CASE WHEN IP.CORRESPONDENCE is null or IP.CORRESPONDENCE = ''
			THEN 1
			ELSE 0 END	as IsNew,
		IP.CORRESPONDENCE	as Text,
		IP.LOGDATETIMESTAMP     as ModifiedDate
	from IPNAME IP 
	where IP.NAMENO =  @pnNameKey
	UNION	
	Select cast(@pnNameKey as nvarchar(11)) + '^' + TT.TEXTTYPE as RowKey,
		@pnNameKey 		as NameKey,
		TT.TEXTTYPE		as TextTypeKey,		
		CASE WHEN NT.NAMENO=@pnNameKey 
			THEN 0 
			ELSE 1 END	as IsNew,
		Cast(NT.TEXT as NVARCHAR(MAX)) as Text,		
		NT.LOGDATETIMESTAMP     as ModifiedDate
	from TEXTTYPE TT	
	left join NAMETEXT NT		on (NT.TEXTTYPE = TT.TEXTTYPE and NT.NAMENO = @pnNameKey)
	where TT.TEXTTYPE in ('CB','CC','CP')"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int',
				  @pnNameKey		= @pnNameKey

End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListCorrespondenceInstructionsData to public
GO
