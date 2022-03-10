-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListLicensedUsers
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListLicensedUsers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListLicensedUsers.'
	Drop procedure [dbo].[ip_ListLicensedUsers]
End
Print '**** Creating Stored Procedure dbo.ip_ListLicensedUsers...'
Print ''
go

CREATE  PROCEDURE dbo.ip_ListLicensedUsers
(
	@pnUserIdentityId	int,
	@psCulture		nvarchar(10),
	@pnDisplay		int 	-- 0 shows the staff member. 1 shows non staff members.
)
AS
-- PROCEDURE:	ip_ListLicensedUsers
-- VERSION:		3
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- SCOPE:		Inpro to be used with licensing window.
-- DESCRIPTION:	Returns the all licensed users.
-- MODIFICATIONS:
-- Date			Who	Change	Version	Description
-- ----------------	-------	------	-------	----------------------------------------------- 
-- 19th april 2004	vlam	7660	1	procedure created.
-- 10th nov 2004	vlam	10095	2	dynamically return licensed users based on modules in the LICENSEMODULE table.
-- 7th	may 2010	vlam	18394	3	Update licensing software for new module structure.

-- NOTES:
-- when a new module is added must modify SQL to include the new module. add 'sum( case when LU.MODULEID = 3 then 1 else 0 end)'.
-- there currently 19 module.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)
Declare @sSQLWhere	nvarchar(4000)
Declare @sSQLGroupBy	nvarchar(4000)
Declare @sSQLOrderBy	nvarchar(4000)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
		-- sum and group by so rows collapse to form single row for each user.
	Select @sSQLString=isnull(nullif(@sSQLString+char(10),char(10)),'')+char(9)+char(9)+
			   'sum( case when LU.MODULEID = '+convert(varchar,L.MODULEID)+' then 1 else 0 end)'+CASE WHEN(L.MODULEID<L1.MODULEID) THEN ', ' END+'-- '+L.MODULENAME
	from LICENSEMODULE L
	cross join (select max(MODULEID) as MODULEID  from LICENSEMODULE) L1
	Order by L.MODULEID
	
	If @pnDisplay in (0, 1, 3)
		Set @sSQLString='Select case when N.FIRSTNAME is null then N.NAME else N.FIRSTNAME + SPACE( 1 ) + N.NAME end as STAFF,
			UI.NAMENO, U.USERID, UI.LOGINID, UI.IDENTITYID, E.ENDDATE, null, null,'+char(10)+
			@sSQLString+'
		from		USERIDENTITY UI
		left join	NAME N on ( UI.NAMENO = N.NAMENO )
		left join	EMPLOYEE E on ( UI.NAMENO = E.EMPLOYEENO )
		left join	USERS U on ( UI.IDENTITYID = U.IDENTITYID )
		left join	LICENSEDUSER LU on ( UI.IDENTITYID = LU.USERIDENTITYID )
		left join	LICENSEMODULE M on ( LU.MODULEID = M.MODULEID )'
	
	If @pnDisplay in (2, 4)
		Set @sSQLString='Select AA.ACCOUNTNAME+cast(AA.ACCOUNTID as nvarchar(254)),
			null, null, null, null, null, AA.ACCOUNTNAME, AA.ACCOUNTID,'+char(10)+
			@sSQLString+'
		from		ACCESSACCOUNT AA
		left join	LICENSEDACCOUNT LU on ( AA.ACCOUNTID = LU.ACCOUNTID )
		left join	LICENSEMODULE M on ( LU.MODULEID = M.MODULEID )'

End

If @nErrorCode = 0
Begin
	-- create the where clause.
	If @pnDisplay = 0
		Set @sSQLWhere = '
		where U.USERID is not null AND UI.IDENTITYID is not null'
	Else If @pnDisplay = 1
		Set @sSQLWhere = '
		where UI.IDENTITYID is not null and UI.ISEXTERNALUSER = 0'
	Else If @pnDisplay in (2 , 4)
		Set @sSQLWhere = '
		where AA.ISINTERNAL = 0'
	Else If @pnDisplay = 3
		Set @sSQLWhere = '
		where (U.USERID is not null AND UI.IDENTITYID is not null) OR (UI.IDENTITYID is not null and UI.ISEXTERNALUSER = 0)'
End

If @nErrorCode = 0
Begin
	-- create the group by clause.
	If @pnDisplay in (0, 1, 3)
		Set @sSQLGroupBy = '
		group by case when N.FIRSTNAME is null then N.NAME else N.FIRSTNAME + SPACE( 1 ) + N.NAME end, UI.NAMENO, U.USERID, UI.LOGINID, UI.IDENTITYID, E.ENDDATE'
	Else If @pnDisplay in (2, 4)
		Set @sSQLGroupBy = '
		group by AA.ACCOUNTNAME+cast(AA.ACCOUNTID as nvarchar(254)), AA.ACCOUNTNAME, AA.ACCOUNTID'
End

If @nErrorCode = 0
Begin
	-- create the group by clause.
	Set @sSQLOrderBy = '
	order by 1'
End

If @nErrorCode = 0
Begin
	-- execute statement.
	Set @sSQLString = @sSQLString + @sSQLWhere + @sSQLGroupBy + @sSQLOrderBy
	Exec @nErrorCode = sp_executesql @sSQLString
End
PRINT @sSQLString
Return @nErrorCode
GO

Grant execute on dbo.ip_ListLicensedUsers to public
GO
