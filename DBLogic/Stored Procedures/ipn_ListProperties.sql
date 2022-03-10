-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipn_ListProperties
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListProperties.'
	Drop procedure [dbo].[ipn_ListProperties]
	Print '**** Creating Stored Procedure dbo.ipn_ListProperties...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipn_ListProperties
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pnCaseAccessMode	int		= 1  /* 1=Select, 4=insert, 8=update */

-- PROCEDURE:	ipn_ListProperties
-- VERSION :	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 22-OCT-2002	JB	3	Implemented row level security

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
	Select 	P.PROPERTYTYPE as PropertyTypeKey,
		P.PROPERTYNAME as PropertyTypeDescription
		from 	PROPERTYTYPE P
		order by P.PROPERTYNAME	


Else
	-- Give those that have the appropriate rights
	Select 	P.PROPERTYTYPE as PropertyTypeKey,
		P.PROPERTYNAME as PropertyTypeDescription
		from PROPERTYTYPE P
		join ROWACCESSDETAIL RAD on (RAD.PROPERTYTYPE = P.PROPERTYTYPE)
		join IDENTITYROWACCESS IRA on (IRA.ACCESSNAME = RAD.ACCESSNAME)
		where IRA.IDENTITYID =  @pnUserIdentityId
		and RAD.RECORDTYPE = 'C'
		and (RAD.SECURITYFLAG & @pnCaseAccessMode != 0) 
		order by P.PROPERTYNAME	

Set @nErrorCode = @@ERROR

RETURN @nErrorCode
GO

Grant execute on dbo.ipn_ListProperties to public
GO
