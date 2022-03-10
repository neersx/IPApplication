-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListImage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListImage.'
	Drop procedure [dbo].[ip_ListImage]
End
Print '**** Creating Stored Procedure dbo.ip_ListImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ListImage
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnImageKey	int		-- Mandatory
)
as
-- PROCEDURE:	ip_ListImage
-- VERSION:	3
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 03-NOV-2003  SHOY	RFC581	1	Procedure created
-- 30-OCT-2007  SW	RFC5892	2	Implement security check
-- 18-APR-2008	AT	RFC6079	3	Add Name Image secuirty check


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @bIsExternalUser	bit

Set	@nErrorCode      = 0

-- Extract the @bIsExternalUser from UserIdentity if it has not been supplied.
If @nErrorCode=0
Begin		
	Set @sSQLString='
	Select @bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode=0
Begin	
	Set @sSQLString="
	select 	isnull(IMAGEDETAIL.CONTENTTYPE,'image/png') as 'ContentType', 
		IMG.IMAGEDATA 		as 'ImageData'
	from 	IMAGE IMG
	left join IMAGEDETAIL on IMAGEDETAIL.IMAGEID = IMG.IMAGEID
	where 	IMG.IMAGEID = @pnImageKey " +
	Case @bIsExternalUser
	When 1
	Then 
		"and IMG.IMAGEID in 
			(select CI.IMAGEID
			from CASEIMAGE CI
			join dbo.fn_FilterUserCases(@pnUserIdentityId,null,null) FC on (FC.CASEID = CI.CASEID)
			UNION
			select NI.IMAGEID
			from NAMEIMAGE NI
			join dbo.fn_FilterUserNames(@pnUserIdentityId,1) FN on (FN.NAMENO = NI.NAMENO)
			)"
	Else
		""
	End

	exec sp_executesql @sSQLString,
				N'@pnImageKey		int,
				  @pnUserIdentityId	int',
				  @pnImageKey		=@pnImageKey,
				  @pnUserIdentityId	=@pnUserIdentityId
	
	Set @nErrorCode = @@error
End


Return @nErrorCode
GO

Grant execute on dbo.ip_ListImage to public
GO
