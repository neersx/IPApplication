-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetCopyToNames] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetCopyToNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetCopyToNames].'
	drop procedure dbo.[biw_GetCopyToNames]
end
print '**** Creating procedure dbo.[biw_GetCopyToNames]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.biw_GetCopyToNames
		@pnUserIdentityId	int,		-- Mandatory
		@psCulture		nvarchar(10) 	= null,
		@pbCalledFromCentura	bit		= 0,
		@pnEntityKey		int=null,	-- OpenItemEntity for saved copies to names
		@pnTransKey		int=null,	-- OpenItemTrans for saved copies to names
		@pnDebtorKey		int=null,
		@pnCaseKey		int=null,
		@pbUseRenewalDebtor	bit=0,
		@psResultTable		nvarchar(30) = null
as
-- PROCEDURE :	biw_GetCopyToNames
-- VERSION :	6
-- DESCRIPTION:	A procedure that returns Copy To names for:
--		an existing bill, else
--		a case, else
--		a debtor
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- -----------------------------------------------------------
-- 14-Oct-2010	AT	RFC8982		1	Procedure created.
-- 25-Oct-2010	AT	RFC7272		2	Fix return of Contact name key.
-- 12-Jul-2011	DW	RFC10942	3	Fixed problem where only one 'Copy To' Name returned.
-- 02-Nov-2011	AT	RFC9451		4	Make Entity Key parameter optional.
-- 02 May 2012	vql	RFC100635	5	Name Presentation not always used when displaying a name.
-- 02 Nov 2015	vql	R53910		6	Adjust formatted names logic (DR-15543).

set concat_null_yields_null off

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(max)
Declare		@sSQLInsert	nvarchar(1000)
Declare		@sAlertXML	nvarchar(2000)
Declare		@sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

if (@psResultTable is not null and @psResultTable != "")
Begin
	Set @sSQLInsert = "Insert into " + @psResultTable + "(DEBTORNO, RELATEDNAMENO, COPYTONAME,
			CONTACTNAMEKEY, CONTACTNAME, ADDRESSKEY, ADDRESS, ADDRESSCHANGEREASON)" + CHAR(10)
End


If exists(select * from OPENITEMCOPYTO WHERE ITEMENTITYNO = @pnEntityKey AND ITEMTRANSNO = @pnTransKey)
Begin
	Set @sSQLString = "Select
		OIC.ACCTDEBTORNO AS 'DebtorNo',
		N.NAMENO as 'RelatedNameNo',
		N.FORMATTEDNAME as 'CopyToName',
		N.ATTNNAMENO as 'ContactNameKey',
		N.FORMATTEDATTENTION as 'ContactName',
		N.ADDRESSCODE as 'AddressKey',
		N.FORMATTEDADDRESS as 'Address',
		N.REASONCODE as 'AddressChangeReason'
		FROM OPENITEMCOPYTO OIC
		JOIN NAMEADDRESSSNAP N ON (N.NAMESNAPNO = OIC.NAMESNAPNO)
		Where OIC.ITEMENTITYNO= @pnEntityKey
		and OIC.ITEMTRANSNO = @pnTransKey"

	Set @sSQLString = @sSQLInsert + @sSQLString 

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnEntityKey	int,
				  @pnTransKey	int',
				  @pnEntityKey=@pnEntityKey,
				  @pnTransKey=@pnTransKey
End
Else
Begin
	If (@ErrorCode = 0 and @pnCaseKey is null)
	Begin
		-- Return copies to names for the debtor
		Set @sSQLString = "Select
			AN.NAMENO as 'DebtorNo',
			AN.RELATEDNAME as 'RelatedNameNo',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CT.NAMESTYLE, 7101)) as 'CopyToName', 
			CN.NAMENO as 'ContactNameKey',
			dbo.fn_FormatNameUsingNameNo(CN.NAMENO, COALESCE(CN.NAMESTYLE, CTCN.NAMESTYLE, 7101)) as 'ContactName',
			N.POSTALADDRESS as 'AddressKey',
			dbo.fn_GetFormattedAddress(N.POSTALADDRESS, @psCulture, null, null, 0) as 'Address',
			null as 'AddressChangeReason'
			From ASSOCIATEDNAME AN
			join NAME N on (N.NAMENO = AN.RELATEDNAME)
			left join NAME CN on (CN.NAMENO = AN.CONTACT)
			left join COUNTRY CT on (CT.COUNTRY=N.NATIONALITY)
			left join COUNTRY CTCN on (CTCN.COUNTRY=CN.NATIONALITY)
			Where AN.NAMENO = @pnDebtorKey
			and AN.RELATIONSHIP = 'BI2'
			and (AN.CEASEDDATE is null
				OR AN.CEASEDDATE > GetDate())"

		Set @sSQLString = @sSQLInsert + @sSQLString 

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnDebtorKey	int,
					@psCulture nvarchar(10)',
					@pnDebtorKey=@pnDebtorKey,
					@psCulture = @psCulture
	End
	Else If (@ErrorCode = 0) and (@pnEntityKey is not null) and (@pnTransKey is not null)
	Begin
		-- RFC10942 return copies to names for all cases on Open Item
		Set @sSQLString = "SELECT
		null as 'DebtorNo',
		CN.NAMENO as 'RelatedNameNo',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'CopyToName',
		CTN.NAMENO as 'ContactNameKey',
		dbo.fn_FormatNameUsingNameNo(CTN.NAMENO, 7101) as 'ContactName',
		N.POSTALADDRESS as 'AddressKey',
		dbo.fn_GetFormattedAddress(N.POSTALADDRESS, @psCulture, null, null, 0) as 'Address',
		null as 'AddressChangeReason'
		FROM CASENAME CN
		join NAME N on (N.NAMENO = CN.NAMENO)
		left join NAME CTN on (CTN.NAMENO = CN.CORRESPONDNAME)
		join WORKHISTORY WH on (WH.CASEID = CN.CASEID)
		where (CN.EXPIRYDATE is null
			OR CN.EXPIRYDATE > GetDate())
		and WH.REFENTITYNO = @pnEntityKey
		and WH.REFTRANSNO = @pnTransKey"
	
		If (@pbUseRenewalDebtor = 0)
		Begin
			-- Debtor copies to:
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'CD'"
		End
		Else
		Begin
			-- RENEWAL DEBTOR copies to:
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'ZC'"
		End


		Set @sSQLString = @sSQLInsert + @sSQLString 

		exec @ErrorCode=sp_executesql @sSQLString, 
						N'@psCulture nvarchar(10),
						@pnEntityKey int,
						@pnTransKey int',
						@psCulture = @psCulture,
						@pnEntityKey = @pnEntityKey,
						@pnTransKey = @pnTransKey	
	End
	Else If (@ErrorCode = 0)
	Begin
		-- return copies to names for the case
		Set @sSQLString = "SELECT
		null as 'DebtorNo',
		CN.NAMENO as 'RelatedNameNo',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CT.NAMESTYLE, 7101)) as 'CopyToName',
		CTN.NAMENO as 'ContactNameKey',
		dbo.fn_FormatNameUsingNameNo(CTN.NAMENO, COALESCE(CTN.NAMESTYLE, CT2.NAMESTYLE, 7101)) as 'ContactName',
		N.POSTALADDRESS as 'AddressKey',
		dbo.fn_GetFormattedAddress(N.POSTALADDRESS, @psCulture, null, null, 0) as 'Address',
		null as 'AddressChangeReason'
		FROM CASENAME CN
		join NAME N on (N.NAMENO = CN.NAMENO)
		left join NAME CTN on (CTN.NAMENO = CN.CORRESPONDNAME)
		left join COUNTRY CT on (CT.COUNTRY=N.NATIONALITY)
		left join COUNTRY CT2 on (CT2.COUNTRY=CTN.NATIONALITY)		
		Where CN.CASEID = @pnCaseKey
		and (CN.EXPIRYDATE is null
			OR CN.EXPIRYDATE > GetDate())"
	
		If (@pbUseRenewalDebtor = 0)
		Begin
			-- Debtor copies to:
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'CD'"
		End
		Else
		Begin
			-- RENEWAL DEBTOR copies to:
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'ZC'"
		End


		Set @sSQLString = @sSQLInsert + @sSQLString 

		exec @ErrorCode=sp_executesql @sSQLString, 
						N'@pnCaseKey int,
						@psCulture nvarchar(10)', 
						@pnCaseKey = @pnCaseKey,
						@psCulture = @psCulture
		
	End



End


return @ErrorCode
go

grant execute on dbo.[biw_GetCopyToNames]  to public
go
