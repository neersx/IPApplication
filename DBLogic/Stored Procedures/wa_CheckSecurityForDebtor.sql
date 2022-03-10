-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_CheckSecurityForDebtor
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_CheckSecurityForDebtor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_CheckSecurityForDebtor'
	drop procedure [dbo].[wa_CheckSecurityForDebtor]
	print '**** Creating procedure dbo.wa_CheckSecurityForDebtor...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_CheckSecurityForDebtor]
	@pnDebtorNo	int
AS
-- PROCEDURE :	wa_CheckSecurityForDebtor
-- VERSION :	3
-- DESCRIPTION:	Checks if an external user is allowed access to this Debtor. -1 is returned if acces
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03/08/2001	MF			Procedure created
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
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
	and not exists(	select * from NAMEALIAS NA
			join SITECONTROL S on (S.CONTROLID='Client May View Debt')
			where	NA.ALIAS=user
			and	NA.ALIASTYPE='IU'
			and	NA.NAMENO   = @pnDebtorNo
			and	NA.COUNTRYCODE  is null
			and	NA.PROPERTYTYPE is null
			and	S.COLBOOLEAN=1)
	Begin
		set @ErrorCode=-1
	End
	Else Begin
		set @ErrorCode=0
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_CheckSecurityForDebtor] to public
go
