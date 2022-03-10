-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteTableAttribute
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteTableAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteTableAttribute.'
	Drop procedure [dbo].[ipw_DeleteTableAttribute]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteTableAttribute...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteTableAttribute
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey 		int		= null,
	@pnCaseKey 		int		= null,
	@psCountryKey 		nvarchar(3)	= null,
	@pnAttributeKey		int		= null,
	@pnOldAttributeTypeKey	smallint	= null
)
as
-- PROCEDURE:	ipw_DeleteTableAttribute
-- VERSION:	2
-- DESCRIPTION:	Delete a Table Attribute if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Oct 2004	TM	RFC1814	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @sGenericKey		nvarchar(20)
Declare @sParentTable		nvarchar(50)

-- Initialise variables
Set @nErrorCode 		= 0

If @pnNameKey is not null
and @nErrorCode = 0
Begin
	Set @sGenericKey = cast(@pnNameKey as varchar(11))
	Set @sParentTable = 'NAME'
End
Else If @pnCaseKey is not null
and @nErrorCode = 0
Begin
	Set @sGenericKey = cast(@pnCaseKey as varchar(11))
	Set @sParentTable = 'CASES'
End
Else If @psCountryKey is not null
and @nErrorCode = 0
Begin
	Set @sGenericKey = @psCountryKey
	Set @sParentTable = 'COUNTRY'
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete TABLEATTRIBUTES
	where	PARENTTABLE 	= @sParentTable
	and	GENERICKEY 	= @sGenericKey		
	and	TABLECODE 	= @pnAttributeKey
	and 	TABLETYPE	= @pnOldAttributeTypeKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sParentTable		nvarchar(50),
					  @sGenericKey		nvarchar(20),					
					  @pnAttributeKey	int,
					  @pnOldAttributeTypeKey smallint',
					  @sParentTable		= @sParentTable,
					  @sGenericKey		= @sGenericKey,	
					  @pnAttributeKey	= @pnAttributeKey,					  
					  @pnOldAttributeTypeKey= @pnOldAttributeTypeKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteTableAttribute to public
GO
