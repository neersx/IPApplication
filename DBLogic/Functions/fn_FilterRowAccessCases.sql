-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterRowAccessCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterRowAccessCases') and xtype in ('IF','TF'))
begin
	print '**** Drop function dbo.fn_FilterRowAccessCases.'
	drop function dbo.fn_FilterRowAccessCases
end
print '**** Creating function dbo.fn_FilterRowAccessCases...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterRowAccessCases
			(@pnUserIdentityId	int	-- the specific user the Cases are required for
			)

RETURNS TABLE


-- FUNCTION :	fn_FilterRowAccessCases
-- VERSION :	1
-- DESCRIPTION:	This function is used to return all of the Cases that the
--		user identified by @pnUserIdentityId is allowed Select Access to.
--		The SECURITYFLAG column returned can also be used to determine the 
--		level of access the user may have.  These use bit flags so that more
--		than 1 flag can be combined into the single SECURITYFLAG value.
--		1 - Select
--		2 - Delete
--		4 - Insert
--		8 - Update
--		Examples:
--		SECURITYFLAG=15 is full access (1+2+4+8)
--		SECURITYFLAG=9  is Select and Update (1+8)

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 19 Dec 2013	MF		1	Function created

as RETURN
	(
	SELECT CaseAccess.CASEID,
	       CONVERT(INT, Substring(CaseAccess.SCORE, 4, 2)) AS SECURITYFLAG
	FROM   (SELECT CO.CASEID,
		       Max(CASE WHEN RAD.OFFICE       IS NULL THEN '0' ELSE '1' END
			 + CASE WHEN RAD.CASETYPE     IS NULL THEN '0' ELSE '1' END
			 + CASE WHEN RAD.PROPERTYTYPE IS NULL THEN '0' ELSE '1' END
			 + CASE WHEN RAD.SECURITYFLAG < 10    THEN '0' ELSE ''  END
			 + CONVERT(NVARCHAR, RAD.SECURITYFLAG)) AS SCORE
		FROM   IDENTITYROWACCESS UA
		-------------------------------------------
		-- Get all of the row access rules for the
		-- user.
		-------------------------------------------
		JOIN ROWACCESSDETAIL RAD ON (RAD.ACCESSNAME = UA.ACCESSNAME
					 AND RAD.RECORDTYPE = 'C' )
					      
		JOIN CASES CO ON (( CO.OFFICEID     = RAD.OFFICE       OR RAD.OFFICE       IS NULL )
			      AND ( CO.CASETYPE     = RAD.CASETYPE     OR RAD.CASETYPE     IS NULL )
			      AND ( CO.PROPERTYTYPE = RAD.PROPERTYTYPE OR RAD.PROPERTYTYPE IS NULL ) )
	                      
		WHERE  UA.IDENTITYID = @pnUserIdentityId
		GROUP  BY CO.CASEID
		UNION ALL
		-------------------------------------------
		-- Return all CASES with full access if the
		-- user has no row access rules for Cases.
		-------------------------------------------
		SELECT CO.CASEID, '   15' as SCORE
		FROM CASES CO
		where NOT EXISTS (select 1
				  from IDENTITYROWACCESS UA
				  join ROWACCESSDETAIL RAD on (RAD.ACCESSNAME=UA.ACCESSNAME
							   and RAD.RECORDTYPE='C')
				  where UA.IDENTITYID=@pnUserIdentityId)) AS CaseAccess
	        
	WHERE  Substring(CaseAccess.SCORE, 4, 2) IN ( '01', '03', '05', '07','09', '11', '13', '15' )
	)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_FilterRowAccessCases to public
GO

