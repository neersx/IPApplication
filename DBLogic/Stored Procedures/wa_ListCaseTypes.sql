-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCaseTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCaseTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCaseTypes'
	drop procedure [dbo].[wa_ListCaseTypes]
	print '**** Creating procedure dbo.wa_ListCaseTypes...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListCaseTypes]

-- PROCEDURE :	wa_ListCaseTypes
-- VERSION :	3
-- DESCRIPTION:	Returns a list of CaseTypes that the currently connected user is allowed to see.
--				If the currently connected user is external then the list is filtered by
--				a list of types set as a Site Control

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	MF		1	Procedure created
-- 25/09/2001	MF		2	Restrict the list of case types if the user has limited access
-- 15 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	

as 
	-- set server options
	set NOCOUNT on

	-- declare variables
	declare	@ErrorCode	int

	-- initialise variables
	set @ErrorCode=0

	-- When extracting the list of Cases available a number of things have to be considered.
	-- 1. If the user is External the maximum list of CaseTypes will be listed in a SiteControl;
	-- 2. If Row level security is implemented then the user may have a restricted view of Case Types.

	Select C.CASETYPE, C.CASETYPEDESC
	From USERROWACCESS UR
	     join ROWACCESSDETAIL R	on (R.ACCESSNAME=UR.ACCESSNAME)
	     join CASETYPE C		on (C.CASETYPE  =R.CASETYPE)
	left join SITECONTROL S		on (S.CONTROLID='Client Case Types')
	     join USERS U		on (U.USERID=UR.USERID)
	Where UR.USERID = user
	And R.RECORDTYPE = 'C'
	And R.SECURITYFLAG   IN ( 1,3,5,7,9,11,13,15 )
	And R.CASETYPE IS NOT NULL
	And ((U.EXTERNALUSERFLAG>1
	and   patindex('%' + C.CASETYPE + '%', S.COLCHARACTER)>0)
	 or  (U.EXTERNALUSERFLAG<2 or U.EXTERNALUSERFLAG is NULL))
	UNION
	Select C.CASETYPE, C.CASETYPEDESC
	From CASETYPE C
	left join SITECONTROL S		on (S.CONTROLID='Client Case Types')
	     join USERS U		on (U.USERID=user)
	where ((U.EXTERNALUSERFLAG>1
	and  	patindex('%' + C.CASETYPE + '%', S.COLCHARACTER)>0)
	or    	(U.EXTERNALUSERFLAG<2 or U.EXTERNALUSERFLAG is NULL))
	and (exists
	(select * from USERROWACCESS UR
	 join ROWACCESSDETAIL R	on (R.ACCESSNAME= UR.ACCESSNAME)
	 Where UR.USERID = U.USERID
	 And R.RECORDTYPE = 'C'
	 And R.SECURITYFLAG  IN ( 1,3,5,7,9,11,13,15 )
	 And R.CASETYPE  is  NULL)
	OR not exists
	(select * from USERROWACCESS UR
	 join ROWACCESSDETAIL R	on (R.ACCESSNAME= UR.ACCESSNAME)
	 Where R.RECORDTYPE = 'C'))
	and not exists
	(select * from USERROWACCESS UR
	 join ROWACCESSDETAIL R	on (R.ACCESSNAME= UR.ACCESSNAME)
	 Where UR.USERID = U.USERID
	 And R.RECORDTYPE = 'C'
	 And R.SECURITYFLAG  IN ( 0,2,4,6,8,10,12,14 )
	 And R.OFFICE       is NULL
	 And R.PROPERTYTYPE is NULL
	 And R.CASETYPE  =C.CASETYPE)
	Order by C.CASETYPEDESC

	Select @ErrorCode=@@Error

	return @ErrorCode
go

grant execute on [dbo].[wa_ListCaseTypes] to public
go
