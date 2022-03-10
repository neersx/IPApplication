-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_GetOurEmailAddress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_GetOurEmailAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_GetOurEmailAddress'
	drop procedure [dbo].[wa_GetOurEmailAddress]
end
print '**** Creating procedure dbo.wa_GetOurEmailAddress...'
print ''
go

CREATE PROCEDURE [dbo].[wa_GetOurEmailAddress]
			@pnCaseId	int = NULL,
			@pnNameNo	int = NULL
as
-- PROCEDURE :	wa_GetOurEmailAddress
-- VERSION :	3
-- DESCRIPTION:	Return the best email address associated with a particular Name or Case
--		depending upon the parameter passed.  If neither a Name or Case is passed
--		then return the Email address associated with the Home Name.
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28/07/2001	MF		1	Procedure created	
-- 07/10/2003	AB		2	Formatting for Clear Case auto generation
-- 15 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	

	-- disable row counts
	set nocount on
	
	If  @pnCaseId is not null
	Begin
		select	isnull(E.TELECOMNUMBER, E2.TELECOMNUMBER)
		from	CASENAME CN
		left join TELECOMMUNICATION E on (E.TELECODE=(	select min(E1.TELECODE)
								from NAMETELECOM NT
								join TELECOMMUNICATION E1 on (E1.TELECODE=NT.TELECODE
											  and E1.TELECOMTYPE=1903)
								where NT.NAMENO=CN.NAMENO))
		left join SITECONTROL S on (S.CONTROLID= 'HOMENAMENO')
		left join TELECOMMUNICATION E2 on (E2.TELECODE=(select min(E1.TELECODE)
								from NAMETELECOM NT
								join TELECOMMUNICATION E1 on (E1.TELECODE=NT.TELECODE
											  and E1.TELECOMTYPE=1903)
								where NT.NAMENO=S.COLINTEGER))
		where	CN.NAMETYPE='EMP'
		and	CN.EXPIRYDATE is null
		and 	CN.CASEID=@pnCaseId	End
	Else if @pnNameNo is not null
	Begin
		select	TOP 1 isnull(E.TELECOMNUMBER, E2.TELECOMNUMBER)
		from	ASSOCIATEDNAME AN
		left join TELECOMMUNICATION E on (E.TELECODE=(	select min(E1.TELECODE)
								from NAMETELECOM NT
								join TELECOMMUNICATION E1 on (E1.TELECODE=NT.TELECODE
											  and E1.TELECOMTYPE=1903)
								where NT.NAMENO=AN.RELATEDNAME))
		left join SITECONTROL S on (S.CONTROLID= 'HOMENAMENO')
		left join TELECOMMUNICATION E2 on (E2.TELECODE=(select min(E1.TELECODE)
								from NAMETELECOM NT
								join TELECOMMUNICATION E1 on (E1.TELECODE=NT.TELECODE
											  and E1.TELECOMTYPE=1903)
								where NT.NAMENO=S.COLINTEGER))
		where	AN.NAMENO=@pnNameNo
		and	AN.RELATIONSHIP= 'RES' 
		and	AN.CEASEDDATE is null
		order by AN.PROPERTYTYPE, AN.SEQUENCE
	End
	Else Begin
		select	E.TELECOMNUMBER
		from	SITECONTROL S
		left join TELECOMMUNICATION E on (E.TELECODE=(	select min(E1.TELECODE)
								from NAMETELECOM NT
								join TELECOMMUNICATION E1 on (E1.TELECODE=NT.TELECODE
											  and E1.TELECOMTYPE=1903)
								where NT.NAMENO=S.COLINTEGER))
		where S.CONTROLID= 'HOMENAMENO'
	End
go 

grant execute on [dbo].[wa_GetOurEmailAddress] to public
go
