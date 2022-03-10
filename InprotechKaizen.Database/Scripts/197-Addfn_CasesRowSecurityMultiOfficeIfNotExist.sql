if exists (select * from sysobjects where id = object_id('dbo.fn_CasesRowSecurityMultiOffice') and xtype in ('IF','TF'))
begin
	set noexec on;
end
go

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_CasesRowSecurity
-----------------------------------------------------------------------------------------------------------------------------
set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_CasesRowSecurityMultiOffice
			(@pnUserIdentityId	int	-- Mandatory User Identity of the logged on user
			)

RETURNS TABLE


-- FUNCTION :	fn_CasesRowSecurityMultiOffice
-- VERSION :	1
-- DESCRIPTION:	This function encapsulates the row level security rules of a given user to return
--		the Cases and the security access allowed.

-- EXAMPLE:	The following returns the CASEID of Cases that the user linked to IDENTITYID 26 is allowed access to
--		along with the level of access that is allowed.
--			Select *
--			from  dbo.fn_CasesRowSecurityMultiOffice(26)


-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 02 Jun 2016	MF	62341	1	Function created


as RETURN
	(
	With CaseRowAccess(CASEID, SECURITYFLAG)
	as (select  
		C.CASEID as CASEID,
		convert(int,
		SUBSTRING(
		(Select MAX(CASE WHEN RAD.OFFICE       is NULL THEN '0' ELSE '1' END+
			    CASE WHEN RAD.CASETYPE     is NULL THEN '0' ELSE '1' END+
			    CASE WHEN RAD.PROPERTYTYPE is NULL THEN '0' ELSE '1' END+
			    CASE WHEN RAD.SECURITYFLAG<10      THEN '0' ELSE ''  END+
			    convert(nvarchar,RAD.SECURITYFLAG))
		  from IDENTITYROWACCESS UA WITH (NOLOCK)
		  join ROWACCESSDETAIL RAD WITH (NOLOCK)
					on (RAD.ACCESSNAME  =UA.ACCESSNAME
					and RAD.RECORDTYPE  ='C'
					and(RAD.OFFICE in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='CASES' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, C.CASEID)) 
					                                    or RAD.OFFICE       is NULL)
					and(RAD.CASETYPE    =C.CASETYPE     or RAD.CASETYPE     is NULL)
					and(RAD.PROPERTYTYPE=C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL))
		  where UA.IDENTITYID=@pnUserIdentityId),4,2)) as SECURITYFLAG
	    from CASES C WITH (NOLOCK)
	    )
	Select	C.CASEID,
		C.SECURITYFLAG,
		CASE WHEN(SECURITYFLAG&1=1) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as READALLOWED,
		CASE WHEN(SECURITYFLAG&2=2) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as DELETEALLOWED,
		CASE WHEN(SECURITYFLAG&4=4) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as INSERTALLOWED,
		CASE WHEN(SECURITYFLAG&8=8) THEN Cast(1 as bit) ELSE Cast(0 as bit) END as UPDATEALLOWED
	from CaseRowAccess C
	)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_CasesRowSecurityMultiOffice to public
GO


set noexec off;