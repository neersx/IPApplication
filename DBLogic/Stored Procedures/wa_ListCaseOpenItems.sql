-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCaseOpenItems
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCaseOpenItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCaseOpenItems'
	drop procedure [dbo].[wa_ListCaseOpenItems]
	print '**** Creating procedure dbo.wa_ListCaseOpenItems...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListCaseOpenItems]
			@pnCaseId	int

-- PROCEDURE :	wa_ListCaseOpenItems
-- VERSION :	2.2.0
-- DESCRIPTION:	List details of debtor open items for a specific Entity and Debtor.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 16/07/2001	MF	Procedure created
-- 03/08/2001	MF	Returns additional details to about the Open Item
-- 16/10/2001	MF	Return values formatted as currency.

as 
	-- set server options
	set NOCOUNT on
	set CONCAT_NULL_YIELDS_NULL off

	-- declare variables
	declare	@ErrorCode	int	-- declare variables
	declare @iStart		int	-- start record
	declare @iEnd		int	-- end record
	declare @iPageCount	int	-- total number of pages

	-- initialise variables
	set @ErrorCode=0

	if @ErrorCode=0
	Begin
		SELECT	O.ITEMENTITYNO,
			O.ITEMTRANSNO,
			O.OPENITEMNO,
			O.ITEMDATE,
			O.BILLPERCENTAGE,
			LOCALVALUE	=CONVERT(VARCHAR(20), CAST(O.LOCALVALUE     as MONEY), 1),
			LOCALBALANCE	=CONVERT(VARCHAR(20), CAST(O.LOCALBALANCE   as MONEY), 1),
			O.CURRENCY,
			O.EXCHRATE,
			FOREIGNVALUE	=CONVERT(VARCHAR(20), CAST(O.FOREIGNVALUE   as MONEY), 1),
			FOREIGNBALANCE	=CONVERT(VARCHAR(20), CAST(O.FOREIGNBALANCE as MONEY), 1),
			O.REFERENCETEXT,
			O.LONGREFTEXT,
			O.REGARDING,
			O.LONGREGARDING,
			O.SCOPE,
			NOOFDAYSOLD	=datediff(dd,O.ITEMDATE,getdate()), 
			DEBTORTYPEDESC	=DT.DESCRIPTION,
			RAISEDBYNAME	=convert(varchar(254),	CASE WHEN EMP.TITLE IS NOT NULL THEN EMP.TITLE + ' ' ELSE '' END  +
				 				CASE WHEN EMP.FIRSTNAME IS NOT NULL THEN EMP.FIRSTNAME  + ' ' ELSE '' END +
				 				EMP.NAME),
			NS.FORMATTEDNAME, 
			NS.FORMATTEDADDRESS, 
			NS.FORMATTEDATTENTION
		FROM OPENITEM O
		     join DEBTOR_ITEM_TYPE DT	on (DT.ITEM_TYPE_ID=O.ITEMTYPE)
		left join NAME EMP  		on (EMP.NAMENO=O.EMPLOYEENO)
		left join NAMEADDRESSSNAP NS	on (NS.NAMESNAPNO = O.NAMESNAPNO)  
		WHERE O.STATUS = 1  
		AND EXISTS
		(select * from WORKHISTORY WH
		 where WH.REFENTITYNO=O.ITEMENTITYNO
		 and   WH.REFTRANSNO =O.ITEMTRANSNO
 		 and   WH.CASEID=@pnCaseId)
		ORDER BY  O.OPENITEMNO

		Select @ErrorCode=@@Error
	End
go

grant execute on [dbo].[wa_ListCaseOpenItems]  to public
go
