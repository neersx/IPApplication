-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListWelcome
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListWelcome]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListWelcome.'
	Drop procedure [dbo].[ip_ListWelcome]
	Print '**** Creating Stored Procedure dbo.ip_ListWelcome...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ListWelcome
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ip_ListWelcome
-- VERSION:	7
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates WelcomeData dataset. Provides introductory information to the user.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 28-Aug-2003  TM	1			Procedure created
-- 07-Oct-2003	TM	2	RFC331	Welcome Web Part. Make @pnRowCount the first parameter. 
-- 09-Sep-2004	JEK	3	RFC1695 Implement translation.
-- 15 May 2005	JEK	4	RFC2508	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 11 Dec 2008	MF	5	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 06 May 2014	KR	6	R13955	Adjusted the case statement so it gets it from the logged in user first before looking at the firms.
-- 02 Nov 2015	vql	7	R53910	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode 	= 0
Set 	@pnRowCount	= 0

-- Populating WelcomeData dataset 
	
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select UID.NAMENO 		as 'UserIdentityKey',
	       -- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
	       -- fn_FormatNameUsingNameNo, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last). 
	       -- Pass @psTitle = null as the name should be shown without a title	   	
	       dbo.fn_FormatNameUsingNameNo(N.NAMENO, CASE WHEN N.NAMESTYLE  IS NOT NULL
				    	  			     	THEN N.NAMESTYLE 
				    	  			     	ELSE CASE WHEN  N.NATIONALITY IS NOT NULL
					               			       	  THEN  NN.NAMESTYLE
					            			       	  ELSE  7101
					      				     END
				     			    END ) 	
			  		as 'UserIdentityName', 	
	       N1.NAMENO  		as 'FirmNameKey',
	       N1.NAME	  		as 'FirmName',
	       -- If for external/internal user there is no corresponding internal/external
	       -- welcome message (NTP1.TEXT IS NULL) then use 'Welcome Message - Global'.
	       CASE WHEN DATALENGTH("+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTP1',@sLookupCulture,@pbCalledFromCentura)
					+")>0
					THEN "+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTP1',@sLookupCulture,@pbCalledFromCentura)+"
	       WHEN DATALENGTH("+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTP2',@sLookupCulture,@pbCalledFromCentura)
					+")>0
		    THEN "+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTP2',@sLookupCulture,@pbCalledFromCentura)+"
	            ELSE "+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NTP3',@sLookupCulture,@pbCalledFromCentura)+" 
	       END			as 'WelcomeMessage'        
	from   USERIDENTITY UID
	left join NAME N 		on (N.NAMENO = UID.NAMENO)
	left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY) 
	-- The 'FirmName' can be found on Name.Name where Name.NameNo = SiteControl.Colinteger
	-- for the SiteControl.ControlId = HomeNameNo 
	left join SITECONTROL SC 	on (SC.CONTROLID = 'HOMENAMENO')
	left join NAME N1 		on (N1.NAMENO = SC.COLINTEGER)
	-- Get the NameText.Text for an external/internal welcome message (NTP1.TEXT)  
	left join SITECONTROL SC1	on (SC1.CONTROLID = CASE WHEN UID.ISEXTERNALUSER = 1 THEN 'Welcome Message - External'
								 WHEN UID.ISEXTERNALUSER = 0 THEN 'Welcome Message - Internal'
							    END) 
	left join NAMETEXT NTP1		on (NTP1.NAMENO = N.NAMENO
					and NTP1.TEXTTYPE  = SC1.COLCHARACTER)
	left join NAMETEXT NTP2		on (NTP2.NAMENO = N1.NAMENO
					and NTP2.TEXTTYPE  = SC1.COLCHARACTER)
	"+dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','NTP1',@sLookupCulture,@pbCalledFromCentura)+"  
	-- Get the NameText.Text for a global welcome message (NTP2.TEXT)
	left join SITECONTROL SC2 	on (SC2.CONTROLID = 'Welcome Message - Global')      
	left join NAMETEXT NTP3		on (NTP3.NAMENO = N1.NAMENO
					and NTP3.TEXTTYPE = SC2.COLCHARACTER)
	"+dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','NTP2',@sLookupCulture,@pbCalledFromCentura)+"  
	where UID.IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
					  @pnUserIdentityId     =@pnUserIdentityId

	Set @pnRowCount=@@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ip_ListWelcome to public
GO


