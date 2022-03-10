-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAddresses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAddresses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAddresses.'
	Drop procedure [dbo].[naw_ListAddresses]
End
Print '**** Creating Stored Procedure dbo.naw_ListAddresses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListAddresses
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,
	@pbExcludeMain		bit		= null, -- Exclude main street and postal addresses
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListAddresses
-- VERSION:	13
-- DESCRIPTION:	Lists all the addresses for a given name, formatted for an envelope.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2003	JEK	RFC621	1	Procedure created
-- 01 Jul 2004	TM	RFC910	2	Add new Status column. 
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
-- 29 Sep 2004	TM	RFC1806	4	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.	
-- 15 May 2005	JEK	RFC2508	5	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 28 Aug 2006	SF	RFC4214	6	Add RowKey
-- 29 Nov 2007  PG	RFC3497 7	Return IsMain
-- 13 Jan 2009	SF	RFC7479	8	Return IsOwner and IsLinked
-- 29 Dec 2009  ASH	RFC8606 9	Add new DateCeased column.
-- 22 Feb 2010  ASH	RFC7343 10	Add new Phone and Fax columns.
-- 26 Jul 2010	SF	RFC9563	11	Ensure IsOwner flag is returned as either a 0 or a 1.
-- 11 Apr 2013	DV	R13270	12	Increase the length of nvarchar to 11 when casting or declaring integer
-- 17 Mar 2017	MF	70924	13	Postal address is not taking the users culture into consideration.	

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
	Select	N.NAMENO	as 'NameKey',"+CHAR(10)+ 
	"	A.ADDRESSCODE	as 'AddressCode',"+CHAR(10)+ 
	"	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'AT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'AddressType',"+CHAR(10)+ 
	"	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Status',"+CHAR(10)+
	"	dbo.fn_FormatAddress("+dbo.fn_SqlTranslatedColumn('ADDRESS','STREET1',null,'A',@sLookupCulture,@pbCalledFromCentura)+", 
				     A.STREET2, 
				     "+dbo.fn_SqlTranslatedColumn('ADDRESS','CITY',null,'A',@sLookupCulture,@pbCalledFromCentura)+", 
				     "+dbo.fn_SqlTranslatedColumn('ADDRESS','STATE',null,'A',@sLookupCulture,@pbCalledFromCentura)+", 
				     "+dbo.fn_SqlTranslatedColumn('STATE','STATENAME',null,'S',@sLookupCulture,@pbCalledFromCentura)+", 
				     A.POSTCODE, 
				     "+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'C',@sLookupCulture,@pbCalledFromCentura)+", 
				     C.POSTCODEFIRST, 
				     C.STATEABBREVIATED, 
				     "+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTCODELITERAL',null,'C',@sLookupCulture,@pbCalledFromCentura)+", 
				     C.ADDRESSSTYLE)"+CHAR(10)+ 
	"			as 'Address',"+CHAR(10)+ 
	"	CAST(N.NAMENO as nvarchar(11)) + '^' + CAST(NA.ADDRESSTYPE as nvarchar(11)) + '^' + CAST(A.ADDRESSCODE as nvarchar(11))"+CHAR(10)+
	"			as 'RowKey',"+CHAR(10)+
	" CASE"+char(10)+
	"		WHEN (   (NA.ADDRESSTYPE = 301 and N.POSTALADDRESS = NA.ADDRESSCODE)"+char(10)+
	"		      or (NA.ADDRESSTYPE = 302 and N.STREETADDRESS = NA.ADDRESSCODE))"+char(10)+
	"		THEN cast(1 as bit)"+char(10)+
	"		ELSE cast(0 as bit)"+char(10)+
	"	END			as IsMain,"+char(10)+ 	
	"CASE WHEN AC.UsedByNameCount > 1 THEN 1 "+char(10)+
				 "ELSE 0"+char(10)+
			"END as IsLinked,"+char(10)+
	"cast(ISNULL(NA.OWNEDBY,0) as bit)	as IsOwner,"+char(10)+
	" NA.DATECEASED as DateCeased,"+char(10)+
	"(Select dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION)) as 'Phone',"+CHAR(10)+
	"(Select dbo.fn_FormatTelecom(F.TELECOMTYPE, F.ISD, F.AREACODE, F.TELECOMNUMBER, F.EXTENSION) ) as 'Fax' "+CHAR(10)+
	"From NAME N"+CHAR(10)+ 
	"join NAMEADDRESS NA	on (NA.NAMENO = N.NAMENO)"+CHAR(10)+ 
	"join TABLECODES AT	on (AT.TABLECODE = NA.ADDRESSTYPE)"+CHAR(10)+ 	
	"left join ADDRESS A 		on (A.ADDRESSCODE = NA.ADDRESSCODE)"+CHAR(10)+ 
	"left join COUNTRY C		on (C.COUNTRYCODE = A.COUNTRYCODE)"+CHAR(10)+ 
	"left Join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE"+CHAR(10)+ 
	" 	           	 	and S.STATE = A.STATE)"+CHAR(10)+
	"left join TABLECODES TS 	on (TS.TABLECODE = NA.ADDRESSSTATUS)"+CHAR(10)+
	"left join	[TELECOMMUNICATION] T on (T.TELECODE = A.TELEPHONE)"+CHAR(10)+
	"left join	[TELECOMMUNICATION] F on (F.TELECODE = A.FAX)"+CHAR(10)+

	-- AC - ADDRESSCODE count
	"left join (	Select	N1.ADDRESSCODE,"+char(10)+
						" COUNT(distinct N1.NAMENO) as UsedByNameCount"+char(10)+
						" from	NAMEADDRESS N1"+char(10)+
						" where	N1.ADDRESSCODE is not null"+char(10)+
						" group by N1.ADDRESSCODE"+char(10)+
						" ) AC on (AC.ADDRESSCODE = NA.ADDRESSCODE)"+char(10)+

	"where N.NAMENO = @pnNameKey"+CHAR(10)

	If (@pbExcludeMain = 1)
	begin
		Set @sSQLString = @sSQLString +
		"and	A.ADDRESSCODE NOT IN (N.STREETADDRESS,N.POSTALADDRESS)"+CHAR(10)
	end

	Set @sSQLString = @sSQLString +
	"order by	case 	when A.ADDRESSCODE = N.POSTALADDRESS then 0 "+CHAR(10)+
	"			else case when A.ADDRESSCODE = N.STREETADDRESS then 1"+CHAR(10)+
	"				  else 2 end"+CHAR(10)+
	"			end,"+CHAR(10)+
	"		3,"+CHAR(10)+
	"		A.ADDRESSCODE DESC"+CHAR(10)

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int',
					  @pnNameKey			= @pnNameKey

	Set @pnRowCount = @@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListAddresses to public
GO
