-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateNameReference
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateNameReference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateNameReference.'
	Drop procedure [dbo].[naw_UpdateNameReference]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateNameReference...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateNameReference
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int = null,	-- Mandatory
	@psAlias		nvarchar(30),	-- Mandatory
	@psAliasTypeKey		nvarchar(2),	-- Mandatory
	@psOldAlias		nvarchar(30)	= null,
	@psOldAliasTypeKey	nvarchar(2)	= null,	

	@pnAliasNo		int,			-- Mandatory identifier of NAMEALIAS row

	@psCountryCode		nvarchar(3)  = null,	-- the Country the Alias applies to
	@psPropertyType		nvarchar(2)  = null	-- the Property Type the Alias applies to	

)
as
-- PROCEDURE:	naw_UpdateNameReference
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update NameReference if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Oct 2008	PS	RFC6461	1	Procedure created
-- 04 Jun 2010	MF	18703	2	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be considered in the Update.
-- 02 Jul 2010  PA  RFC9423 3   Declared the parameters @pnAliasNo, @psCountryCode and @psPropertyType

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)



-- Initialise variables
Set @nRowCount = 1 -- anything not zero
Set @nErrorCode = 0


If @nErrorCode = 0
Begin

	Set @sSQLString = 
	"Update NAMEALIAS 
	set ALIASTYPE   = @psAliasTypeKey, 
	    ALIAS       = @psAlias,
	    COUNTRYCODE = @psCountryCode,
	    PROPERTYTYPE= @psPropertyType
	where NAMENO  = @pnNameKey 
	and ALIASTYPE = @psOldAliasTypeKey
	and ALIASNO   = @pnAliasNo"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@psAliasTypeKey		nvarchar(2),
			@psAlias		nvarchar(30),
			@psOldAliasTypeKey	nvarchar(2),
			@psOldAlias		nvarchar(30),
			@pnAliasNo		int,
            @psCountryCode nvarchar(3),
			@psPropertyType nvarchar(2)',
			@pnNameKey	 	= @pnNameKey,
			@psAliasTypeKey	 	= @psAliasTypeKey,
			@psAlias	 	= @psAlias,
			@psOldAliasTypeKey	= @psOldAliasTypeKey,
			@psOldAlias	 	= @psOldAlias,
			@pnAliasNo		= @pnAliasNo,
            @psCountryCode  = @psCountryCode,
			@psPropertyType = @psPropertyType
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateNameReference to public
GO
