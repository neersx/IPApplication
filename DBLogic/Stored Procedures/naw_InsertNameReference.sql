-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertNameReference
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertNameReference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertNameReference.'
	Drop procedure [dbo].[naw_InsertNameReference]
End
Print '**** Creating Stored Procedure dbo.naw_InsertNameReference...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertNameReference
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int = null,		-- Mandatory
	@psAlias		nvarchar(30),		-- Mandatory
	@psAliasTypeKey		nvarchar(2),		-- Mandatory
	@psCountryCode		nvarchar(3)	= null,	-- the Country the Alias applies to
	@psPropertyType		nvarchar(2)	= null	-- the Property Type the Alias applies to
)
as
-- PROCEDURE:	naw_InsertNameReference
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Name Reference (Name Alias).

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------  
-- 24 Oct 2008	PS	RFC6461	1	Procedure created
-- 04 Jun 2010	MF	18703	2	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE and can be included in the Insert

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0


If @nErrorCode = 0
Begin
		Set @sSQLString = "Insert into NAMEALIAS ( NAMENO, ALIASTYPE, ALIAS, COUNTRYCODE, PROPERTYTYPE) 
				   values (@pnNameKey, @psAliasTypeKey, @psAlias, @psCountryCode,@psPropertyType)" 
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey		int,
				@psAliasTypeKey		nvarchar(2),
				@psAlias		nvarchar(30),
				@psCountryCode		nvarchar(3),
				@psPropertyType		nvarchar(2)',
				@pnNameKey	 	= @pnNameKey,
				@psAliasTypeKey	 	= @psAliasTypeKey,
				@psAlias	 	= @psAlias,
				@psCountryCode		= @psCountryCode,
				@psPropertyType		= @psPropertyType
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertNameReference to public
GO
