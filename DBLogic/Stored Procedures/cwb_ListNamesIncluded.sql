-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.cwb_ListNamesIncluded
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListNamesIncluded]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListNamesIncluded.'
	Drop procedure [dbo].[cwb_ListNamesIncluded]
End
Print '**** Creating Stored Procedure dbo.cwb_ListNamesIncluded...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListNamesIncluded
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	cwb_ListNamesIncluded
-- VERSION:	12
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates ClientNamesIncludedData dataset. Lists InPro client names that 
--		the user represents. 

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 25-Aug-2003  TM		1	Procedure created
-- 17-Sep-2003	TM		2	RFC333 Client Names Included Web Part. Join to another 
--					versions of the Country table for both 'OurContactName' 
--					and 'YourContactKey' instead of using NN.NAMESTYLE
-- 10-Oct-2003	MF	RFC519	3	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 13-Oct-2003	TM	RFC333	4 	Client Names Included Web Part. Make the @pnRowCount
--					the first parameter. 	
-- 28-Jan-2003	TM	RFC884	5	Use 'derived table' and 'the best fit' approaches to eliminate duplicated 
--					rows when retrieving OurContact.
-- 03-Feb-2004	TM	RFC884	6	Implement Mike's feedback. Implement 'select min(ASN1.RELATEDNAME)' subquery
--					instead of the 'derived table' and 'the best fit' approaches.  
-- 16 Sep 2004	JEK	RFC886	7	Implement translation.
-- 29-Sep-2004	TM	RFC1806	8	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.		
-- 15 May 2005	JEK	RFC2508	9	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 31 Oct 2006	SW	RFC4427	10	Suppress rows for OurContactKey with multiple OurContactRole
-- 11 Dec 2008	MF	17136	11	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 10 Nov 2015	KR	R53910	12	Adjust formatted names logic (DR-15543)     


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode 	= 0
Set 	@pnRowCount	= 0

-- Populating ClientNamesIncludedData dataset 
	
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select N.NAMENO 		as 'NameKey',"+char(10)+
	-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
	-- fn_FormatName, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, CASE WHEN N.NAMESTYLE  IS NOT NULL"+char(10)+
	"		    	  			     	THEN N.NAMESTYLE "+char(10)+
	"		    	  			     	ELSE CASE WHEN  N.NATIONALITY IS NOT NULL"+char(10)+
	"			               			       	  THEN  NN.NAMESTYLE"+char(10)+
	"			            			       	  ELSE  7101"+char(10)+
	"			      				     END"+char(10)+
	"		     				   END ) "+char(10)+
	"				as 'Name', "+char(10)+
	"N.NAMECODE			as 'NameCode',"+char(10)+
	-- Format address as for an envelope with any carriage returns (char(13)+char(10)) replaced with a comma 	
	"REPLACE"+char(10)+
        "(dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, SS.STATENAME, A.POSTCODE, NN1.POSTALNAME, NN1.POSTCODEFIRST, NN1.STATEABBREVIATED, NN1.POSTCODELITERAL, NN1.ADDRESSSTYLE),"+char(10)+
	"CHAR(13)+ char(10), ', ') 	as 'Address',"+char(10)+
	"N1.NAMENO			as 'YourContactKey',"+char(10)+
	"dbo.fn_FormatNameUsingNameNo(N1.NAMENO, CASE WHEN N1.NAMESTYLE  IS NOT NULL"+char(10)+
	"		    	  			        THEN N1.NAMESTYLE "+char(10)+
	"		    	  			        ELSE CASE WHEN  N1.NATIONALITY IS NOT NULL"+char(10)+
	"			               			          THEN  NN2.NAMESTYLE"+char(10)+
	"			            			          ELSE  7101"+char(10)+
	"			      				     END"+char(10)+
	"		     				   END )"+char(10)+
	"				as 'YourContactName', "+char(10)+
	"N2.NAMENO			as 'OurContactKey',"+char(10)+
	"dbo.fn_FormatNameUsingNameNo(N2.NAMENO, CASE WHEN N2.NAMESTYLE  IS NOT NULL"+char(10)+
	"		    	  			        THEN N2.NAMESTYLE "+char(10)+
	"		    	  			        ELSE CASE WHEN  N2.NATIONALITY IS NOT NULL"+char(10)+
	"			               			          THEN  NN3.NAMESTYLE"+char(10)+
	"			            			          ELSE  7101"+char(10)+
	"			      				     END"+char(10)+
	"		     				   END )"+char(10)+
	"				as 'OurContactName', "+char(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TBC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'OurContactRole',"+char(10)+
	dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTP',@sLookupCulture,@pbCalledFromCentura)
					+" as 'WelcomeMessage'"+char(10)+
	-- Client WorkBench should only be run by external users so the call to 
	-- dbo.fn_FilterUserNames is always passing 1 for the @pbIsExternalUser
     	"from dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN  "+char(10)+
	"     join NAME N		on (N.NAMENO=FN.NAMENO)"+char(10)+
	"left join COUNTRY NN	        on (NN.COUNTRYCODE = N.NATIONALITY)"+char(10)+
	-- If street address is not available, use postal address
 	"left join ADDRESS A 		on (A.ADDRESSCODE = CASE WHEN N.STREETADDRESS IS NOT NULL "+char(10)+
	"			  				 THEN N.STREETADDRESS "+char(10)+
	"			  				 ELSE N.POSTALADDRESS "+char(10)+
	"						    END)  "+char(10)+
	"left join COUNTRY NN1		on (NN1.COUNTRYCODE = A.COUNTRYCODE)"+char(10)+
	"left Join STATE SS		on (SS.COUNTRYCODE = A.COUNTRYCODE"+char(10)+
	" 	           	 	and SS.STATE = A.STATE)"+char(10)+
	-- For 'YourContactName' use Name.MainContact
	"left join NAME N1		on (N1.NAMENO  = N.MAINCONTACT)"+char(10)+
	"left join COUNTRY NN2	        on (NN2.COUNTRYCODE = N1.NATIONALITY)"+char(10)+
	-- For 'OurContactName' AssociatedName.RelatedName is used where AssociatedName.Relationship 
	-- = 'RES' (NamyType.Description = 'Staff Member') whith no PropertyType  		
	"left join ASSOCIATEDNAME ASN	on (ASN.NAMENO  = N.NAMENO"+char(10)+
	"				and ASN.RELATIONSHIP = 'RES'"+char(10)+
	"				and ASN.PROPERTYTYPE IS NULL"+char(10)+
	-- RFC4427 concat ASN.RELATEDNAME and ASN.SEQUENCE to get best fit for the join
	"				and Cast(ASN.RELATEDNAME as nvarchar(50))"+char(10)+
	"					+ '^' "+char(10)+
	"					+ Cast(ASN.SEQUENCE as nvarchar(50))"+char(10)+
	"					=(	select Cast(min(ASN1.RELATEDNAME) as nvarchar(50))"+char(10)+
	"							+ '^' "+char(10)+
	"							+ Cast(min(ASN1.SEQUENCE) as nvarchar(50))"+char(10)+
	"						from ASSOCIATEDNAME ASN1"+char(10)+
	"						where ASN1.NAMENO=ASN.NAMENO"+char(10)+
	"						and ASN1.RELATIONSHIP='RES'"+char(10)+
	"						and ASN1.PROPERTYTYPE is null))"+char(10)+
	"left join NAME N2 		on (N2.NAMENO = ASN.RELATEDNAME)"+char(10)+
	"left join COUNTRY NN3	        on (NN3.COUNTRYCODE = N2.NATIONALITY)"+char(10)+
	-- 'OurContactRole' is found on the TableCodes.Description where
	-- TableCodes.TableCode = AssociatedName.JobRole of 'OurContactName' 	
	"left join TABLECODES TBC	on (TBC.TABLECODE = ASN.JOBROLE)"+char(10)+ 
	"left join SITECONTROL SC	on (CONTROLID = 'Welcome Message - External')"+char(10)+
	"left join NAMETEXT NTP		on (NTP.NAMENO = N.NAMENO "+char(10)+
	"				and SC.COLCHARACTER = NTP.TEXTTYPE)"+char(10)+
	dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','NTP',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"order by 'Name', 'NameCode', 'NameKey'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
					  @pnUserIdentityId     =@pnUserIdentityId

	Set @pnRowCount=@@Rowcount

End


Return @nErrorCode
GO

Grant execute on dbo.cwb_ListNamesIncluded to public
GO


