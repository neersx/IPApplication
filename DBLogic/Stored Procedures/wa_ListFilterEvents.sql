-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListFilterEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListFilterEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListFilterEvents'
	drop procedure [dbo].[wa_ListFilterEvents]
	print '**** Creating procedure dbo.wa_ListFilterEvents...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListFilterEvents]
AS
-- PROCEDURE :	wa_ListFilterEvents
-- VERSION :	3
-- DESCRIPTION:	Returns a list of events that the currently connected user is allowed to see.
--		The Events are restricted by Importance Level and action if these have been elected via
--		a SiteControl.
--				
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	AF		1	Procedure created
-- 27/08/2001	MF		2	Restrict the events to only those associated with a particular Action
--					if the Action has been elected through a SiteControl
-- 15 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

	-- set server options
	set NOCOUNT on

	-- declare variables
	declare	@ErrorCode	int

	-- initialise variables
	set @ErrorCode=0

	select	distinct E.EVENTNO, E.EVENTDESCRIPTION
		from USERS U
		left join SITECONTROL S1	on (S1.CONTROLID='Client Importance')
		left join SITECONTROL S2	on (S2.CONTROLID='Events Displayed')
		left join SITECONTROL S3	on (S3.CONTROLID='Client PublishAction')
		left join SITECONTROL S4	on (S4.CONTROLID='Publish Action')
		left join CRITERIA C		on (C.PURPOSECODE='E'
						and C.RULEINUSE  =1
						and C.ACTION	 =	CASE WHEN(EXTERNALUSERFLAG > 1) THEN S3.COLCHARACTER 
													ELSE S4.COLCHARACTER
									END)
		left join EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
		     join EVENTS E		on (E.IMPORTANCELEVEL>=	CASE WHEN(EXTERNALUSERFLAG > 1)	THEN isnull(S1.COLINTEGER,0)
													ELSE isnull(S2.COLINTEGER,0)
									END)
	 	where	U.USERID      = user
		and    (E.EVENTNO = EC.EVENTNO OR EC.EVENTNO is null)
	ORDER BY	E.EVENTDESCRIPTION

	Select @ErrorCode=@@Error

return @ErrorCode
go

grant execute on [dbo].[wa_ListFilterEvents] to public
go
