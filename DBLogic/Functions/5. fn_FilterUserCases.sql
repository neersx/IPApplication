-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserCases') and xtype in ('IF','TF'))
begin
	print '**** Drop function dbo.fn_FilterUserCases.'
	drop function dbo.fn_FilterUserCases
end
print '**** Creating function dbo.fn_FilterUserCases...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserCases
			(@pnUserIdentityId	int,	-- the specific user the Cases are required for
			 @pbIsExternalUser	bit,	-- external user flag if already known
			 @pnCaseKey 		int = null
			)

RETURNS TABLE


-- FUNCTION :	fn_FilterUserCases
-- VERSION :	12
-- DESCRIPTION:	This function is used to return all of the Cases that the
--		user identified by @pnUserIdentityId is linked to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 20 Aug 2003	MF		1	Function created
-- 04 Sep 2003	MF	RFC337	2	Extend the result set to include "client" information that is
--					associated with a Case.
-- 10-Oct-2003	MF	RFC519	3	Remove most of the "client" information as it causes performance problems.
-- 29-Oct-2003	TM	RFC495	4	Subset site control implementation with patindex. Enhance the 
--					existing logic that implements patindex to find the matching item 
--					in the following manner:
--					before change: "where patindex('%'+CN.NAMETYPE+'%',S.COLCHARACTER) > 0"
--					after change:  "where patindex('%'+','+CN.NAMETYPE+','+'%',',' + 
--								       replace(S.COLCHARACTER, ' ', '') + ',')>0
-- 18-Feb-2004	TM	RFC976	5        Pass the @bCalledFromCentura  = default parameter to the calling code for
--					the fn_FilterUserCaseTypes.
-- 04-Mar-2004	TM	RFC1032	6	Add new optional parameter @pnCaseKey and pass it in the “Where” clause 
--					of the subquery. 
-- 03-May-2004	TM	RFC1033	7	Modify the logic to look up the new AccountCaseContact table for the account 
--					that the current user is attached to. 
-- 23-Jul-2004	TM	RFC1610	8	Increase datasize of the CLIENTREFERENCENO column in the @tbCases table variable
--					from nvarchar(50) to nvarchar(80).
-- 18 Aug 2004	AB	8035	9	use collate database_default syntax on all temp tables.
-- 09 Sep 2004	JEK	RFC886	10	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 30 Nov 2005	JEK	RFC4755	11	Include primary key index.
-- 13 Dec 2006	MF	4002	12	Change into an In-Line Function to improve performance
-- 12 Dec 2008	AT	RFC7365	13	Added today's date param to pass into fn_FilterUserCaseTypes.

as RETURN
	(
	select	CN.CASEID		as CASEID, 
		CN.CORRESPONDNAME	as CLIENTCORRESPONDNAME, 
		CN.REFERENCENO		as CLIENTREFERENCENO, 
		N.MAINCONTACT		as CLIENTMAINCONTACT
	from USERIDENTITY U
	join ACCOUNTCASECONTACT AC	on(AC.ACCOUNTID = U.ACCOUNTID)
	join CASES C			on (C.CASEID = AC.ACCOUNTCASEID)	
	join dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,1,0,null) CT
					on (CT.CASETYPE = C.CASETYPE)
	join CASENAME CN		on (CN.CASEID = AC.CASEID
					and CN.NAMETYPE = AC.NAMETYPE
					and CN.NAMENO = AC.NAMENO
					and CN.SEQUENCE = AC.SEQUENCE)
	join NAME N			on (N.NAMENO=CN.NAMENO)
	where U.IDENTITYID = @pnUserIdentityId
	and  (AC.CASEID = @pnCaseKey or @pnCaseKey is null) 

	)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_FilterUserCases to public
GO

