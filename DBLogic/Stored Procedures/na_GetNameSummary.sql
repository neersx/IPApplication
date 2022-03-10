-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_GetNameSummary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_GetNameSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_GetNameSummary.'
	drop procedure [dbo].[na_GetNameSummary]
	print '**** Creating Stored Procedure dbo.na_GetNameSummary...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[na_GetNameSummary]
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo		int
)

-- PROCEDURE :	na_GetNameDetails
-- VERSION :	10
-- DESCRIPTION:	Returns summary Name details for a given NameNo passed as a parameter.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18-JUN-2002	SF		Procedure created
-- 21-AUG-2002	SF		Use fn_FormatName instead of ipfn_FormatName
-- 11-OCT-2022	JB	4	Implemented IsCPAReportable
-- 15-OCT-2202	JB	5	Bug found with IsCPAReportable
-- 14-FEB-2003	SF	6	RFC9 - Add MainContact
-- 14-JUL-2003	TM	8	RFC214 - Incorrectly using WAM security in Names
-- 15 Apr 2013	DV	9	R13270 - Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	10	R53910 - Adjust formatted names logic (DR-15543).

AS

-- disable row counts
Set nocount on
Set concat_null_yields_null off

-- declare variables
Declare @nErrorCode int
Set     @nErrorCode = 0 	

Declare @bIsCPAReportable bit

If  @nErrorCode=0
Begin
	/* IsCPAReportable */
	if exists(Select * 
			from NAMEINSTRUCTIONS I
			join SITECONTROL S on S.COLINTEGER = I.INSTRUCTIONCODE 
				and S.CONTROLID = 'CPA Reportable Instr'
			where	I.NAMENO=@pnNameNo)
		Set @bIsCPAReportable = 1
	else
		Set @bIsCPAReportable = 0
End

if  @nErrorCode=0
Begin
	SELECT
	Cast(N.NAMENO as varchar(11))		as 'NameKey',	
	N.NAMECODE		as 'NameCode',
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'DisplayName',
	O.INCORPORATED		as 'Incorporated',
	C.COUNTRYADJECTIVE 	as 'NationalityDescription',
	N.DATECEASED		as 'DateCeased',
	@bIsCPAReportable	as 'IsCPAReportable',	
	N.REMARKS		as 'Remarks',
	dbo.fn_FormatNameUsingNameNo(MC.NAMENO, null) as 'MainContactDisplayName',
	N.MAINCONTACT		as 'MainContactNameKey'
	FROM NAME N
	left join COUNTRY C	on C.COUNTRYCODE = N.NATIONALITY
	left join ORGANISATION O on O.NAMENO = N.NAMENO
	left join INDIVIDUAL I 	on I.NAMENO = N.NAMENO
	left join NAME MC on (N.MAINCONTACT = MC.NAMENO)
	where	N.NAMENO=@pnNameNo

	select @nErrorCode=@@Error
End

RETURN @nErrorCode
go

Grant execute on dbo.na_GetNameSummary to public
go
