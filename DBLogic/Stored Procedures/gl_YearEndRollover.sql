-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_YearEndRollover
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[gl_YearEndRollover]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.gl_YearEndRollover.'
	drop procedure dbo.gl_YearEndRollover
End
print '**** Creating procedure dbo.gl_YearEndRollover...'
print ''
go 

CREATE PROCEDURE dbo.gl_YearEndRollover
(
	@pnUserIdentityId	int		= null,	-- included for use by .NET
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura 	tinyint = 0,
	@pnDebugFlag		tinyint,
	@pnYear 		int, 
	@prnTransNo 		int output
)
AS
-- PROCEDURE :	gl_YearEndRollover
-- VERSION :	11
-- DESCRIPTION:	Year End Rollover
-- CALLED BY :	Centura
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIfICTIONS :
-- Date         Who  	Version  Mod	Details
-- ------------ ---- 	-------- ---	------------------------------------------- 
-- 20.5.03	MB			Created
-- 06.06.03 	MB			Added Set @nTotalProfit = @nTotalProfit *(-1)
-- 27.08.03	MB		SQA8803
-- 10.11.03	MB		SQA9184
-- 26.11.03	MB	5	SQA9478
-- 10.05.04	MB	6	SQA10015 Changed call to the gl_GetTotalProfit SP
-- 26.05.05	MB	7	SQA11278 Added code to update LEDGEJOURNALLINEBALANCE table
-- 22.09.05	KR	8	SQA11682 Added parameters for RecalculateAll and logic for the same
-- 16.11.05	vql	9	SQA9704	 When updating LEDGERJOURNAL/TRANSACTIONHEADER table insert @pnUserIdentityId.
-- 17.03.10	DL	10	SQA18535 Year end trans is not created if JUNE period has no transactions.
-- 04 Jun 2010	MF	11	SQA18703 NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.


Begin
Set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF
	
Declare	@nErrorCode		int
Declare @nPeriodFrom 		int
Declare @nPeriodTo 		int
Declare @nEntityNo 		int
Declare @nTotalProfit 		decimal(13,2)
Declare @nLocalAmount 		decimal(13,2)
Declare @dtLastDateOfPeriod 	datetime
Declare @nNameNo 		int
Declare @nTransNo 		int
Declare @sProfitCentreCode 	nvarchar(6)
Declare @nAccountId 		int
Declare @nSeqNo			int
Declare @nTempCount 		int
Declare @nDefaultAccountId 	int
Declare @sDefaultProfitCentre 	varchar(6)
Declare @nAmount		decimal (13,2)
Declare @nRecalculated		int
	
Set @nErrorCode=0
	
Select 
		@nPeriodFrom = MIN(PERIODID), 
		@nPeriodTo = MAX(PERIODID)
from PERIOD 
where CAST ( LEFT (PERIODID,4) AS Int)  = @pnYear

Set @nErrorCode=@@Error

If @nErrorCode = 0
	Select @dtLastDateOfPeriod = ENDDATE from PERIOD where PERIODID = @nPeriodTo
Set @nErrorCode=@@Error
If @nErrorCode = 0
	Select @nNameNo = NAMENO from NAMEALIAS where ALIAS = SYSTEM_USER and ALIASTYPE = 'U' and COUNTRYCODE is null and PROPERTYTYPE is null
Set @nErrorCode=@@Error
	
If @nErrorCode = 0
Begin
	Begin TRANSACTION

	Select @nTempCount = COUNT(1) from LEDGERJOURNALLINE WITH (HOLDLOCK TABLOCK) 

	Set @nErrorCode=@@Error
	If @nErrorCode = 0
	Begin
					
		Declare cMain CURSOR LOCAL FOR 
		Select 
			DISTINCT B.ACCTENTITYNO  
		from 
			TRANSACTIONHEADER A JOIN LEDGERJOURNALLINE B
			on 	A.ENTITYNO = B.ENTITYNO
			and	A.TRANSNO = B.TRANSNO
			JOIN LEDGERACCOUNT LA on B.ACCOUNTID = LA.ACCOUNTID
		where
	 		A.TRANPOSTPERIOD BETWEEN  @nPeriodFrom AND @nPeriodTo 
		and	LA.ACCOUNTTYPE IN (8104, 8105) 
		and	A.TRANSTATUS = 1 
	
		OPEN cMain
		FETCH NEXT FROM cMain INTO @nEntityNo
		While @@FETCH_STATUS = 0 AND @nErrorCode = 0
		Begin
			-- 8803 fetch default account
			Select 	
				@nDefaultAccountId = a.ACCOUNTID, 
				@sDefaultProfitCentre = a.PROFITCENTRECODE 
			From 	DEFAULTACCOUNT a, LEDGERACCOUNT b
			Where 	
				b.ACCOUNTID = a.ACCOUNTID 
			and b.ISACTIVE = 1
			and a.ENTITYNO = @nEntityNo 
			and a.CONTROLACCTYPEID = 8707
			and not exists (Select 1 from LEDGERACCOUNT d
			where b.ACCOUNTID = d.PARENTACCOUNTID )
			Set @nErrorCode=@@Error
			If @nDefaultAccountId is Null
				Set @nErrorCode = 1
			If @nErrorCode = 0
				Exec @nErrorCode = gl_GetTotalProfit 
							@prnTotalProfit 	= @nTotalProfit output,
							@prnRecalculated	= @nRecalculated output,
							@pnPeriodFrom		= @nPeriodFrom, 
							@pnPeriodTo 		= @nPeriodTo,
							@pnAcctEntity 		= @nEntityNo, 
							@pnUserIdentityId 	= @pnUserIdentityId, 
							@pbCalledFromCentura 	= 0, 
							@psCulture 		= @psCulture 
									
			If @nErrorCode = 0
			Begin
				Update  LASTINTERNALCODE Set INTERNALSEQUENCE = INTERNALSEQUENCE + 1 
				where TABLENAME = 'TRANSACTIONHEADER'
				Set @nErrorCode=@@Error
			End
			If @nErrorCode = 0
			Begin
				Select 
					@nTransNo = INTERNALSEQUENCE  
				from 
					LASTINTERNALCODE 
				where 
					TABLENAME = 'TRANSACTIONHEADER'
				Set @nErrorCode=@@Error
			End
			Set @nTotalProfit = @nTotalProfit *(-1)
			If @nErrorCode = 0
			Begin
				Insert into TRANSACTIONHEADER (
					ENTITYNO, TRANSNO,
					TRANSDATE, TRANSTYPE, 
					EMPLOYEENO,	USERID,
					ENTRYDATE, TRANSTATUS,
					TRANPOSTPERIOD, TRANPOSTDATE,
					SOURCE, IDENTITYID) 
				values (
					@nEntityNo, @nTransNo, 
					@dtLastDateOfPeriod, 812,
					@nNameNo, SYSTEM_USER, 
					CURRENT_TIMESTAMP ,1,
					@nPeriodTo, @dtLastDateOfPeriod,
					32, @pnUserIdentityId )
				Set @nErrorCode=@@Error
			End
			If @nErrorCode = 0
			Begin
				Insert into LEDGERJOURNAL (
					ENTITYNO, TRANSNO, USERID,STATUS, IDENTITYID) 
				values (@nEntityNo, @nTransNo, SYSTEM_USER, 1, @pnUserIdentityId)

				Set @nErrorCode=@@Error
			End
			If @nErrorCode = 0
			Begin
				Select @nSeqNo = (ISNULL ( Max (SEQNO),0) + 1 )
				from 
					LEDGERJOURNALLINE
				where 
					ENTITYNO = @nEntityNo  
				and	TRANSNO = @nTransNo

				Set @nErrorCode=@@Error
			End
			If @nErrorCode = 0
			Begin
				Insert into LEDGERJOURNALLINE (
					ENTITYNO, TRANSNO, SEQNO,
					ACCOUNTID, LOCALAMOUNT, 
					NOTES, ACCTENTITYNO,
					PROFITCENTRECODE ) 
				values (
					@nEntityNo, @nTransNo, @nSeqNo, 
					@nDefaultAccountId, @nTotalProfit, 
					'Retained Earnings', @nEntityNo,
					@sDefaultProfitCentre)
				Set @nErrorCode=@@Error
			End
----------------------------------------------------------------
-- Start LEDGERJOURNALLINEBALANCE processing
----------------------------------------------------------------

			If @nErrorCode = 0
			Begin
				set @nAmount = null
				
				Select @nAmount = LOCALAMOUNTBALANCE 
				from LEDGERJOURNALLINEBALANCE
				where 
					ACCTENTITYNO = @nEntityNo
				and	PROFITCENTRECODE  = @sDefaultProfitCentre
				and 	ACCOUNTID = @nDefaultAccountId 
				and 	TRANPOSTPERIOD = @nPeriodTo
				Set @nErrorCode=@@Error
			End
			If @nErrorCode = 0 and @nAmount is null
			Begin
				Insert into LEDGERJOURNALLINEBALANCE ( 
				ACCTENTITYNO, PROFITCENTRECODE, 
				ACCOUNTID, TRANPOSTPERIOD, 
				LOCALAMOUNTBALANCE)
				values
				(@nEntityNo, @sDefaultProfitCentre,
				@nDefaultAccountId, @nPeriodTo,
				@nTotalProfit )
				Set @nErrorCode=@@Error
			End
			Else If @nErrorCode = 0 and @nAmount is not null
			Begin
				Update LEDGERJOURNALLINEBALANCE 
				Set LOCALAMOUNTBALANCE = @nAmount + @nTotalProfit
				where 
					ACCTENTITYNO = @nEntityNo
				and	PROFITCENTRECODE  = @sDefaultProfitCentre
				and 	ACCOUNTID = @nDefaultAccountId 
				and 	TRANPOSTPERIOD = @nPeriodTo
				Set @nErrorCode=@@Error
			End
----------------------------------------------------------------
-- End LEDGERJOURNALLINEBALANCE processing
----------------------------------------------------------------
			If @nErrorCode = 0
			Begin
				Declare cClearing CURSOR LOCAL FOR 
				Select 
					SUM(B.LOCALAMOUNT),  B.PROFITCENTRECODE,  B.ACCOUNTID
				from 
					TRANSACTIONHEADER A JOIN LEDGERJOURNALLINE B
				on 	A.ENTITYNO = B.ENTITYNO AND 
						A.TRANSNO = B.TRANSNO
						JOIN LEDGERACCOUNT C 
				on B.ACCOUNTID = C.ACCOUNTID
				where
					A.TRANPOSTPERIOD BETWEEN  @nPeriodFrom AND @nPeriodTo AND 
					B.ACCTENTITYNO = @nEntityNo AND 
					A.TRANSTATUS = 1 AND 
					A.TRANSTYPE <> 812 AND 
					C.ACCOUNTTYPE IN (8104,8105)	
				group by
					B.PROFITCENTRECODE,  B.ACCOUNTID
				OPEN cClearing
				FETCH NEXT FROM cClearing INTO @nLocalAmount, @sProfitCentreCode,  @nAccountId
				While @@FETCH_STATUS = 0 AND @nErrorCode = 0
				Begin
					Set @nLocalAmount  =@nLocalAmount * (-1)
	
					Select @nSeqNo = (ISNULL ( Max (SEQNO),0) + 1 )
					from 
						LEDGERJOURNALLINE
					where 
						ENTITYNO = @nEntityNo  AND 
						TRANSNO = @nTransNo
					Set @nErrorCode=@@Error
					If @nErrorCode = 0
					Begin
						Insert into LEDGERJOURNALLINE (
							ENTITYNO, TRANSNO, SEQNO,
							PROFITCENTRECODE,
							ACCOUNTID, LOCALAMOUNT, NOTES, ACCTENTITYNO ) 
						values (
							@nEntityNo, @nTransNo, @nSeqNo, 
							@sProfitCentreCode,
							@nAccountId, @nLocalAmount, 
							'Closing Entries', @nEntityNo)
						Set @nErrorCode=@@Error
					End
----------------------------------------------------------------
-- Start LEDGERJOURNALLINEBALANCE processing
----------------------------------------------------------------

					If @nErrorCode = 0
					Begin
						-- SQA18515 initialise to ensure insert logic work.
						Set @nAmount = NULL
					
						Select @nAmount = LOCALAMOUNTBALANCE 
						from LEDGERJOURNALLINEBALANCE
						where 
							ACCTENTITYNO = @nEntityNo
						and	PROFITCENTRECODE  = @sProfitCentreCode
						and 	ACCOUNTID = @nAccountId 
						and 	TRANPOSTPERIOD = @nPeriodTo
						Set @nErrorCode=@@Error
					End
					If @nErrorCode = 0 and @nAmount is null
					Begin
						Insert into LEDGERJOURNALLINEBALANCE ( 
						ACCTENTITYNO, PROFITCENTRECODE, 
						ACCOUNTID, TRANPOSTPERIOD, 
						LOCALAMOUNTBALANCE)
						values
						(@nEntityNo, @sProfitCentreCode,
						@nAccountId, @nPeriodTo,
						@nLocalAmount )
						Set @nErrorCode=@@Error
					End
					Else If @nErrorCode = 0 and @nAmount is not null
					Begin
						Update LEDGERJOURNALLINEBALANCE  
						Set LOCALAMOUNTBALANCE = @nAmount + @nLocalAmount
						where 
							ACCTENTITYNO = @nEntityNo
						and	PROFITCENTRECODE  = @sProfitCentreCode 
						and 	ACCOUNTID = @nAccountId 
						and 	TRANPOSTPERIOD = @nPeriodTo
						Set @nErrorCode=@@Error
					End
----------------------------------------------------------------
-- End LEDGERJOURNALLINEBALANCE processing
----------------------------------------------------------------

					FETCH NEXT FROM cClearing INTO @nLocalAmount, @sProfitCentreCode,  @nAccountId
				End
				CLOSE cClearing
				DEALLOCATE cClearing
				FETCH NEXT FROM cMain INTO @nEntityNo
			End
		End
	End
If @nErrorCode = 0
Begin
	Update PERIOD Set 
		YEARENDROLLOVERFL = 1 , 
		LEDGERPERIODOPENFL = 0
	where CAST ( LEFT (PERIODID,4) AS Int) = @pnYear
	Set @nErrorCode=@@Error
End

If @nErrorCode = 0
	COMMIT TRANSACTION
Else
	ROLLBACK TRANSACTION
End	

CLOSE cMain
DEALLOCATE cMain
	If @pbCalledFromCentura = 1
		Select @nErrorCode, @nTransNo

End
Return @nErrorCode
go 

grant Execute on dbo.gl_YearEndRollover to public
go
