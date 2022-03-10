-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_CheckSecurityForName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_CheckSecurityForName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_CheckSecurityForName'
	drop procedure [dbo].[wa_CheckSecurityForName]
	print '**** Creating procedure dbo.wa_CheckSecurityForName...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_CheckSecurityForName]
	@pnNameNo	int

AS
-- PROCEDURE :	wa_CheckSecurityForName
-- VERSION :	3
-- DESCRIPTION:	Checks if an external user is allowed access to this Name. -1 is returned if access is denied.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03/08/2001	MF			Procedure created
-- 12/10/2001	MF			When checking security of Name also allow access to any name that is related to 
--					an associated name of the Names linked to the login id.
-- 04 Jun 2010	MF	18703	3	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be NULL

begin
	-- disable row counts
	set nocount on
	
	-- declare variables

	declare @ErrorCode	int

	-- Check that external users have access to see the details of the Name.

	if exists (	select * from USERS
			where USERID = user
			AND EXTERNALUSERFLAG > 1)
	and not exists(	select * from NAMEALIAS
			where	ALIAS=user
			and	ALIASTYPE='IU'
			and	NAMENO   = @pnNameNo
			and	COUNTRYCODE  is null
			and	PROPERTYTYPE is null)
							-- Allow access to any name associated with the names
							-- directly linked to the login names.
	and not exists( select * from NAMEALIAS NA
			join ASSOCIATEDNAME A	on (A.NAMENO=NA.NAMENO
						and(A.CEASEDDATE is null or A.CEASEDDATE>getdate())
						and A.RELATEDNAME=@pnNameNo)
			where	NA.ALIAS=user
			and	NA.ALIASTYPE='IU'
			and	NA.COUNTRYCODE  is null
			and	NA.PROPERTYTYPE is null)
	Begin
		set @ErrorCode=-1
	End
	Else Begin
		set @ErrorCode=0
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_CheckSecurityForName] to public
go
