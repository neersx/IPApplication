-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListJournalEntries
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_ListJournalEntries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_ListJournalEntries.'
	Drop procedure [dbo].[gl_ListJournalEntries]
End
Print '**** Creating Stored Procedure dbo.gl_ListJournalEntries...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_ListJournalEntries
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null
)
AS
-- PROCEDURE:	gl_ListJournalEntries
-- VERSION:	4
-- SCOPE:	Inprotech
-- DESCRIPTION:	List details of Journal Entries that are selected
--		by the user. It is used by printing LedgerJournalEntry
--		report.
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 28-OCT-2003  SFOO	1	Procedure created
-- 12-NOV-2003	SFOO	1.1	Change ##JOURNALTOPRINT to local #JOURNALTOPRINT
-- 17-NOV-2003	SFOO	1.2	Added Entity Name additional to Acct Entity Name
-- 06-FEB-2004	SS	1.3	Modified to display results in a specific currency
-- 04 Feb 2005	MB	2	10822 Display Profit Centre Code and Description.
-- 07 Jun 2006	AT	3	Changed to display account code before description.
-- 02 Nov 2015	vql	4	R53910 - Adjust formatted names logic (DR-15543).

Begin

	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	Declare @nErrorCode	int
	Declare @sSql		nvarchar(2000)

	Set @nErrorCode = 0

	Set @sSql =	"Select TH.ENTITYNO,
				N.[NAME],
				TH.TRANSNO,
				LJ.REFERENCE,
				LJ.[DESCRIPTION],
				ATT.[DESCRIPTION],
				TH.TRANSDATE,
				LJ.REFTRANSNO,
				TH.ENTRYDATE,
				Convert(nvarchar(254), dbo.fn_FormatNameUsingNameNo(N2.NAMENO, 7101)),
				LJL.ACCTENTITYNO,
				N1.[NAME],
				'{' + PC.PROFITCENTRECODE + '} ' + PC.[DESCRIPTION],
				'{' + LA.ACCOUNTCODE + '} ' + LA.[DESCRIPTION],
				Case when LJL.LOCALAMOUNT > 0 then LJL.LOCALAMOUNT
				     else 0.00
				end,
				Case when LJL.LOCALAMOUNT < 0 then LJL.LOCALAMOUNT * (-1)
				     else 0.00
				end,
				Case when LJL.FOREIGNAMOUNT > 0 then LJL.FOREIGNAMOUNT
				     else 0.00
				end,
				Case when LJL.FOREIGNAMOUNT < 0 then LJL.FOREIGNAMOUNT * (-1)
				     else 0.00
				end,
				LJL.CURRENCY,
				LJL.NOTES	
			from #JOURNALTOPRINT JTP
			inner join TRANSACTIONHEADER TH on	(TH.ENTITYNO = JTP.ENTITYNO
								and TH.TRANSNO = JTP.TRANSNO)
			inner join LEDGERJOURNAL LJ on		(LJ.ENTITYNO = TH.ENTITYNO
								and LJ.TRANSNO = TH.TRANSNO)
			inner join LEDGERJOURNALLINE LJL on	(LJL.ENTITYNO = LJ.ENTITYNO
								and LJL.TRANSNO = LJ.TRANSNO)
			inner join ACCT_TRANS_TYPE ATT on	(ATT.TRANS_TYPE_ID = TH.TRANSTYPE)
			inner join PROFITCENTRE PC on		(PC.PROFITCENTRECODE = LJL.PROFITCENTRECODE)   
			inner join NAME N on			(N.NAMENO = TH.ENTITYNO)
			inner join NAME N1 on			(N1.NAMENO = LJL.ACCTENTITYNO)
			left outer join NAME N2 on		(N2.NAMENO = TH.EMPLOYEENO)
			inner join LEDGERACCOUNT LA on		(LA.ACCOUNTID = LJL.ACCOUNTID)
			order by TH.ENTITYNO, TH.TRANSNO, LJL.SEQNO"
		
	--print @sSql
	Exec @nErrorCode = sp_executesql @sSql

	Return @nErrorCode
End
GO

Grant execute on dbo.gl_ListJournalEntries to public
GO