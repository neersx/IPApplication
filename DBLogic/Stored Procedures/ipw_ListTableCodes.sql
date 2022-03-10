---------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListTableCodes 
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListTableCodes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListTableCodes.'
	drop procedure [dbo].[ipw_ListTableCodes]
	Print '**** Creating Stored Procedure dbo.ipw_ListTableCodes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListTableCodes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTableTypeKey 	smallint,	-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@pbIsKeyUserCode	bit		= 0,
	@psFilterSiteControlKey	nvarchar(30)	= null,
	@pbIsExternalUser	bit 		= null,
	@psUserCode			nvarchar(10) = null
)
AS
-- PROCEDURE:	ipw_ListTableCodes
-- VERSION:	7
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists TableCodes for a certain @pnTableTypeKey.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM	1	Procedure created
-- 15 Sep 2004	JEK	2	RFC886 	Implement translation.
-- 15 May 2005	JEK	3	RFC2508	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 27 Mar 2006	IB	4	RFC3378	Add @pbIsKeyUserCode parameter.  When the parameter is 1 return
--					TABLECODES.USERCODE db column as 'Key' column.
-- 15 May 2006	SW	5	RFC2985	Add new optional parameter @psFilterSiteControlKey.  
--					If called by an external user and the parameter is provided, filter the list using fn_FilterUserTableCodes above.
-- 04 Dec 2006  PG	6	Add @pbIsExternalUser parameter 
-- 01 Feb 2011	DV	7	Add @psUsercode	parameter and filter results if @psUsercode is not null and check for log table if TABLETYPE = -502
-- 03 Aug 2017	SF  8   @psUserCode has capital C, on case insensitive database on a case sensitive server this still breaks.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
If @nErrorCode = 0 and @pbIsExternalUser is null
Begin

	Set @sSQLString = '
		Select	@pbIsExternalUser=ISEXTERNALUSER
		from	USERIDENTITY
		where	IDENTITYID=@pnUserIdentityId
	'

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId		int,
				  @pbIsExternalUser		bit			OUTPUT',
				  @pnUserIdentityId		= @pnUserIdentityId,
				  @pbIsExternalUser		= @pbIsExternalUser	OUTPUT

End

If @nErrorCode = 0
Begin
	If @pbIsKeyUserCode = 1
	Begin
		Set @sSQLString = "
		Select 	T.USERCODE 	as 'Key',"+char(10)
	End
	Else
	Begin
		Set @sSQLString = "
		Select 	T.TABLECODE 	as 'Key',"+char(10)
	End

	Set @sSQLString = @sSQLString +
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description' 
		from 	TABLECODES T" +char(10)	
	
	If (@pnTableTypeKey is not null and @pnTableTypeKey = -502)
	Begin
		Set @sSQLString = @sSQLString + " 
		join INFORMATION_SCHEMA.TABLES TB on (TB.TABLE_NAME=substring(T.DESCRIPTION,1,patindex('%.%',T.DESCRIPTION)-1)+'_iLOG')"
	End
	
	If @pbIsExternalUser = 1 and @psFilterSiteControlKey is not null
	Begin
		If @pbIsKeyUserCode = 1
		Begin	
			Set @sSQLString = @sSQLString +
				"join dbo.fn_FilterUserTableCodes(@pnUserIdentityId, @pnTableTypeKey, @psFilterSiteControlKey, @pbCalledFromCentura) FILTER on (FILTER.TABLECODE = T.USERCODE)"
		End
		Else
		Begin	
			Set @sSQLString = @sSQLString +
				"join dbo.fn_FilterUserTableCodes(@pnUserIdentityId, @pnTableTypeKey, @psFilterSiteControlKey, @pbCalledFromCentura) FILTER on (FILTER.TABLECODE = T.TABLECODE)"
		End
	End

	Set @sSQLString = @sSQLString + "
		where 	T.TABLETYPE = @pnTableTypeKey "
	
	If (@pnTableTypeKey is not null and @pnTableTypeKey = -502)
	Begin
		Set @sSQLString = @sSQLString + " 
		and 	patindex('%.%',T.DESCRIPTION)>1 "
	End
	
	If @psUserCode is not null
	Begin
		Set @sSQLString = @sSQLString + " 
		and 	T.USERCODE = @psUserCode "
	End
	
	Set @sSQLString = @sSQLString + " order by 2"
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @pnTableTypeKey		smallint,
					  @psFilterSiteControlKey	nvarchar(30),
					  @pbCalledFromCentura		bit,
					  @psUserCode				nvarchar(10)',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnTableTypeKey		= @pnTableTypeKey,
					  @psFilterSiteControlKey	= @psFilterSiteControlKey,
					  @pbCalledFromCentura		= @pbCalledFromCentura,
					  @psUserCode				= @psUserCode

	Set @pnRowCount = @@Rowcount
End	

Return @nErrorCode
GO

Grant exec on dbo.ipw_ListTableCodes to public
GO
