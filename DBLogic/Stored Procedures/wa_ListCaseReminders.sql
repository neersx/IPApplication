-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCaseReminders
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCaseReminders]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCaseReminders'
	drop procedure [dbo].[wa_ListCaseReminders]
	print '**** Creating procedure dbo.wa_ListCaseReminders...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListCaseReminders]
	@pnCaseId	int
AS
-- PROCEDURE :	wa_ListCaseReminders
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of Reminders for a given Case passed as a parameter.
--				No rows are returned if the user is external (client)
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	MF	Procedure created
-- 03/08/2001	MF	Only display details if the user has the correct access rights

begin
	-- disable row counts
	set nocount on
	
	declare @ErrorCode	int

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId

	If @ErrorCode=0
	Begin
		select	ER.DUEDATE,
			MESSAGE = CASE	
					WHEN ER.LONGMESSAGE IS NULL THEN ER.SHORTMESSAGE
					WHEN ER.LONGMESSAGE LIKE '' THEN ER.SHORTMESSAGE	/* cater for crappy data */			
								    ELSE ER.LONGMESSAGE
			  END,
			 NAME =	CASE	
					WHEN N.FIRSTNAME IS NULL THEN N.NAME
					ELSE N.NAME + ', ' + N.FIRSTNAME
				END,
			ER.EMPLOYEENO
		from	EMPLOYEEREMINDER ER
		left join NAME N
		on	N.NAMENO 	= ER.EMPLOYEENO
		where	ER.CASEID	= @pnCaseId
		and	exists (select 0 from USERS
					where USERID = user
					AND (EXTERNALUSERFLAG < 2 or EXTERNALUSERFLAG is null ))
		ORDER BY DUEDATE ASC
	
		Set @ErrorCode=@@Error
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListCaseReminders] to public
go
