-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListCaseTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListCaseTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListCaseTypes.'
	Drop procedure [dbo].[ipn_ListCaseTypes]
	Print '**** Creating Stored Procedure dbo.ipn_ListCaseTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipn_ListCaseTypes
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseAccessMode	int		= 1  /* 1=Select, 4=insert, 8=update */

-- PROCEDURE:	ipn_ListCaseTypes
-- VERSION :	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 22-OCT-2002	JB	2	Standardised and implemented row level security

AS

SET NOCOUNT ON

Declare @nErrorCode int

-- There are 2 times we return the whole list:
-- 	Either row security is not being used
-- 	Or there is a row with an unspecified case type with appropriate rights
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
				and RAD.CASETYPE is NULL
		)
Begin	
	-- Give the whole list
	Select 	CASETYPE as CaseTypeKey, 
		CASETYPEDESC as CaseTypeDescription
		from CASETYPE
		order by CASETYPEDESC
	Set @nErrorCode = @@ERROR
End
Else
Begin
	-- Give those that have the appropriate rights
	Select 	CT.CASETYPE as CaseTypeKey, 
		CT.CASETYPEDESC as CaseTypeDescription
		from CASETYPE CT
		join ROWACCESSDETAIL RAD on (RAD.CASETYPE = CT.CASETYPE)
		join IDENTITYROWACCESS IRA on (IRA.ACCESSNAME = RAD.ACCESSNAME)
		where IRA.IDENTITYID =  @pnUserIdentityId
		and RAD.RECORDTYPE = 'C'
		and (@pnCaseAccessMode & RAD.SECURITYFLAG  != 0) 
		order by CT.CASETYPEDESC
	Set @nErrorCode = @@ERROR
End

RETURN @nErrorCode
GO

Grant execute on dbo.ipn_ListCaseTypes to public
GO
