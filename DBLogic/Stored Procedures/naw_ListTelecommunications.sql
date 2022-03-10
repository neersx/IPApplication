-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListTelecommunications
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListTelecommunications]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListTelecommunications.'
	Drop procedure [dbo].[naw_ListTelecommunications]
End
Print '**** Creating Stored Procedure dbo.naw_ListTelecommunications...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListTelecommunications
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,
	@pbExcludeMain		bit		= null, -- Exclude main phone and fax
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListTelecommunications
-- VERSION:	9
-- DESCRIPTION:	Lists all the telecommunication numbers for a given name, formatted for display.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2003	JEK	RFC621	1	Procedure created
-- 03 Sep 2004	TM	RFC1158	2	Add new IsReminderEmails, Carrier and Description columns.
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
-- 21 Oct 2004	TM	RFC1538	4	Implement flags to identify telecommunication entries.
-- 27 Oct 2004	TM	RFC1538	5	The site control has the Telecom Type in it, not the TeleCode.
-- 22 Nov 2004	TM	RFC2007	6	Correct the SiteControl spelling.
-- 15 May 2005	JEK	RFC2508	7	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 28 Aug 2006	SF	RFC4214	6	Add RowKey
-- 11 Dec 2008	MF	17136	8	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 11 Apr 2013	DV	R13270	9	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

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

	"	CAST(T.REMINDEREMAILS as bit)"+CHAR(10)+
	"			as 'IsReminderEmails',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TT1',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Carrier',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('NAMETELECOM','TELECOMDESC',null,'NT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description',"+CHAR(10)+
	"	CASE WHEN N.MAINPHONE = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainPhone',"+CHAR(10)+
	"	CASE WHEN N.FAX = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainFax',"+CHAR(10)+
	"	CASE WHEN N.MAINEMAIL = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainEmail',"+CHAR(10)+
	"	CASE WHEN SC.COLINTEGER = T.TELECOMTYPE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsHomePage',"+CHAR(10)+
	"	CAST(N.NAMENO as nvarchar(11)) + '^' + CAST(T.TELECOMTYPE as nvarchar(11)) + '^' + CAST(NT.TELECODE as nvarchar(11))"+CHAR(10)+
	"			as 'RowKey'"+CHAR(10)+ 	
	"from NAME N"+CHAR(10)+
	"join NAMETELECOM NT	 	on (NT.NAMENO = N.NAMENO)"+CHAR(10)+
	"join TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE)"+CHAR(10)+
	"join TABLECODES TT		on (TT.TABLECODE = T.TELECOMTYPE)"+CHAR(10)+ 
	"left join TABLECODES TT1	on (TT1.TABLECODE = T.CARRIER)"+CHAR(10)+ 
	"left join SITECONTROL SC	on (SC.CONTROLID = 'Telecom Type - Home Page')"+CHAR(10)+ 
	"where N.NAMENO = @pnNameKey"+CHAR(10)

	If (@pbExcludeMain = 1)
	begin
		Set @sSQLString = @sSQLString +
		"and	T.TELECODE NOT IN (N.MAINPHONE,N.FAX)"+CHAR(10)
	end

	Set @sSQLString = @sSQLString +
	"order by 'IsMainPhone' DESC, 'IsMainFax' DESC, 'IsMainEmail' DESC, 'IsHomePage' DESC, 'DeviceType' ASC"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int',
					  @pnNameKey			= @pnNameKey

	Set @pnRowCount = @@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListTelecommunications to public
GO
