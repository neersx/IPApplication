-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDesignatedCountries
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetDesignatedCountries') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetDesignatedCountries.'
	drop function dbo.fn_GetDesignatedCountries
	print '**** Creating function dbo.fn_GetDesignatedCountries...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetDesignatedCountries
	(
		@pnCaseId		int,		-- the CaseId to be reported on
		@pbWithStatus		bit,		-- return the Status of the Designation when set to 1
		@psBetweenSeparator	nvarchar(10),	-- character string between Country and Status
		@psAfterSeparator	nvarchar(10)	-- character string between each Designation
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetDesignatedCountries
-- VERSION :	2
-- DESCRIPTION:	This function accepts a CaseId and gets the designated country list 
--		and concatenates them with the Separator between each country.  An option
--		also allows the Status of the designation to be returned.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 22 Jun 2005	MF 			Function created
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)

AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sDesignations	nvarchar(max)

	If @pbWithStatus=1
	Begin
		Select @sDesignations=nullif(@sDesignations+@psAfterSeparator, @psAfterSeparator)+CT.COUNTRY+@psBetweenSeparator+CF.FLAGNAME
		From RELATEDCASE RC
		Join CASES C			on (C.CASEID=RC.CASEID)
		Join COUNTRY CT			on (CT.COUNTRYCODE=RC.COUNTRYCODE)
		Left Join COUNTRYFLAGS CF	on (CF.COUNTRYCODE=C.COUNTRYCODE
						and CF.FLAGNUMBER=RC.CURRENTSTATUS)
		Where RC.CASEID  =@pnCaseId
		and   RC.RELATIONSHIP='DC1'
		order by CT.COUNTRY
	End
	Else Begin
		Select @sDesignations=nullif(@sDesignations+@psAfterSeparator, @psAfterSeparator)+CT.COUNTRY
		From RELATEDCASE RC
		Join COUNTRY CT			on (CT.COUNTRYCODE=RC.COUNTRYCODE)
		Where RC.CASEID  =@pnCaseId
		and   RC.RELATIONSHIP='DC1'
		order by CT.COUNTRY
	End

Return @sDesignations
End
go

grant execute on dbo.fn_GetDesignatedCountries to public
GO
