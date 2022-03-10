-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListPreference
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListPreference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListPreference.'
	Drop procedure [dbo].[ua_ListPreference]
End
Print '**** Creating Stored Procedure dbo.ua_ListPreference...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_ListPreference
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,	-- The language in which output is to be expressed.
	@psSettingKeys		nvarchar(4000)	= null
)
as
-- PROCEDURE:	ua_ListPreference
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Gets the value of a particular preference for a particular user.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 30 AUG 2005	TM	RFC2953		1	Procedure created
-- 26 Jul 2011	SF	RFC11013	2	Allow multiple site controls to be queried and returned
-- 05 Jul 2013	SF	DR-198		3	Return SettingName with the setting
-- 07 Sep 2018	AV	74738	4	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sControlIdsInClause	nvarchar(4000)
Declare @bCalledFromCentura	bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @bCalledFromCentura = 0
 
If @nErrorCode = 0
Begin
	Set @sControlIdsInClause = null
	Select @sControlIdsInClause = @sControlIdsInClause+ isnull(nullif(',', ',' + @sControlIdsInClause), '') 
		+ dbo.fn_WrapQuotes(Parameter,0,@bCalledFromCentura)
	from dbo.fn_Tokenise(@psSettingKeys, ',')
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	SD.SETTINGID	as 'SettingId',
		SD.DATATYPE 	as 'DataType',
		SD.SETTINGNAME	as 'SettingName',
		ISNULL(SVI.COLINTEGER, SVD.COLINTEGER)		
				as 'IntegerValue',
		ISNULL(SVI.COLCHARACTER, SVD.COLCHARACTER)		
				as 'StringValue',
		ISNULL(SVI.COLDECIMAL, SVD.COLDECIMAL)
				as 'DecimalValue',
		ISNULL(SVI.COLBOOLEAN, SVD.COLBOOLEAN)
				as 'BooleanValue'
	from SETTINGDEFINITION SD
	join USERIDENTITY UI		on (UI.IDENTITYID = @pnUserIdentityId
					-- The setting should only be returned for an external 
					-- user if it is available for external use
					and((UI.ISEXTERNALUSER = 1 and SD.ISEXTERNAL = 1)
					-- The setting should only be returned for an internal 
					-- user if it is available for internal use 
					 or (UI.ISEXTERNALUSER = 0 and SD.ISINTERNAL = 1)
					 or (SD.ISEXTERNAL = 1 	   and SD.ISINTERNAL = 1)))
	-- Default settings for the firm as a whole are available in SETTINGVALUES with 
	-- an IDENTITYID of null. This value is returned if there is not a specific value for 
	-- the @pnUserIdentityId.
	left join SETTINGVALUES SVI	on (SVI.SETTINGID = SD.SETTINGID
					and SVI.IDENTITYID = @pnUserIdentityId)
	left join SETTINGVALUES SVD	on (SVD.SETTINGID = SD.SETTINGID	
					and SVD.IDENTITYID is null)
	where SD.SETTINGID in (" + @sControlIdsInClause + ")
	and (SVD.SETTINGID is not null 
	 or SVI.SETTINGID is not null)"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
					  @pnUserIdentityId	= @pnUserIdentityId
End

Return @nErrorCode
GO

Grant execute on dbo.ua_ListPreference to public
GO
