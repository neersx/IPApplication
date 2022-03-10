-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetSourceCountry
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetSourceCountry') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetSourceCountry.'
	drop function dbo.fn_GetSourceCountry
	print '**** Creating function dbo.fn_GetSourceCountry...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetSourceCountry
	(
		@pnSourceName int = null, -- the name to Get the Country for.
		@pnCaseKey int = null		-- the case
	)
Returns nvarchar(3)

-- FUNCTION :	fn_GetSourceCountry
-- VERSION :	2
-- DESCRIPTION:	This function accepts a source name and a case and returns
--				the country applicable for tax purposes.

-- Date			Who	Number		Version	Description
-- ===========	===	======		=======	==========================================
-- 20 Jan 2010	AT 	RFC3605		1		Function created.
-- 19 Apr 2012	Dw 	RFC11940	2		Staff linked to multiple offices triggered SQL error.

AS
Begin

Declare @sReturnCountryCode nvarchar(3)

If (@pnSourceName is null and @pnCaseKey is not null)
Begin

-- Get the employee of the case
	SELECT @pnSourceName = NAMENO
	From CASENAME
	Where NAMETYPE = 'EMP'
	and CASEID = @pnCaseKey
	and SEQUENCE = (Select MIN(SEQUENCE) --@pnSourceName = NAMENO
					From CASENAME
					Where NAMETYPE = 'EMP'
					and CASEID = @pnCaseKey
					Group By CASEID)
End

if (@pnSourceName is not null)
Begin
	Select @sReturnCountryCode = COUNTRYCODE 
	From OFFICE
	Where OFFICEID = (Select min(TABLECODE) from TABLEATTRIBUTES
						Where GENERICKEY = CAST(@pnSourceName as nvarchar(14))
						and PARENTTABLE = 'NAME'
						and TABLETYPE = 44) -- Office
End

If @sReturnCountryCode is null
Begin
	Select @sReturnCountryCode = A.COUNTRYCODE 
	From ADDRESS A
	Join NAME N on (N.POSTALADDRESS = A.ADDRESSCODE)
	Where N.NAMENO = (select COLINTEGER from SITECONTROL where CONTROLID = 'HOMENAMENO')
End

If (@sReturnCountryCode is null)
Begin
	Set @sReturnCountryCode = 'ZZZ'
End

Return @sReturnCountryCode

End
go

grant execute on dbo.fn_GetSourceCountry to public
GO
