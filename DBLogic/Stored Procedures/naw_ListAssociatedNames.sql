-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAssociatedNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAssociatedNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAssociatedNames.'
	Drop procedure [dbo].[naw_ListAssociatedNames]
End
Print '**** Creating Stored Procedure dbo.naw_ListAssociatedNames...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListAssociatedNames
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListAssociatedNames
-- VERSION:	30
-- DESCRIPTION:	List all the associated names - both forward and reverse relationships

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2003	JEK	RFC621	1	Procedure created
-- 16 Dec 2003	TM	RFC621	2	Show the appropriate relationships based on the Name.UsedAs. Double check 
--					to ensure that the naw_ListAssociatedNames conforms to current coding standards.
-- 08 Jan 2004 	TM	RFC621	3	Replace 'Union' with 'Union All' as it is more efficient for mutually exclusive result sets.
-- 09 Mar 2004	TM	RFC868	4	Modify the logic extracting the 'Email' column to use new Name.MainEmail column. 
-- 06 Sep 2004 	TM	RFC1158	5	Add new columns: PositionCategory, DateCeased, UseForMailing, PropertyType, 
--					Action, Country, StreetAddress, PostalAddress. sp_executesql has been removed due to the
--					length of the result SQL statement (greater than 4000 characters).
-- 15 Sep 2004	JEK	RFC886	6	Implement translation.
-- 29 Sep 2004	TM	RFC1806	7	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.		
-- 29 Oct 2004	TM	RFC1158	8	Add a RoeKey column.
-- 15 May 2005	JEK	RFC2508	9	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 07 Jul 2005	TM	RFC2654	10	Restructure sql to be able to use sp_executesql instead of the exec.
-- 05 Dec 2007	PG	RFC3501	11	Return RelationshipCode and IsMainContact
-- 30 Jun 2008	AT	RFC5787	12	Added IsCRMOnly flag 
-- 10 Mar 2009	SF	RFC7682 13	Associated Name Grid is not displaying relationships as specified in Name Relationship setup
-- 12 Mar 2009	SF	RFC7744	14	SQL Overflow when culture is not english.
-- 23 Mar 2009	AT	RFC7244	15	Return CanConvertToClient flag and Formatted name.
-- 24 Mar 2009  ASH	RFC6312	16	Added new parameters of DEBATORSTATUS to show flags in Associated Name Grid.
-- 25 Mar 2009  ASH	RFC6312	17	Undo new parameters of DEBATORSTATUS to show flags in Associated Name Grid.(will implement later)
-- 26 Mar 2009	SF	RFC7474	18	Include reverse relationship when filtering Name Relationship restrictions
-- 2  Apr 2009	SF	RFC5757	19	SQL Overflow when culture is not english.
-- 3  Apr 2009	SF	RFC7682	20	Associated Names are incorrectly returned for Staff eventhough EMPLOYEE checkbox is unchecked
-- 2  Mar 2010	MS	RFC100147 21	Correct the Sorting by removing column 4 from Order by clause
-- 27 Jan 2011	PA	RFC10058 22	Correct the correlation prefix with STATE table
-- 15 Mar 2011  DV      RFC10307 23     Remove the check to restrict the display of Ceased Names
-- 14 Sep 2011  DV      RFC100600 24   	 Do not specify DateFormat inside Convert in comparison of CEASEDDATE
-- 30 Sep 2011	DV	RFC11366 25	Correct the correlation prefix with STATE table
-- 20 Jul 2012  ASH	R100733	26	Included Distict keyword in subquery for IsMainContact as the query is returning multiple same flag value.
-- 11 Apr 2013	DV	R13270	27	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 May 2014	DV	R31367	28	Remove the check to restrict the display of ceased names
-- 02 Nov 2015	vql	R53910	29	Adjust formatted names logic (DR-15543).
-- 25 Oct 2017	MF	72706	30	Use translation for COUNTRY.POSTALNAME (Courtesy of AK of Novagraaf)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode 	int
Declare @sSQLString	nvarchar(max)
Declare @sSQLString1	nvarchar(max)
Declare @dt datetime
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode 	= 0
Set @dt = getdate()  

If @nErrorCode = 0
Begin
	-- the following sql cannot support any more changes as 
	-- it will overflow 4000 characters when used with a different lookup culture
	-- You must test with ZH-CHS 
	Set @sSQLString = 
	"Select"+CHAR(10)+
	"CAST(AN.NAMENO as varchar(11))+'^'+"+CHAR(10)+
	"AN.RELATIONSHIP+'^'+"+CHAR(10)+
	"CAST(AN.RELATEDNAME as varchar(11))+'^'+"+CHAR(10)+
	"CAST(AN.SEQUENCE as varchar(5))"+CHAR(10)+
				"as RowKey,"+CHAR(10)+ /* 1 */
	"CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN AN.NAMENO ELSE AN.RELATEDNAME END as NameKey,"+CHAR(10)+ /* 2 */
	"CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN "+ dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',@sLookupCulture,0)+CHAR(10)+
	     "ELSE " +dbo.fn_SqlTranslatedColumn('NAMERELATION','REVERSEDESCR',null,'NR',@sLookupCulture,0) +" END as Relationship,"+CHAR(10)+ /* 3 */
	"CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN AN.RELATEDNAME ELSE AN.NAMENO END as AssociatedNameKey,"+CHAR(10)+ /* 4 */
	"CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  
	     "ELSE dbo.fn_FormatNameUsingNameNo(N2.NAMENO, null) END as AssociatedName,"+CHAR(10)+ /* 5 */
	"CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN N.NAMECODE ELSE N2.NAMECODE END as AssociatedNameCode,"+CHAR(10)+
	"C.NAMENO as ContactKey,"+CHAR(10)+
	"dbo.fn_FormatNameUsingNameNo(C.NAMENO, COALESCE(C.NAMESTYLE, CNN.NAMESTYLE, 7101))"+CHAR(10)+ 
				"as ContactName,"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('ASSOCIATEDNAME','POSITION',null,'AN',@sLookupCulture,0)+" as Position,"+CHAR(10)+
	"dbo.fn_FormatTelecom(T.TELECOMTYPE,T.ISD,T.AREACODE,T.TELECOMNUMBER,T.EXTENSION)"+CHAR(10)+
				"as Phone,"+CHAR(10)+
	"dbo.fn_FormatTelecom(F.TELECOMTYPE,F.ISD,F.AREACODE,F.TELECOMNUMBER,F.EXTENSION)"+CHAR(10)+
				"as Fax,"+CHAR(10)+
	"dbo.fn_FormatTelecom(M.TELECOMTYPE,M.ISD,M.AREACODE,M.TELECOMNUMBER,M.EXTENSION)"+CHAR(10)+ 
				"as Email,"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,0)+" as PositionCategory,"+CHAR(10)+
	"AN.CEASEDDATE as DateCeased,"+CHAR(10)+
	"AN.USEINMAILING as UseForMailing,"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,0)
				+ " as PropertyType,"+char(10)+
	dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,0)
				+ " as Action,"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNT',@sLookupCulture,0)
				+ " as Country,"+char(10)+
	"dbo.fn_FormatAddress(SA.STREET1,SA.STREET2,SA.CITY,SA.STATE,SS.STATENAME,SA.POSTCODE,"+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'CS',@sLookupCulture,0)+",CS.POSTCODEFIRST,CS.STATEABBREVIATED,CS.POSTCODELITERAL,CS.ADDRESSSTYLE)"+CHAR(10)+
				"as StreetAddress,"+CHAR(10)+
	"dbo.fn_FormatAddress(PA.STREET1,PA.STREET2,PA.CITY,PA.STATE,SP.STATENAME,PA.POSTCODE,"+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'CP',@sLookupCulture,0)+",CP.POSTCODEFIRST,CP.STATEABBREVIATED,CP.POSTCODELITERAL,CP.ADDRESSSTYLE)"+CHAR(10)+
				"as PostalAddress,"+CHAR(10)+
    	"AN.RELATIONSHIP as RelationshipCode,"+CHAR(10)+
	"cast(ISNULL((	select distinct 1 from NAME N1 where (N1.NAMENO=AN.NAMENO and N1.MAINCONTACT=AN.RELATEDNAME) or (N1.NAMENO=AN.RELATEDNAME and N1.MAINCONTACT=AN.NAMENO)),0) as bit) as IsMainContact,"+CHAR(10)+
	"isnull(AN.CRMONLY,0) as IsCRMOnly,"+CHAR(10)+
	-- If the name is a lead and the related name is not already a client, then the associated name is convertible to a client.
	"case when (isnull(LNTC.ALLOW,0) = 1 and isnull(PNTC.ALLOW,0) = 1"+CHAR(10)+
			"and AN.RELATIONSHIP IN ('LEA','EMP')"+char(10)+
			"and ((N.USEDASFLAG & 4 = 0 and N.NAMENO != "+ cast(@pnNameKey as nvarchar(11)) + ") OR "+char(10)+
			"	(N2.USEDASFLAG & 4 = 0 and N2.NAMENO != " + cast(@pnNameKey as nvarchar(11)) + ") OR " +char(10)+
			"	(N.NAMENO = N2.NAMENO and N.USEDASFLAG & 4 = 0)))"+char(10)+
		"then 1 else 0 end as CanConvertToClient,"+char(10)+
	"CASE AN.NAMENO"+char(10)+
	"WHEN " + cast(@pnNameKey as nvarchar(11)) + " THEN dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CS.NAMESTYLE, 7101))"+CHAR(10)+
	"ELSE dbo.fn_FormatNameUsingNameNo(N2.NAMENO, COALESCE(N2.NAMESTYLE, CS.NAMESTYLE, 7101))"+CHAR(10)+
	"END as FormattedName,"+CHAR(10)+
	"CASE WHEN (AN.CEASEDDATE is null or AN.CEASEDDATE >'"+convert(nvarchar(25),@dt,120)+"')"+CHAR(10)+
	        "then 0 else 1 end as IsCeased"+char(10)+
	"from ASSOCIATEDNAME AN"+CHAR(10)+
	"left join NAME N on (N.NAMENO=AN.RELATEDNAME)"+CHAR(10)+
	"left join COUNTRY NN on (NN.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+
	"left join NAME N2 on (N2.NAMENO=AN.NAMENO)"+CHAR(10)+
	"left join NAME NRT on (NRT.NAMENO=" + cast(@pnNameKey as nvarchar(11))+")"+CHAR(10)+
	"left join NAMERELATION NR on (NR.RELATIONSHIP=AN.RELATIONSHIP)"+CHAR(10)+
	"left join NAME C on (C.NAMENO=AN.CONTACT)"+CHAR(10)+
	"left join COUNTRY CNN on (CNN.COUNTRYCODE = C.NATIONALITY)"+CHAR(10)+
	"left join TELECOMMUNICATION T on (T.TELECODE=coalesce(AN.TELEPHONE,C.MAINPHONE,CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN N.MAINPHONE ELSE N2.MAINPHONE END))"+CHAR(10)+
	"left join TELECOMMUNICATION F on (F.TELECODE=coalesce(AN.FAX,C.FAX,CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN N.FAX ELSE N2.FAX END))"+CHAR(10)+
	"left join TELECOMMUNICATION M on (M.TELECODE=coalesce(C.MAINEMAIL,CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN N.MAINEMAIL ELSE N2.MAINEMAIL END))"+CHAR(10)+
	"left join TABLECODES TC on (TC.TABLECODE=AN.POSITIONCATEGORY)"+CHAR(10)+
	"left join PROPERTYTYPE PT on (PT.PROPERTYTYPE=AN.PROPERTYTYPE)"+CHAR(10)
	

	Set @sSQLString1 = 
	"left join ACTIONS A on (A.ACTION=AN.ACTION)"+CHAR(10)+
	"left join COUNTRY CNT on (CNT.COUNTRYCODE=AN.COUNTRYCODE)"+CHAR(10)+
	"left join ADDRESS SA on (SA.ADDRESSCODE=coalesce(AN.STREETADDRESS,CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN N.STREETADDRESS ELSE N2.STREETADDRESS END))"+CHAR(10)+
	"left join COUNTRY CS on (CS.COUNTRYCODE=SA.COUNTRYCODE)"+CHAR(10)+
	"left join STATE SS on (SS.COUNTRYCODE=SA.COUNTRYCODE and SS.STATE=SA.STATE)"+CHAR(10)+
	"left join ADDRESS PA on (PA.ADDRESSCODE=coalesce(AN.POSTALADDRESS,CASE WHEN (AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + ") THEN N.POSTALADDRESS ELSE N2.POSTALADDRESS END))"+CHAR(10)+
	"left join COUNTRY CP on (CP.COUNTRYCODE=PA.COUNTRYCODE)"+CHAR(10)+
	"left join STATE SP	on (SP.COUNTRYCODE = PA.COUNTRYCODE"+CHAR(10)+
	               		"and SP.STATE=PA.STATE)"+CHAR(10)+
	-- Is the name a Lead
	"left join NAMETYPECLASSIFICATION LNTC on (LNTC.NAMENO = " + cast(@pnNameKey as nvarchar(11)) +char(10)+
						"and LNTC.NAMETYPE='~LD' and LNTC.ALLOW=1)" +CHAR(10)+
	-- Is the name a Prospect
	"left join NAMETYPECLASSIFICATION PNTC on (PNTC.NAMENO = AN.NAMENO"+CHAR(10)+
						"and PNTC.NAMETYPE='~PR' and PNTC.ALLOW=1)"+CHAR(10)+
	"where 	(AN.NAMENO=" + cast(@pnNameKey as nvarchar(11)) + " OR AN.RELATEDNAME=" + cast(@pnNameKey as nvarchar(11)) + ")"+CHAR(10)+
	--"left join IPNAME IP on (IP.NAMENO = AN.NAMENO)"+CHAR(10)+ 
	--"left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)"+CHAR(10)+ 
	"and    ("+CHAR(10)+
	      		"(NRT.USEDASFLAG&0 = 0 and NRT.USEDASFLAG&1 <> 1 and NRT.USEDASFLAG&2 <> 2 and NR.USEDBYNAMETYPE IN (4, 5, 6, 7 ) )"+CHAR(10)+
			-- Show the Relationships available for an Individual (N.USEDAS&1 = 1)
	 "or		(NRT.USEDASFLAG&1 = 1 and NRT.USEDASFLAG&2 <> 2 and NR.USEDBYNAMETYPE IN (2, 3, 6, 7 ) )"+CHAR(10)+
	 		-- Show the Relationships available for Staff (N.USEDAS&2 = 2)
	 "or		(NRT.USEDASFLAG&2 = 2 and NR.USEDBYNAMETYPE IN (1, 3, 5, 7 ))"+CHAR(10)+
		")"+CHAR(10)+
	" order by 3,4,5"

	exec (@sSQLString + @sSQLString1)
	Set @nErrorCode = @@Error

-- we can't execute like this anymore because the SQL is too large.
-- 	exec @nErrorCode = sp_executesql @sSQLString,
-- 					N'@pnNameKey int,
-- 						@dt datetime',
-- 					  @pnNameKey = @pnNameKey,
-- 						@dt = @dt

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListAssociatedNames to public
GO
