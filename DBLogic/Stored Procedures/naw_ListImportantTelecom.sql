-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListImportantTelecom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListImportantTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListImportantTelecom.'
	Drop procedure [dbo].[naw_ListImportantTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_ListImportantTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.naw_ListImportantTelecom
(
	@pnRowCount			int		= null	output, 
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey			int, 		-- Mandatory
	@pbCalledFromCentura		bit		= 0
)
AS
-- PROCEDURE:	naw_ListImportantTelecom
-- VERSION:	2

-- DESCRIPTION:	List the main phone/fax/email and home page for the name

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Apr 2006	SW	RFC3301	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 		nvarchar(4000)
Declare @nErrorCode		int
Declare @nRowCount		int

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode 		 = 0
Set	@nRowCount		 = 0

-- Populating Telecommunications result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  N.NAMENO	as 'NameKey',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'DeviceType',"+CHAR(10)+
	"	dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION)"+CHAR(10)+
	"			as 'TelecomNumber',"+CHAR(10)+
	"	case when T.TELECOMTYPE = 1903 THEN 1 ELSE 0 END"+CHAR(10)+
	"			as 'IsEmailAddress',"+CHAR(10)+
	"	CASE WHEN N.MAINPHONE = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainPhone',"+CHAR(10)+
	"	CASE WHEN N.FAX = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainFax',"+CHAR(10)+
	"	CASE WHEN N.MAINEMAIL = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainEmail',"+CHAR(10)+
	"	CASE WHEN SC.COLINTEGER = T.TELECOMTYPE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsHomePage',"+CHAR(10)+
	"	convert(nvarchar(11),NT.NAMENO)+'^'+convert(nvarchar(11),NT.TELECODE) as 'RowKey'"+CHAR(10)+
	"from NAME N"+CHAR(10)+
	"join NAMETELECOM NT	 	on (NT.NAMENO = N.NAMENO)"+CHAR(10)+
	"join TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE)"+CHAR(10)+
	"join TABLECODES TT		on (TT.TABLECODE = T.TELECOMTYPE)"+CHAR(10)+ 
	"left join SITECONTROL SC	on (SC.CONTROLID = 'Telecom Type - Home Page')"+CHAR(10)+ 
	"where N.NAMENO = @pnNameKey"+CHAR(10)+
	"and   (T.TELECODE IN (N.MAINPHONE,N.FAX, N.MAINEMAIL)"+CHAR(10)+
	" or    SC.COLINTEGER = T.TELECOMTYPE)"+CHAR(10)+
	"order by CASE WHEN N.MAINPHONE = T.TELECODE THEN 0"+CHAR(10)+
	"	     WHEN N.FAX = T.TELECODE THEN 1"+CHAR(10)+
	"	     WHEN N.MAINEMAIL = T.TELECODE THEN 2"+CHAR(10)+
	"	     WHEN SC.COLINTEGER = T.TELECOMTYPE THEN 3"+CHAR(10)+
	"	ELSE 4 END, TelecomNumber"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int',
					  @pnNameKey			= @pnNameKey

	Set @pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListImportantTelecom to public
GO


