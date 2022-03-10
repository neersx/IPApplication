-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListValidProperties
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListValidProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListValidProperties.'
	Drop procedure [dbo].[ipn_ListValidProperties]
	Print '**** Creating Stored Procedure dbo.ipn_ListValidProperties...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipn_ListValidProperties
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseAccessMode	int		= 1  /* 1=Select, 4=insert, 8=update */


-- PROCEDURE:	ipn_ListProperties
-- VERSION :	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 22-OCT-2002	JB	3	Standardised and implemented row level security

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

-- There are 2 times we return the whole list:
-- 	Either row security is not being used
-- 	Or there is a row with an unspecified property type with appropriate rights
If not exists 	( Select *
			from IDENTITYROWACCESS IRA
			join ROWACCESSDETAIL RAD on (RAD.ACCESSNAME = IRA.ACCESSNAME)
			where  RECORDTYPE = 'C'
		)

    or exists 	( Select * 
			from IDENTITYROWACCESS IRA
			join ROWACCESSDETAIL RAD on (IRA.ACCESSNAME = RAD.ACCESSNAME)
			where IRA.IDENTITYID =  @pnUserIdentityId
				and RAD.RECORDTYPE = 'C'
				and (RAD.SECURITYFLAG & @pnCaseAccessMode != 0)
				and RAD.PROPERTYTYPE is NULL
		)
	
	-- Give the whole list
	Select 	PROPERTYTYPE as PropertyTypeKey,
		PROPERTYNAME as PropertyTypeDescription,
		COUNTRYCODE as CountryKey,
		case COUNTRYCODE when 'ZZZ' then 1 else 0 end as IsDefaultCountry
		from VALIDPROPERTY	
		order by PROPERTYNAME


Else
	-- Give those that have the appropriate rights
	Select 	VP.PROPERTYTYPE as PropertyTypeKey,
		VP.PROPERTYNAME as PropertyTypeDescription,
		VP.COUNTRYCODE as CountryKey,
		case VP.COUNTRYCODE when 'ZZZ' then 1 else 0 end as IsDefaultCountry
		from VALIDPROPERTY VP
		join ROWACCESSDETAIL RAD on (RAD.PROPERTYTYPE = VP.PROPERTYTYPE)
		join IDENTITYROWACCESS IRA on (IRA.ACCESSNAME = RAD.ACCESSNAME)
		where IRA.IDENTITYID =  @pnUserIdentityId
		and RAD.RECORDTYPE = 'C'
		and (RAD.SECURITYFLAG & @pnCaseAccessMode != 0) 
		order by VP.PROPERTYNAME	

Set @nErrorCode = @@ERROR

RETURN @nErrorCode
GO

Grant execute on dbo.ipn_ListValidProperties to public
GO
