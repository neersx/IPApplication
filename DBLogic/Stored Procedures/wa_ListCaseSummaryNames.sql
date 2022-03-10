-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCaseSummaryNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCaseSummaryNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCaseSummaryNames'
	drop procedure [dbo].[wa_ListCaseSummaryNames]
	print '**** Creating procedure dbo.wa_ListCaseSummaryNames...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListCaseSummaryNames]
	@pnCaseId	int
AS
-- PROCEDURE :	wa_ListCaseSummaryNames
-- VERSION :	2
-- DESCRIPTION:	Returns the Names associated with the Case passed as a parameter that the
--				user is allowed to see.  The Names are displayed in a predefined order based
--				on their relationship with the Case.
--				If the currently logged in user is external then the list is filtered by
--				name types set in Site Control

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	AWF		1	Procedure created	
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	

	-- declare variables
	declare @ErrorCode	int

	-- disable row counts
	set nocount on

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId
	
	If @ErrorCode=0
	Begin
		select 	
		C.NAMENO, 
		C.NAMETYPE, 
		T.DESCRIPTION,
		FULLNAME = 
			CASE WHEN N.TITLE IS NOT NULL THEN N.TITLE + ' ' ELSE '' END  +
			CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME  + ' ' ELSE '' END +
			N.NAME,
		N.NAMECODE,
		REFERENCENO,
		N.MAINPHONE, 
		N.FAX, 
		BESTFIT =
		  CASE	C.NAMETYPE
			when 'EMP' then 10000
			when 'SIG' then 1000
			when '&' then 50
			when 'A' then 40
			when 'I' then 30
			when 'L' then 20
			when 'J' then 10
			when 'O' then 1
			ELSE 500
		  END,
		C.SEQUENCE,
		EXPIRYDATE
		from		CASENAME C
			     join	NAME N		on (N.NAMENO = C.NAMENO)
 		     join	NAMETYPE T	on (T.NAMETYPE = C.NAMETYPE)
		left join	NAME M		on (M.NAMENO = C.CORRESPONDNAME)
		where C.CASEID = @pnCaseId
		and (exists
			(Select * from SITECONTROL S
			 where S.CONTROLID='Client Name Types'
			 and   patindex('%' + T.NAMETYPE + '%', S.COLCHARACTER)>0)
		or  not exists
			(select * from USERS
			 where USERID = user
			 and   EXTERNALUSERFLAG > 1))
		ORDER BY BESTFIT, T.DESCRIPTION, C.SEQUENCE

		Select @ErrorCode=@@Error
	End

	return @ErrorCode
go 

grant execute on [dbo].[wa_ListCaseSummaryNames] to public
go
