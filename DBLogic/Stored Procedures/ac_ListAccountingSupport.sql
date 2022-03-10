-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ListAccountingSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListAccountingSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListAccountingSupport.'
	Drop procedure [dbo].[ac_ListAccountingSupport]
End
Print '**** Creating Stored Procedure dbo.ac_ListAccountingSupport...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ac_ListAccountingSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null		-- Is the comma separated list of requested tables (e.g.'Entity, BillingFrequency, StaffNameType')
)
AS
-- PROCEDURE:	ac_ListAccountingSupport
-- VERSION:	17
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of valid values for the requested tables. Allows the calling code to request multiple tables in one round trip.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Apr 2005	TM	RFC1896	1	Procedure created
-- 03 May 2005	TM	RFC2455	2	Implement a new support table called CurrencyDecimalPlaces.
-- 23 Jun 2005	TM	RFC2556	3	Add a new option PostToEntity. This is to call ac_ListEntities 
--					with the @pbForPosting parameter set to 1.
-- 29 Jun 2005	TM	RFC2556	4	When the Entity table is requested the @pbForPosting should not be passed. 
-- 17 Jan 2006	LP	RFC4671	5	Implement a new support table called Region.
--					Remove hard-coded TableTypeKey for BillingFrequency support table.
-- 08 Feb 2010	LP	RFC8289	6	Implement new Item Type support table.
-- 16 Feb 2010	MS	RFC8607	7	Added WIPCategory and WIPType
-- 08-Mar-2010	AT	RFC3605	8	Added Reason, Action, BillFormat
-- 31 Mar 2010  LP      RFC7276 9       Added BillFormatProfile.
-- 20 Apr 2010  KR	RFC8300 10	Added Billing Reason
-- 05-May-2010	LP	RFC9257	11	Added Post Periods.
-- 04-Jul-2010	AT	RFC7278	12	Added Bill Map Fields, WIPType, WIP Category
-- 09-Jul-2010	AT	RFC7278	13	Added Bill Map
-- 15-Jul-2010	AT	RFC7271	14	Added Address change reason.
-- 15 Apr 2013	DV	R13270	15	Increase the length of nvarchar to 11 when casting or declaring integer
-- 08-Jul-2013	SF	DR-135	16	Added Wip Reason
-- 22-Jul-2013	vql	DR-136	17	Added Transaction Type

-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@ErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		nvarchar(4000)

-- initialise variables
Set @nRow			= 1		

Set @nRowCount			= 0
Set @ErrorCode			= 0

While @nRow is not null
and @ErrorCode = 0
Begin
	-- Extruct the stored procedure's name from the @psTables comma separated string using function fn_Tokenise
	
	Select 	@sProc =
		CASE Parameter
			WHEN 'Entity'			THEN 'ac_ListEntities'
			WHEN 'BillingFrequency'		THEN 'ipw_ListTableCodes75'
			WHEN 'BillFormatProfile'	THEN 'biw_ListBillFormatProfiles'
			WHEN 'StaffNameType'		THEN 'ipw_ListNameTypes1'			
			WHEN 'CurrencyDecimalPlaces'	THEN 'ac_ListCurrency'
			WHEN 'PostToEntity'		THEN 'ac_ListEntities1'
			WHEN 'Region'			THEN 'ipw_ListTableCodes139'
			WHEN 'ItemType'			THEN 'bi_ListDebtorItemTypes'
			WHEN 'WIPCategory'		THEN 'acw_ListWIPCategory'
			WHEN 'WIPType'			THEN 'acw_ListWIPType'
			WHEN 'Reason'			THEN 'acw_ListReasons'
			WHEN 'BillingReason'		THEN 'acw_ListReasons1'
			WHEN 'WipReason'		THEN 'acw_ListReasons2'
			WHEN 'Action'			THEN 'acw_ListActions'
			WHEN 'BillFormat'		THEN 'biw_ListBillFormats'
			WHEN 'PostPeriods'		THEN 'ac_ListPostPeriods'
			WHEN 'BillMapField'		THEN 'ipw_ListTableCodes-500'
			WHEN 'BillMapProfile'		THEN 'biw_ListBillMapProfiles'
			WHEN 'AddressChangeReason'	THEN 'ipw_ListTableCodes-501'
			WHEN 'TransactionType'		THEN 'ac_ListTransactionTypes'
			
			ELSE NULL
		END	
	from fn_Tokenise (@psTables, NULL)
	where InsertOrder = @nRow
	
	Set @nRowCount = @@Rowcount
	

	-- If the dataset name is valid build the string to execute required stored procedure
	If (@nRowCount > 0)
	Begin
		If @sProc is not null
		Begin
			-- Build the parameters

			Set @sParams = '@pnUserIdentityId=' + CAST(@pnUserIdentityId as varchar(11)) 

			If @psCulture is not null
			Begin
				Set @sParams = @sParams + ", @psCulture='" + @psCulture + "'"
			End

			If @sProc like 'ipw_ListTableCodes%'  
			Begin
				-- For the ipw_ListTableCodes the @pnTableTypeKey is concatenated at the end of 
				-- the @sProc string so cut it off it and pass it to the stored procedure: 				

				Set @sParams = @sParams + ', @pnTableTypeKey = ' + substring(@sProc, 19, 5)

				-- Cut off the @pnTableTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTableCodes' 
				Set @sProc = substring(@sProc, 1, 18)  
			End

			If @sProc = 'ac_ListEntities1'  
			Begin
				Set @sParams = @sParams + ', @pbForPosting = 1'

				-- Cut off the '1' from the end of the @sProc to get the actual
				-- @sProc = 'ac_ListEntities' 
				Set @sProc = substring(@sProc, 1, 15)  
			End

			-- Pass the hard coded @pbIsUsedByStaff=1 parameter value to the ipw_ListNameTypes

			If @sProc = 'ipw_ListNameTypes1'  
			Begin
				Set @sParams = @sParams + ', @pbIsUsedByStaff = 1' 
				
				-- Cut off the '1' from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListNameTypes' 
				Set @sProc = substring(@sProc, 1, 17)  
			End
			
			If @sProc = 'acw_ListReasons1'  
			Begin
				Set @sParams = @sParams + ', @pnUsedByFlag = 1' 
				
				-- Cut off the '1' from the end of the @sProc to get the actual
				-- @sProc = 'acw_ListReasons' 
				Set @sProc = substring(@sProc, 1, 15)  
			End
			
			If @sProc = 'acw_ListReasons2'  
			Begin
				Set @sParams = @sParams + ', @pnUsedByFlag = 2' 
				
				-- Cut off the '2' from the end of the @sProc to get the actual
				-- @sProc = 'acw_ListReasons' 
				Set @sProc = substring(@sProc, 1, 15)  
			End

			If @sProc = 'ac_ListCurrency'
			Begin
				Set @sParams = @sParams + ', @ptXMLOutputRequests = 
								N''<OutputRequests>
								    <Column ID="CurrencyCode" PublishName="CurrencyCode" SortOrder="1" SortDirection="A"/>
								    <Column ID="DecimalPlaces" PublishName="DecimalPlaces"/>
								  </OutputRequests>'''
			End

			Exec (@sProc + ' ' + @sParams)	

			Set @ErrorCode=@@Error		
		End

		-- Increment @nRow by one so it points to the next dataset name
		
		Set @nRow = @nRow + 1
	End
	Else 
	Begin
		-- If the dataset name is not valid then exit the 'While' loop
	
		Set @nRow = null
	End

End

RETURN @ErrorCode
GO

Grant execute on dbo.ac_ListAccountingSupport to public
GO
