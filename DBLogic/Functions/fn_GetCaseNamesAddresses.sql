-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCaseNamesAddresses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCaseNamesAddresses') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetCaseNamesAddresses.'
	drop function dbo.fn_GetCaseNamesAddresses
	print '**** Creating function dbo.fn_GetCaseNamesAddresses...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetCaseNamesAddresses
	(
		@pnCaseKey		int,
		@psNameTypeKey		nvarchar(3),
		@psSeparator		nvarchar(10), 
		@pdtToday		datetime
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetCaseNamesAddresses
-- VERSION :	4
-- DESCRIPTION:	This function accepts CaseKey and NameTypeKey and gets the formatted names and addresses
--		and concatenates them with the Separator between each name and address as the following:
--		<Name><CarriageReturn><Address><CarriageReturn><Name><CarriageReturn><Address>

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 02 May 2005	TM 	RFC2554	1	Function created
-- 02 May 2005	TM	RFC2554	2	Rename function fn_GetCopyToForCase to be fn_GetCaseNamesAddresses. 
-- 14 Apr 2011	MF	RFC10475 3	Change nvarchar(4000) to nvarchar(max)
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sFormattedNameAddressList	nvarchar(max)

	Select @sFormattedNameAddressList=nullif(@sFormattedNameAddressList+@psSeparator, @psSeparator)+
						dbo.fn_FormatNameUsingNameNo(N.NAMENO, coalesce(N.NAMESTYLE,NAT.NAMESTYLE,7101))+
						@psSeparator+
						dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
	From CASENAME CN
	Join NAME N on (N.NAMENO=CN.NAMENO)
	left join ADDRESS A		on (A.ADDRESSCODE=ISNULL(CN.ADDRESSCODE, N.POSTALADDRESS))
	left join COUNTRY CT		on (CT.COUNTRYCODE=A.COUNTRYCODE)
	left join STATE S		on (S.COUNTRYCODE=A.COUNTRYCODE
					and S.STATE=A.STATE)
	left join COUNTRY NAT		on (NAT.COUNTRYCODE=N.NATIONALITY)
	Where CN.CASEID  =@pnCaseKey
	and   CN.NAMETYPE=@psNameTypeKey
	and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
	order by CN.SEQUENCE	

	Return @sFormattedNameAddressList
End
go

grant execute on dbo.fn_GetCaseNamesAddresses to public
GO
