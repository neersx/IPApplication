-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cn_ChangeCountryCode
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cn_ChangeCountryCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cn_ChangeCountryCode.'
	Drop procedure [dbo].[cn_ChangeCountryCode]
End
Print '**** Creating Stored Procedure dbo.cn_ChangeCountryCode...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cn_ChangeCountryCode
(
	@psOldCountryCode	nvarchar(3),
	@psNewCountryCode	nvarchar(3)
)
as
-- PROCEDURE:	cn_ChangeCountryCode
-- VERSION:	10
-- SCOPE:	Inproma
-- DESCRIPTION:	Used to modify the CountryCode of a country from one value to another.
--		The CountryCode is used in multiply places and referential integrity
--		will stop it from just being updated in the base COUNTRY table.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21-AUG-2003  MF		1	Procedure created
-- 20-DEC-2003	MF		2	Accomodate table changes introduced in release 2.3 SP3
-- 06 Oct 2006	MF	13556	3	Add changes for new tables added up to release 3.4
-- 09 Oct 2006	MF	13556	4	Revisit
-- 18 Dec 2007	MF	15757	5	Include WIPTEMPLATE in changes
-- 22 Jan 2008	MF	15849	6	Table Attributes need to have the Country Code modified
--					even though this is not directly linked to the Country
--					table.
-- 03 May 2010	MF	18703	7	Include NAMEALIAS table.
-- 27 Aug 2010	MF	RFC9316	8	Include DATAVALIDATION table.
-- 01 Jun 2015  MS  R35907  9   Include DISCOUNT table
-- 16 Mar 2018  SW  R73713  10  Include Additional columns from COUNTRY table

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 	int
Declare @TranCountStart	int

Declare @sSQLString	nvarchar(4000)

Set 	@ErrorCode      = 0

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-- If the a the NewCountryCode already exists in the COUNTRY table
-- then set the @ErrorCode to terminate processing
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @ErrorCode=count(*)
	from COUNTRY
	where COUNTRYCODE=@psNewCountryCode"

	exec sp_executesql @sSQLString,
				N'@ErrorCode		int		OUTPUT,
				  @psNewCountryCode	nvarchar(3)',
				  @ErrorCode=@ErrorCode	OUTPUT,
				  @psNewCountryCode=@psNewCountryCode
End

-- Copy the details of the existing COUNTRY row with the NewCountryCode if it does not already exist.

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into COUNTRY(COUNTRYCODE,ALTERNATECODE,COUNTRY,INFORMALNAME,COUNTRYABBREV,COUNTRYADJECTIVE,RECORDTYPE,ISD,STATELITERAL,POSTCODELITERAL,POSTCODEFIRST,WORKDAYFLAG,DATECOMMENCED,DATECEASED,NOTES,STATEABBREVIATED,ALLMEMBERSFLAG,NAMESTYLE,ADDRESSSTYLE,DEFAULTTAXCODE,REQUIREEXEMPTTAXNO,DEFAULTCURRENCY,COUNTRY_TID,COUNTRYADJECTIVE_TID,INFORMALNAME_TID,NOTES_TID,POSTCODELITERAL_TID,STATELITERAL_TID, POSTCODESEARCHCODE, POSTCODEAUTOFLAG, POSTALNAME)
	select @psNewCountryCode,C.ALTERNATECODE,C.COUNTRY,C.INFORMALNAME,C.COUNTRYABBREV,C.COUNTRYADJECTIVE,C.RECORDTYPE,C.ISD,C.STATELITERAL,C.POSTCODELITERAL,C.POSTCODEFIRST,C.WORKDAYFLAG,C.DATECOMMENCED,C.DATECEASED,C.NOTES,C.STATEABBREVIATED,C.ALLMEMBERSFLAG,C.NAMESTYLE,C.ADDRESSSTYLE,C.DEFAULTTAXCODE,C.REQUIREEXEMPTTAXNO,C.DEFAULTCURRENCY,C.COUNTRY_TID,C.COUNTRYADJECTIVE_TID,C.INFORMALNAME_TID,C.NOTES_TID,C.POSTCODELITERAL_TID,C.STATELITERAL_TID,C.POSTCODESEARCHCODE, C.POSTCODEAUTOFLAG, C.POSTALNAME
	from COUNTRY C
	where C.COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into VALIDPROPERTY(COUNTRYCODE, PROPERTYTYPE, PROPERTYNAME, OFFSET, PROPERTYNAME_TID)
	select @psNewCountryCode, PROPERTYTYPE, PROPERTYNAME, OFFSET, PROPERTYNAME_TID
	from VALIDPROPERTY 
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into VALIDCATEGORY(COUNTRYCODE, PROPERTYTYPE, CASETYPE, CASECATEGORY, CASECATEGORYDESC, PROPERTYEVENTNO, CASECATEGORYDESC_TID)
	select @psNewCountryCode, PROPERTYTYPE, CASETYPE, CASECATEGORY, CASECATEGORYDESC, PROPERTYEVENTNO, CASECATEGORYDESC_TID
	from VALIDCATEGORY
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into STATE(COUNTRYCODE, STATE, STATENAME)
	select @psNewCountryCode, STATE, STATENAME
	from STATE 
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into POSTCODE(POSTCODE, CITY, COUNTRYCODE, STATE)
	select POSTCODE, CITY, @psNewCountryCode, STATE
	from POSTCODE 
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DATAVALIDATION
	set COUNTRYCODE=@psNewCountryCode
	from DATAVALIDATION V
	where V.COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDSUBTYPE
	set COUNTRYCODE=@psNewCountryCode
	from VALIDSUBTYPE V
	where V.COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDACTDATES
	set COUNTRYCODE=@psNewCountryCode
	from VALIDACTDATES V
	where V.COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FEESCALCALT
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDATENUMBERS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update MARGIN
	set DEBTORCOUNTRY=@psNewCountryCode
	where DEBTORCOUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update MARGIN
	set INSTRUCTORCOUNTRY=@psNewCountryCode
	where INSTRUCTORCOUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update MARGIN
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update MARGINPROFILERULE
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update NAMEALIAS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update OFFICE
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update GLACCOUNTMAPPING
	set COUNTRY=@psNewCountryCode
	where COUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DEBITNOTEIMAGE
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update EXCHRATEVARIATION
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update IMPORTCONTROL
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update AIRPORT
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASEPROFITCENTRE
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update ASSOCIATEDNAME
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CHARGERATES
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update B2BELEMENT
	set COUNTRY=@psNewCountryCode
	where COUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update BATCHTYPERULES
	set REJECTEDCOUNTRY=@psNewCountryCode
	where REJECTEDCOUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update BATCHTYPERULES
	set IMPORTEDCOUNTRY=@psNewCountryCode
	where IMPORTEDCOUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update BATCHTYPERULES
	set HEADERCOUNTRY=@psNewCountryCode
	where HEADERCOUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update SEARCHRESULTS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update LETTER
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update LETTERSUBSTITUTE
	set CASECOUNTRYCODE=@psNewCountryCode
	where CASECOUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDACTION
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDCHECKLISTS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDRELATIONSHIPS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDBASIS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDBASISEX
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDSTATUS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update POLICING
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DUEDATECALC
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COUNTRYFLAGS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COUNTRYTEXT
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FILESIN
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update SEARCHRESULTS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update RELATEDCASE
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update RECIPROCITY
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update RECORDALAFFECTEDCASE
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TAXHISTORY
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COUNTRYGROUP
	set TREATYCODE=@psNewCountryCode
	where TREATYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COUNTRYGROUP
	set MEMBERCOUNTRY=@psNewCountryCode
	where MEMBERCOUNTRY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update HOLIDAYS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TMCLASS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update RELATEDCASE
	set TREATYCODE=@psNewCountryCode
	where TREATYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASES
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIA
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIA
	set NEWCOUNTRYCODE=@psNewCountryCode
	where NEWCOUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update NAMEINSTRUCTIONS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update ADDRESS
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update NAME
	set NATIONALITY=@psNewCountryCode
	where NATIONALITY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update OPENITEMTAX
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TAXRATESCOUNTRY
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update WIPTEMPLATE
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TABLEATTRIBUTES
	set GENERICKEY=@psNewCountryCode
	where PARENTTABLE='COUNTRY'
	and GENERICKEY=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DISCOUNT
	set COUNTRYCODE=@psNewCountryCode
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete VALIDCATEGORY
	where  COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3)',
					  @psOldCountryCode
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete POSTCODE
	where  COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3)',
					  @psOldCountryCode
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete STATE
	where  COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3)',
					  @psOldCountryCode
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete VALIDPROPERTY
	where  COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3)',
					  @psOldCountryCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	delete from COUNTRY
	where COUNTRYCODE=@psOldCountryCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCountryCode	nvarchar(3),
					  @psNewCountryCode	nvarchar(3)',
					  @psOldCountryCode,
					  @psNewCountryCode
End

-- Commit the transaction if it has successfully completed

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else Begin
		ROLLBACK TRANSACTION
	End
End

Return @ErrorCode
GO

Grant execute on dbo.cn_ChangeCountryCode to public
GO
