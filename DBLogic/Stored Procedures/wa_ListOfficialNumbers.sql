-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListOfficialNumbers
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListOfficialNumbers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListOfficialNumbers'
	drop procedure [dbo].[wa_ListOfficialNumbers]
	print '**** Creating procedure dbo.wa_ListOfficialNumbers...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListOfficialNumbers]
	@pnCaseId	int
AS
-- PROCEDURE :	wa_ListOfficialNumbers
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of Official Numbers for a given Case passed as a parameter.
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
	
		select 	N.DESCRIPTION,
			O.OFFICIALNUMBER
		from 	OFFICIALNUMBERS O
		join	NUMBERTYPES N
			on N.NUMBERTYPE=O.NUMBERTYPE
			and 	(ISCURRENT=1 OR
				(ISCURRENT is null AND not exists 
				(select * from  OFFICIALNUMBERS O1 
				where O1.CASEID=O.CASEID 
				and O1.NUMBERTYPE=O.NUMBERTYPE and O1.ISCURRENT=1)))
		where	O.CASEID = @pnCaseId
	
		Set @ErrorCode=@@Error
	End

	return @ErrorCode
end
go

grant execute on [dbo].[wa_ListOfficialNumbers] to public
go
