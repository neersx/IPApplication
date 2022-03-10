-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListUserNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListUserNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListUserNames'
	drop procedure [dbo].[wa_ListUserNames]
	print '**** Creating procedure dbo.wa_ListUserNames...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListUserNames]
AS
-- PROCEDURE :	wa_ListUserNames
-- VERSION :	3
-- DESCRIPTON:	Returns a list of names against all cases that the currently connected user is associated with.
--				The list is additionally filtered by the name types allowable according to a site control

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	AF		1	Procedure created
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 04 Jun 2010	MF	18703	3	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be considered in the Update.

begin
	-- disable row counts
	set nocount on
	
	select 	distinct N.NAMENO,
			FULLNAME = N.NAME + 
				CASE WHEN (N.TITLE IS NOT NULL or N.FIRSTNAME IS NOT NULL) THEN ', ' ELSE '' END  +
				CASE WHEN N.TITLE IS NOT NULL THEN N.TITLE + ' ' ELSE '' END  +
				CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME ELSE '' END,
			CASECOUNT =
					(select count(distinct CN.CASEID)
					 from CASENAME CN
					 where CN.NAMENO=NA.NAMENO
					 and 0< patindex('%'+CN.NAMETYPE+'%',S.COLCHARACTER)),
			SelectionWeight=
					(select	max(CASE CN.NAMETYPE
							WHEN 'I' THEN 70
							WHEN 'R' THEN 60
							WHEN 'D' THEN 50
							WHEN 'Z' THEN 40
							WHEN 'A' THEN 30
							WHEN 'O' THEN 20
							WHEN '&' THEN 10
						    END)
					 from CASENAME CN
					 where CN.NAMENO=NA.NAMENO
					 and 0< patindex('%'+CN.NAMETYPE+'%',S.COLCHARACTER))
	from NAMEALIAS NA
	join NAME N 		on (N.NAMENO=NA.NAMENO)
	join SITECONTROL S 	on (S.CONTROLID='Client Name Types')
	where NA.ALIASTYPE='IU'
	and   NA.ALIAS=user
	and   NA.COUNTRYCODE  is null
	and   NA.PROPERTYTYPE is null
	order by 1

	-- turn back on record counts
	SET NOCOUNT OFF

	-- Return the number of records left
	RETURN 0
end
go 

grant execute on [dbo].[wa_ListUserNames] to public
go
