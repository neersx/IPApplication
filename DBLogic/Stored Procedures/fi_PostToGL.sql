-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_PostToGL
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.fi_PostToGL') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_PostToGL.'
	Drop procedure dbo.fi_PostToGL
End
Print '**** Creating Stored Procedure dbo.fi_PostToGL...'
Print ''

GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.fi_PostToGL
(
	@pnRowCount		int		output,
	@pbDebugFlag		tinyint		= 0,	
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnEntityNo		int 		= null,
	@pnTransNo		int 		= null,
	@pnDesignation		int 		= null
)
as
-- PROCEDURE:	fi_PostToGL
-- VERSION:	10	
-- SCOPE:	InPro
-- DESCRIPTION:	Called from Financial Interface to post journals to the 
--		General Ledger.		
-- COPYRIGHT	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 08/09/2003	CR	8197	1	Procedure created
-- 26/11/2003	CR	8197	1.1	Fixed inter-entity processing
-- 05/02/2004	CR	9507	1.2	Extended to accept the key attributes of a 
--					single GL Journal and to process just this 
--					one journal instead of all Draft Journals.
-- 11/02/2004	cr	9607	1.3	Modified to cater for Entity and Profit Centre
--					being derived.
-- 09/04/2004	CR	9873	1.4	Remove references to Post Period as this is
--					no longer relevant.
-- 09/09/2005	CR	11735	5	Added logic to extract the Foreign Amount and Foreign Currency details 
--					from User defined fields just before all other user defined fields 
--					are extracted into the Notes.
--					Logic to ensure the LEDGERJOURNALLINEBALANCE table is up-to-date 
--					will also be added
-- 16/11/2005	vql	9704	6	When updating LEDGERJOURNAL table insert @pnUserIdentityId.
-- 28/11/2005	ab		7	Add collate database_default syntax
-- 11 Mar 2008	MF	16063	8	Reduce the time that locks are held during the transaction by rearranging code
--					to Begin Transaction immediately before live tables are updated.
-- 17/03/2008	KR	15913	9	Reject journals if the post period doesn't belong to the current period.
-- 20 Oct 2015  MS      R53933  10      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

-- Statuses for GLJOURNAL rows
-- Number: TTC_GLSTATUS_REJECTED	= 6702
-- Number: TTC_GLSTATUS_DRAFT		= 6711
-- Number: TTC_GLSTATUS_POSTED		= 6721

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sOfficeCulture	nvarchar(10)

Declare
-- SQA9873 - no longer required	@nPeriodId 			int,
	@nCount				int,
	@nPosted			int,
	@nRejected			int,
	@nEntityNo			int,
	@nAcctEntityNo			int,
	@nTransNo			int,
	@nDesignation			int,
	@nSeqNo				int,
	@nLocalAmount 			decimal(11, 2),
	@nMainAccountId 		int,
	@nMainProfitCentre 		nvarchar(6),
	@nInterEntityAccountId 		int,
	@nInterEntityProfitCentre 	nvarchar(6),
	@sSQLString			nVarchar(4000),
	@sUserDefinedFields		nVarchar(254),
 	@nTranCountStart 		int,
	@nJournalId			int

Declare @tbGLJOURNAL table (
			JOURNALID		int 		IDENTITY(1,1),
			ENTITYNO 		int 		NOT NULL,
			TRANSNO 		int 		NOT NULL,
			DESIGNATION 		tinyint 	NOT NULL,
			JOURNALDATE 		datetime 	NULL,
			STATUS 			int 		NULL,
			USERID 			nvarchar (30)	collate database_default NULL,
			REJECTREASON 		varchar (254) 	collate database_default NULL,
			POSTPERIOD		int		NULL
			)

Declare @tbGLJOURNALLINE table (
			SEQUENCE 		int 		identity,
			ENTITYNO 		int 		NOT NULL,
			ACCTENTITYNO 		int 		NULL,
			TRANSNO 		int 		NOT NULL,
			DESIGNATION 		tinyint 	NOT NULL,
			SEQNO 			int 		NULL,
			LEDGERACCOUNTID 	int 		NULL,
			PROFITCENTRECODE 	nvarchar (6) 	collate database_default NULL,
			DESCRIPTION 		varchar (254) 	collate database_default NULL,
			LOCALAMOUNT 		decimal(11, 2) 	NULL,
			CURRENCY		nvarchar(3)	collate database_default NULL,
			FOREIGNAMOUNT 		decimal(11, 2) 	NULL,
			EXCHRATE		decimal(11,4)	NULL,
			MAINENTITYACCOUNTID 	int 		NULL,
			MAINENTITYPROFITCENTRE 	nvarchar (6) 	collate database_default NULL,
			INTERENTITYACCOUNTID 	int 		NULL,
			INTERENTITYPROFITCENTRE nvarchar (6) 	collate database_default NULL
			)

Set @nErrorCode = 0
Set @nCount = 0
Set @nPosted = 0
Set @nRejected = 0

-- SQA9507 post the individual journal as it is being created.	
If (@pnEntityNo IS NOT NULL) AND (@pnTransNo IS NOT NULL) AND (@pnDesignation IS NOT NULL)
Begin
	If @nErrorCode = 0
	Begin	
		Insert into @tbGLJOURNAL (ENTITYNO, TRANSNO, DESIGNATION, JOURNALDATE, STATUS, USERID, POSTPERIOD)
		select J.ENTITYNO, J.TRANSNO, J.DESIGNATION, J.JOURNALDATE, 6721, J.USERID, J.POSTPERIOD
		from GLJOURNAL J 
		where J.ENTITYNO = @pnEntityNo
		and J.TRANSNO = @pnTransNo 
		and J.DESIGNATION = @pnDesignation 
		and J.STATUS = 6711

		Select @nErrorCode = @@Error,
		       @nCount     = @@Rowcount
	End
	If @pbDebugFlag = 1
	Begin
		Print 'Post Single Journal'
		Select @pnEntityNo as ENTITYNO, @pnTransNo as TRANSNO, @pnDesignation as DESIGNATION
		Select * from @tbGLJOURNAL

		select J.ENTITYNO, J.TRANSNO, J.DESIGNATION, J.JOURNALDATE, 6721, J.USERID
		from GLJOURNAL J 
		where J.ENTITYNO = @pnEntityNo
		and J.TRANSNO = @pnTransNo 
		and J.DESIGNATION = @pnDesignation 
		and J.STATUS = 6711
	End
End
Else
-- post one or more journals in a batch
Begin
	

	If @nErrorCode = 0
	Begin	
		Insert into @tbGLJOURNAL (ENTITYNO, TRANSNO, DESIGNATION, JOURNALDATE, STATUS, USERID)
		select J.ENTITYNO, J.TRANSNO, J.DESIGNATION, J.JOURNALDATE, 6721, J.USERID
		from GLJOURNAL J 
		where J.DESIGNATION = 1 
		and J.STATUS = 6711

		Select @nErrorCode = @@Error,
		       @nCount     = @@Rowcount

		If @pbDebugFlag = 1
		Begin
			Print 'All Draft journals currently available'
			Select * from @tbGLJOURNAL
		End
	End
End

If  @nErrorCode = 0
and @pbDebugFlag = 1
Begin
	Print 'Number of Draft Journals currently available'
	Select @nCount
End

-- if there are journals to post add these to the table variables, validate and then post
-- journals to LEDGERJOURNAL and LEDGERJOURNALLINE
If @nCount > 0
and @nErrorCode=0
Begin
	If @nErrorCode = 0
	Begin
		Insert into @tbGLJOURNALLINE 	(ENTITYNO, ACCTENTITYNO, TRANSNO, DESIGNATION, SEQNO, 
						LEDGERACCOUNTID, PROFITCENTRECODE, DESCRIPTION, LOCALAMOUNT)
		select	JL.ENTITYNO, JL.ACCTENTITYNO, JL.TRANSNO, JL.DESIGNATION, JL.SEQNO, 
			JL.LEDGERACCOUNTID, JL.ACCTPROFITCENTRE, JL.DESCRIPTION, JL.LOCALAMOUNT
		from GLJOURNALLINE JL
		join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
					and JL.TRANSNO = J.TRANSNO 
					and JL.DESIGNATION = J.DESIGNATION)
		order by JL.ENTITYNO, JL.TRANSNO, JL.DESIGNATION

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-- Gather the necessary data for inter-entity processing - Main Entity
		Update @tbGLJOURNALLINE
		set	MAINENTITYACCOUNTID = IEA.ACCOUNTID,
			MAINENTITYPROFITCENTRE = IEA.PROFITCENTRECODE
		from @tbGLJOURNALLINE JL
		join @tbGLJOURNAL J 	on(JL.ENTITYNO = J.ENTITYNO 
					and JL.TRANSNO = J.TRANSNO 
					and JL.DESIGNATION = J.DESIGNATION)
		join INTERENTITYACCOUNT	IEA	on(IEA.MAINENTITYNO = JL.ENTITYNO 
						and IEA.INTERENTITYNO = JL.ACCTENTITYNO)
		where (JL.ENTITYNO <> JL.ACCTENTITYNO) 
		and J.STATUS = 6721

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-- Gather the necessary data for inter-entity processing - Inter Entity
		Update @tbGLJOURNALLINE
		set	INTERENTITYACCOUNTID = IEA.ACCOUNTID,
			INTERENTITYPROFITCENTRE = IEA.PROFITCENTRECODE
		from @tbGLJOURNALLINE JL
		join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
					and JL.TRANSNO = J.TRANSNO 
					and JL.DESIGNATION = J.DESIGNATION)
		join INTERENTITYACCOUNT	IEA	on(IEA.MAINENTITYNO = JL.ACCTENTITYNO
						and IEA.INTERENTITYNO = JL.ENTITYNO)
		where (JL.ENTITYNO <> JL.ACCTENTITYNO) 
		and J.STATUS = 6721

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Journals and lines to be posted'
			select * 
			from @tbGLJOURNALLINE JL
			join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
			where J.STATUS = 6721
			
			Print 'Journals that have been rejected'
			select * from @tbGLJOURNAL
			where STATUS = 6702		
		End
	End

	If @nErrorCode = 0
	Begin
		-- No General Ledger account details specified for the selected Financial Account. 
		Update @tbGLJOURNAL 
		set 	STATUS = 6702, 
			REJECTREASON = 'There are no General Ledger account details specified for one or more of the selected Financial Accounts.' 
		from @tbGLJOURNAL J
		join  @tbGLJOURNALLINE JL 	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
		where J.STATUS = 6721 
		and (JL.ACCTENTITYNO is null 
		or JL.LEDGERACCOUNTID is null 
		or JL.PROFITCENTRECODE is null) 

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-- Reject Journals that don't belong to the periods open for GL. 
		Update @tbGLJOURNAL 
		set 	STATUS = 6702, 
			REJECTREASON = 'Post period is closed for General Ledger.' 
		from @tbGLJOURNAL J
		join PERIOD P	on ( P.PERIODID = J.POSTPERIOD ) 
		where P.LEDGERPERIODOPENFL = 0

		Select @nErrorCode = @@Error
	End


	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Journals and lines to be posted'
			select * 
			from @tbGLJOURNALLINE JL
			join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
			where J.STATUS = 6721
			
			Print 'Journals that have been rejected'
			select * from @tbGLJOURNAL
			where STATUS = 6702		
		End
	End

	If @nErrorCode = 0
	Begin
		-- The General Ledger Account specified is not available for posting.
		-- e.g. Ledger account has since been made inactive or is a parent of another account
		Update @tbGLJOURNAL 
		set	STATUS = 6702, 
			REJECTREASON = 'One or more of the General Ledger Accounts specified for the selected Financial Accounts is not available for posting.' 
		from @tbGLJOURNAL J
		join  @tbGLJOURNALLINE JL	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
		join LEDGERACCOUNT LA1	on(LA1.ACCOUNTID = JL.LEDGERACCOUNTID)
		where	J.STATUS = 6721 
		and (LA1.ISACTIVE = 0 
		or LA1.ACCOUNTID IN 	(Select distinct LA3.PARENTACCOUNTID
					from LEDGERACCOUNT LA3 
					where LA3.PARENTACCOUNTID = LA1.ACCOUNTID) )

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Journals and lines to be posted'
			select * 
			from @tbGLJOURNALLINE JL
			join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
			where J.STATUS = 6721
			
			Print 'Journals that have been rejected'
			select * from @tbGLJOURNAL
			where STATUS = 6702		
		End
	End


	If @nErrorCode = 0
	Begin
		-- Necessary inter-entity accounts are not available.
		Update @tbGLJOURNAL 
		set 	STATUS = 6702, 
			REJECTREASON = 'This journal requires Inter-Entity processing however there relevant Inter-Entity account details have not been defined.' 
		from @tbGLJOURNAL J
		join @tbGLJOURNALLINE JL	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
		where J.STATUS = 6721 
		and JL.ENTITYNO <> JL.ACCTENTITYNO 
		and (JL.MAINENTITYACCOUNTID is null 
		or JL.INTERENTITYACCOUNTID is null)

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Journals and lines to be posted'
			select * 
			from @tbGLJOURNALLINE JL
			join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
			where J.STATUS = 6721
			
			Print 'Journals that have been rejected'
			select * from @tbGLJOURNAL
			where STATUS = 6702		
		End
	End

	-- *** handle inter-entity processing ***
	If @nErrorCode = 0
	Begin
		-- Main Entity
		Insert into @tbGLJOURNALLINE	(ENTITYNO, ACCTENTITYNO, TRANSNO, DESIGNATION, SEQNO, 
						LEDGERACCOUNTID, PROFITCENTRECODE, DESCRIPTION, LOCALAMOUNT)
		select 	JL.ENTITYNO, JL.ENTITYNO, JL.TRANSNO, JL.DESIGNATION, JL.SEQNO, 
			JL.MAINENTITYACCOUNTID, JL.MAINENTITYPROFITCENTRE, JL.DESCRIPTION, JL.LOCALAMOUNT
		from @tbGLJOURNALLINE JL
		where JL.MAINENTITYACCOUNTID is not null 
		and JL.INTERENTITYACCOUNTID is not null
		order by JL.ENTITYNO, JL.TRANSNO, JL.DESIGNATION
	
		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-- Inter Entity					
		Insert into @tbGLJOURNALLINE	(ENTITYNO, ACCTENTITYNO, TRANSNO, DESIGNATION, SEQNO,  
						LEDGERACCOUNTID, PROFITCENTRECODE, DESCRIPTION, LOCALAMOUNT)
		select	JL.ENTITYNO, JL.ACCTENTITYNO, JL.TRANSNO, JL.DESIGNATION, JL.SEQNO, 
			JL.INTERENTITYACCOUNTID, JL.INTERENTITYPROFITCENTRE, JL.DESCRIPTION, ( JL.LOCALAMOUNT * -1)
		from @tbGLJOURNALLINE JL
		where JL.MAINENTITYACCOUNTID is not null 
		and JL.INTERENTITYACCOUNTID is not null	
		order by JL.ENTITYNO, JL.TRANSNO, JL.DESIGNATION
	
		Select @nErrorCode = @@Error
	End


	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Inter Entity Processing complete'
			Print 'Journals and lines to be posted'
			select * 
			from @tbGLJOURNALLINE JL
			join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
			where J.STATUS = 6721
			
			Print 'Journals that have been rejected'
			select * from @tbGLJOURNAL
			where STATUS = 6702		
		End
	End

	-- Extract Foreign Currency details where available.
	-- Foreign Currency
	If @nErrorCode = 0
	Begin
	
		Update  @tbGLJOURNALLINE 
		set	CURRENCY = EXT.CONTENTS
		from  GLJOURNALLINEEXT EXT
		join @tbGLJOURNALLINE JL	on (JL.ENTITYNO = EXT.ENTITYNO
						and JL.TRANSNO = EXT.TRANSNO
						and JL.DESIGNATION = EXT.DESIGNATION
						and JL.SEQNO = EXT.SEQNO)
		join @tbGLJOURNAL J 		on(J.ENTITYNO = JL.ENTITYNO	
						and J.TRANSNO = JL.TRANSNO
						and J.DESIGNATION = JL.DESIGNATION)
		where J.STATUS = 6721
		and EXT.FIELDNO IN (SELECT DISTINCT FRC.FIELDNO
					FROM GLFIELDRULECONTENT FRC
					where FRC.CONTENTID in (14, 21, 25, 27, 36, 43))

		Select @nErrorCode = @@Error

	End


	-- Foreign Amount
	If @nErrorCode = 0
	Begin
		Update  @tbGLJOURNALLINE 
		set	FOREIGNAMOUNT = EXT.CONTENTS
		from  GLJOURNALLINEEXT EXT
		join @tbGLJOURNALLINE JL	on (JL.ENTITYNO = EXT.ENTITYNO
						and JL.TRANSNO = EXT.TRANSNO
						and JL.DESIGNATION = EXT.DESIGNATION
						and JL.SEQNO = EXT.SEQNO)
		join @tbGLJOURNAL J 		on(J.ENTITYNO = JL.ENTITYNO	
						and J.TRANSNO = JL.TRANSNO
						and J.DESIGNATION = JL.DESIGNATION)
		where J.STATUS = 6721
		and EXT.FIELDNO IN (SELECT DISTINCT FRC.FIELDNO
					FROM GLFIELDRULECONTENT FRC
					where FRC.CONTENTID in (15, 22, 26, 28, 37, 44))

		Select @nErrorCode = @@Error

	End


	-- Derive Exchange Rate
	If @nErrorCode = 0
	Begin
		Update  @tbGLJOURNALLINE 
		set	EXCHRATE = FOREIGNAMOUNT/LOCALAMOUNT
		from  @tbGLJOURNALLINE JL	
		join @tbGLJOURNAL J 		on(J.ENTITYNO = JL.ENTITYNO	
						and J.TRANSNO = JL.TRANSNO
						and J.DESIGNATION = JL.DESIGNATION)
		where J.STATUS = 6721
		and CURRENCY IS NOT NULL
		and FOREIGNAMOUNT <> 0
		and FOREIGNAMOUNT IS NOT NULL
		and LOCALAMOUNT <> 0
		and LOCALAMOUNT IS NOT NULL

		Select @nErrorCode = @@Error

	End


	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Foreign currency processing complete'
			Print 'Journals and lines to be posted'
			select * 
			from @tbGLJOURNALLINE JL
			join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
			where J.STATUS = 6721
			
			Print 'Journals that have been rejected'
			select * from @tbGLJOURNAL
			where STATUS = 6702		
		End
	End

	If @nErrorCode = 0
	Begin

		--Update @tbGLJOURNALLINE temporary table with the user defined fields.
		-- ensure Foreign Currency details are excluded from the notes.
		Update  @tbGLJOURNALLINE 
		set	DESCRIPTION = dbo.fn_UserDefinedFields(JL.ENTITYNO, JL.TRANSNO, JL.DESIGNATION, JL.SEQNO, JL.DESCRIPTION, 1)
		from @tbGLJOURNALLINE JL
		join @tbGLJOURNAL J 	on(J.ENTITYNO = JL.ENTITYNO	
					and J.TRANSNO = JL.TRANSNO
					and J.DESIGNATION = JL.DESIGNATION)
		where J.STATUS = 6721

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin	
		--- ****  SeqNo needs to be reset here so that within a journal the seqno of the lines are 1, 2, 3, 4 *** 
		Update @tbGLJOURNALLINE
		set SEQNO=isnull(
			  (select count(*)
			   from @tbGLJOURNALLINE GL1
			   where GL1.ENTITYNO=GL.ENTITYNO
			   and   GL1.TRANSNO=GL.TRANSNO
			   and   GL1.DESIGNATION=GL.DESIGNATION
			   and   GL1.SEQUENCE>GL.SEQUENCE),0)+1
		from @tbGLJOURNALLINE GL

		Select @nErrorCode = @@Error
	End

	-- Validate that the lines of the journals balance
	If @nErrorCode = 0
	Begin	
		Update @tbGLJOURNAL 
		set	STATUS = 6702, 
			REJECTREASON = 'The journal lines to be added to the general ledger do not balance.' 
		from @tbGLJOURNAL J
		join  @tbGLJOURNALLINE JL	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
		where J.STATUS = 6721 
		and J.TRANSNO IN 	(Select distinct(JL2.TRANSNO)
					from @tbGLJOURNALLINE JL2
					GROUP BY JL2.TRANSNO
					HAVING SUM(JL2.LOCALAMOUNT) <> 0)

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Journals and lines to be posted'
			select * 
			from @tbGLJOURNALLINE JL
			join @tbGLJOURNAL J	on(JL.ENTITYNO = J.ENTITYNO 
						and JL.TRANSNO = J.TRANSNO 
						and JL.DESIGNATION = J.DESIGNATION)
			where J.STATUS = 6721
			
			Print 'Journals that have been rejected'
			select * from @tbGLJOURNAL
			where STATUS = 6702		
		End
	End

	-----------------------------------------------
	-- Now apply the transaction(s) to the database
	-- within a database transaction.
	-----------------------------------------------
	If @nErrorCode = 0
	Begin

		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
	End

	If @nErrorCode = 0
	Begin	
		-- ADD VALID JOURNALS TO LEDGERJOURNAL
		Insert into LEDGERJOURNAL (ENTITYNO, TRANSNO, USERID, STATUS, IDENTITYID)	
		Select distinct ENTITYNO, TRANSNO, USERID, 1, @pnUserIdentityId
		from @tbGLJOURNAL
		where STATUS = 6721

		Select @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin	
		-- ADD VALID JOURNALLINES TO LEDGERJOURNALLINE
		Insert into LEDGERJOURNALLINE	(ENTITYNO, ACCTENTITYNO, TRANSNO, SEQNO, PROFITCENTRECODE, ACCOUNTID, 
						LOCALAMOUNT, CURRENCY, FOREIGNAMOUNT, EXCHRATE, NOTES)		
		Select 	JL.ENTITYNO, JL.ACCTENTITYNO, JL.TRANSNO, JL.SEQNO, JL.PROFITCENTRECODE, JL.LEDGERACCOUNTID,
			JL.LOCALAMOUNT, CURRENCY, FOREIGNAMOUNT, EXCHRATE, JL.DESCRIPTION   
		from @tbGLJOURNALLINE JL
		join @tbGLJOURNAL J 	on (JL.ENTITYNO = J.ENTITYNO 	
					and JL.TRANSNO = J.TRANSNO 
					and JL.DESIGNATION = J.DESIGNATION)
		where J.STATUS = 6721

		Select @nErrorCode = @@Error
	End

	-- Update the LEDGERJOURNALLINEBALANCE table for the journals created
	If @nErrorCode = 0
	Begin
		Set @nJournalId = NULL
		
		SELECT @nJournalId = min(JOURNALID)
		FROM @tbGLJOURNAL
	
		Select @nErrorCode = @@Error
	
	End
	

	While @nJournalId is not null and   @nErrorCode = 0
	Begin
	
		If @nErrorCode = 0
		Begin
	
			Select @nEntityNo=ENTITYNO, @nTransNo=TRANSNO
			from @tbGLJOURNAL
			where JOURNALID = @nJournalId
			and STATUS = 6721
	
			Select @nErrorCode = @@Error

			If @pbDebugFlag = 1
			Begin
				Print 'Journal being added'
				Select @nEntityNo as ENTITYNO, @nTransNo as TRANSNO
			End

		End
	

		If @nErrorCode = 0
		Begin
			exec @nErrorCode = dbo.gl_MaintLJLBalance @pnUserIdentityId, @psCulture, 0, @pbDebugFlag, @nEntityNo, @nTransNo
		End
	
		-- Now get the next row
		If @nErrorCode = 0
		Begin
			Select @nJournalId = min(JOURNALID)
			from @tbGLJOURNAL
			where JOURNALID > @nJournalId
	
			Select @nErrorCode = @@Error
	
		End
	End


	If @nErrorCode = 0
	Begin
		If @pbDebugFlag = 1
		Begin
			Print 'Posted Journals'
			select * from LEDGERJOURNAL LJ
			join @tbGLJOURNAL GJ	ON ( GJ.ENTITYNO = LJ.ENTITYNO 
						AND GJ.TRANSNO = LJ.TRANSNO)
			where GJ.STATUS = 6721
		End
	End

	If @nErrorCode = 0
	Begin	
		-- UPDATE GLJOURNAL WITH RESULTS from @tbGLJOURNAL
		Update GLJOURNAL
		set STATUS = J.STATUS, REJECTREASON = J.REJECTREASON
		from @tbGLJOURNAL J
		where J.ENTITYNO = GLJOURNAL.ENTITYNO 
		and J.TRANSNO = GLJOURNAL.TRANSNO 
		and J.DESIGNATION = GLJOURNAL.DESIGNATION
		
		Select	@nErrorCode = @@Error,
			@pnRowCount = @@RowCount
	End


	If @nErrorCode = 0
	Begin
		-- COUNT THE NUMBER OF REJECTED JOURNALS
		Set @nRejected = (select COUNT(*)
		from @tbGLJOURNAL
		where STATUS = 6702)


		-- COUNT THE NUMBER OF POSTED JOURNALS
		Set @nPosted = (select COUNT(*)
		from @tbGLJOURNAL
		where STATUS = 6721)

	End

	If @pbDebugFlag = 1
	Begin
		Print 'Result'
		Select @nCount as JOURNALCOUNT, @nPosted as JOURNALSPOSTED, @nRejected as JOURNALSREJECTED, @nErrorCode as ERRORCODE
	End
End


If @@TranCount > @nTranCountStart
Begin

	If @nErrorCode = 0
	Begin
			
		COMMIT TRANSACTION
		
		Select @nCount as JOURNALCOUNT, @nPosted as JOURNALSPOSTED, @nRejected as JOURNALSREJECTED, @nErrorCode as ERRORCODE

		If @pbDebugFlag = 1
		Begin
			Print 'Transaction committed'
		End
	End
	Else 
	Begin
		ROLLBACK TRANSACTION
		
		If @pbDebugFlag = 1
		Begin
			Print 'Transaction rolledback'
		End
	End

End

Return @nErrorCode
GO

Grant execute on dbo.fi_PostToGL to public
GO
