-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_NamesRowSecurity
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_NamesRowSecurity') and xtype in ('IF','TF'))
begin
	print '**** Drop function dbo.fn_NamesRowSecurity.'
	drop function dbo.fn_NamesRowSecurity
end
print '**** Creating function dbo.fn_NamesRowSecurity...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_NamesRowSecurity
			(@pnUserIdentityId	int	-- Mandatory User Identity of the logged on user
			)

RETURNS TABLE


-- FUNCTION :	fn_NamesRowSecurity
-- VERSION :	1
-- DESCRIPTION:	This function encapsulates the row level security rules of a given user to return
--		the Names and the security access allowed.

-- EXAMPLE:	The following returns the NAMENO of Names that the user linked to IDENTITYID 26 is allowed access to
--		along with the level of access that is allowed.
--			Select *
--			from  dbo.fn_NamesRowSecurity(26)


-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 02 Apr 2018	MS	72435	1	Function created


as RETURN
	(
	With NameRowAccess(NAMENO, SECURITYFLAG)
	as (select  
		N.NAMENO as NAMENO,
		convert(int,
		SUBSTRING(
		(Select MAX(CASE WHEN RAD.OFFICE       is NULL THEN '0' ELSE '1' END+
			    CASE WHEN RAD.NAMETYPE     is NULL THEN '0' ELSE '1' END+
			    CASE WHEN RAD.SECURITYFLAG<10      THEN '0' ELSE ''  END+
			    convert(nvarchar,RAD.SECURITYFLAG))
		  from IDENTITYROWACCESS UA WITH (NOLOCK)
		  join ROWACCESSDETAIL RAD WITH (NOLOCK)
					on (RAD.ACCESSNAME  =UA.ACCESSNAME
					and RAD.RECORDTYPE  ='N'
					and(RAD.OFFICE      = TA.TABLECODE or RAD.OFFICE is NULL)
					and(RAD.NAMETYPE    in (select NTC.NAMETYPE from NAMETYPECLASSIFICATION NTC WHERE NTC.ALLOW = 1 and NTC.NAMENO = N.NAMENO) or RAD.NAMETYPE is NULL))
		  where UA.IDENTITYID=@pnUserIdentityId),3,2)) as SECURITYFLAG
	    from NAME N WITH (NOLOCK)
            left join TABLEATTRIBUTES TA on (TA.PARENTTABLE='NAME' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, N.NAMENO))
	    )
	Select	N.NAMENO,
		N.SECURITYFLAG,
		CASE WHEN(SECURITYFLAG&1=1) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as READALLOWED,
		CASE WHEN(SECURITYFLAG&2=2) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as DELETEALLOWED,
		CASE WHEN(SECURITYFLAG&4=4) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as INSERTALLOWED,
		CASE WHEN(SECURITYFLAG&8=8) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as UPDATEALLOWED
	from NameRowAccess N
	)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_NamesRowSecurity to public
GO

