-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertTableAttribute
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertTableAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertTableAttribute.'
	Drop procedure [dbo].[ipw_InsertTableAttribute]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertTableAttribute...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertTableAttribute
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey 		int		= null,
	@pnCaseKey 		int		= null,
	@psCountryKey 		nvarchar(3)	= null,
	@pnAttributeKey		int		= null,
	@pnAttributeTypeKey	smallint	= null
)
as
-- PROCEDURE:	ipw_InsertTableAttribute
-- VERSION:	2
-- DESCRIPTION:	Add a new TableAttribute.

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

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

Declare @sGenericKey	nvarchar(20)
Declare @sParentTable	nvarchar(50)

-- Initialise variables
Set @nErrorCode 	= 0

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
	insert 	into TABLEATTRIBUTES
		(PARENTTABLE, 
		 GENERICKEY, 		 
		 TABLECODE,
		 TABLETYPE)
	values	(@sParentTable,
		 @sGenericKey, 		
		 @pnAttributeKey,
		 @pnAttributeTypeKey)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sParentTable		nvarchar(50),
					  @sGenericKey		nvarchar(20),
					  @pnAttributeKey	int,					 
					  @pnAttributeTypeKey	smallint',
					  @sParentTable		= @sParentTable,
					  @sGenericKey		= @sGenericKey,
					  @pnAttributeKey	= @pnAttributeKey,					 
					  @pnAttributeTypeKey	= @pnAttributeTypeKey	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertTableAttribute to public
GO