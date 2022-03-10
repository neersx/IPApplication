-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ResetControlTotals									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ResetControlTotals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ResetControlTotals.'
	Drop procedure [dbo].[ac_ResetControlTotals]
End
Print '**** Creating Stored Procedure dbo.ac_ResetControlTotals...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ac_ResetControlTotals
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnLedger		int		= null,
	@pnPeriodId		int		= null,
	@pnEntityNo		int		= null,
	@pbDebug		bit		= 0
)
as
-- PROCEDURE:	ac_ResetControlTotals
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Corrects Control Totals so that they are in synch with corresponding accounting tables.
--		
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Feb 2012	Dw	SQA20367 1	SQL provided by JEK encorporated into stored procedure.
-- 14 Nov 2012	CR	SQA20367 2	Modified to cater for All ledgers and multiple periods
-- 02 Jan 2013	CR	SQA20367 3	Modified to exclude Equalise (Category = 9) movements from
--					All Ledgers except WIP
-- 12 Feb 2013	CR	RFC13191 4	Modified to ensure corrections are made for periods >= @pnPeriodId
--					Made a number of bug fixes also
-- 15 Apr 2013	DV	R13270	 5	Increase the length of nvarchar to 11 when casting or declaring integer
-- 30 Jul 2013	DL	RFC13494 6	Modify filter to adjust all periods from a specified period.
-- 31 Oct 2018	DL	DR-45102	7	Replace control character (word hyphen) with normal sql editor hyphen

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nCurrentPeriodId	int		-- Mandatory
Declare	@dtEndDate		datetime	-- Mandatory
Declare @nNextPeriodId		int


-- Initialise variables
Set @nErrorCode = 0

/*
Control totals will be updated based on values from:
1 - WIP - WORKHISTORY - REFENTITYNO
2 - Debtors - DEBTORHISTORY - REFENTITYNO
3 - Tax - n/a - recorded but not reconciled
4 - Cash - CASHHISTORY - REFENTITYNO
5 - Bank - BANKHISTORY - ENTITYNO
6 - Creditors - CREDITORHISTORY - REFENTITYNO
7 - Tax Paid - n/a - recorded but not reconciled
8 - Trust - TRUSTHISTORY - REFENTITYNO
*/

-- Update for WIP Ledger:
if (@pnLedger = 1) or (@pnLedger is null)
Begin
		
	If @pbDebug = 1
	Begin 	
		Print 'Insert control totals that are missing based on totals calculated from WORKHISTORY'
		SELECT 1, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALTRANSVALUE, 0)) AS HISTTOTAL
			FROM WORKHISTORY 
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 1)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0
		
		print ''
	End
	
	Begin
		Set @sSQLString = "INSERT INTO [dbo].[CONTROLTOTAL]
		   ([LEDGER], [CATEGORY], [TYPE], [PERIODID], [ENTITYNO], [TOTAL])
		SELECT 1, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALTRANSVALUE, 0)) AS HISTTOTAL
			FROM WORKHISTORY 
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 1)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0"

		
		If (@pnPeriodId is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
		AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(11))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
		AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
			
		If @pbDebug = 1
		Begin
			print @sSQLString
			print ''
		End
	end


	If (@nErrorCode = 0)
	Begin
		
		If @pbDebug = 1
		Begin
			Print 'Update control totals with totals calculated from WORKHISTORY'
			SELECT C.LEDGER, C.ENTITYNO, C.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, REFENTITYNO, POSTPERIOD, MOVEMENTCLASS, TRANSTYPE, H.HTOTAL 
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(LOCALTRANSVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
				FROM WORKHISTORY
				WHERE STATUS <> 0
				GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
												AND H.POSTPERIOD = C.PERIODID
												AND H.TRANSTYPE = C.TYPE
												AND H.MOVEMENTCLASS = C.CATEGORY)												
			WHERE C.LEDGER = 1
			AND C.CATEGORY <> 99
			AND C.TOTAL <> H.HTOTAL
			ORDER BY ENTITYNO, PERIODID, TYPE, CATEGORY
			
			print ''
		End
		
		-- Update Control Total for WIP Ledger Transactions for specified period
		Set @sSQLString = "
		UPDATE C
		SET TOTAL = H.HTOTAL
		FROM CONTROLTOTAL C
		JOIN (SELECT SUM(ISNULL(LOCALTRANSVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
			FROM WORKHISTORY
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
											AND H.POSTPERIOD = C.PERIODID
											AND H.TRANSTYPE = C.TYPE
											AND H.MOVEMENTCLASS = C.CATEGORY)						
		WHERE C.LEDGER = 1
		AND C.CATEGORY <> 99
		AND C.TOTAL <> H.HTOTAL"
				
		If (@pnPeriodId is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(11))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
		If @pbDebug = 1
		Begin
			print @sSQLString
			print ''
		End
		
	End
	
	If (@nErrorCode = 0)
	Begin
	
		If @pbDebug = 1
		Begin
			Print 'WIP Ledger opening balances before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = (SELECT TOP 1 PERIODID
													FROM PERIOD
													WHERE ENDDATE < P.STARTDATE
													ORDER BY PERIODID DESC))
			WHERE C.LEDGER = 1
			AND C.CATEGORY = 99
			AND C.TYPE = 00 -- OPENING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
			print ''
			
			Print 'WIP Ledger closing balances Before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				-- SELECT * 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999
				--AND CT.PERIODID = 200502
				--AND CT.LEDGER = 1
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 1
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
			print ''
		End


		If (@pnPeriodId is not null)
		begin
			SET @nCurrentPeriodId = @pnPeriodId
		End
		Else
		Begin
			-- Get the first PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where POSTINGCOMMENCED IS NOT NULL
		End
		
		While @nCurrentPeriodId is not null
		Begin
			SELECT @dtEndDate = ENDDATE
			FROM PERIOD
			WHERE PERIODID = @nCurrentPeriodId

			SELECT TOP 1 @nNextPeriodId = PERIODID
			-- select *
			FROM PERIOD
			WHERE ENDDATE > @dtEndDate
			ORDER BY ENDDATE
			
			If @pbDebug = 1
			Begin			
				SELECT 	@nCurrentPeriodId AS CURRENTPERIOD, @dtEndDate AS STARTDATE, @nNextPeriodId AS NEXTPERIOD
						
				Print 'Update WIP Ledger closing balances for the current period from updated control total details'
				print ''
			End
			
			Set @sSQLString = "UPDATE C
			SET TOTAL = CT1.BALANCE
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 1
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			AND C.PERIODID = @nCurrentPeriodId
			AND C.TOTAL <> CT1.BALANCE "
			
			If (@pnEntityNo is not NULL)
			Begin 
				Set @sSQLString = @sSQLString + "
			AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
			End

			exec @nErrorCode=sp_executesql @sSQLString,
		      		N'@nCurrentPeriodId	int,	
				@pnEntityNo		int',
				@nCurrentPeriodId	= @nCurrentPeriodId,
				@pnEntityNo		= @pnEntityNo

			If @pbDebug = 1
			Begin
				print @sSQLString
				print ''
			End
			
			If (@nErrorCode = 0)
			Begin
				If @pbDebug = 1
				Begin			
					Print 'Update WIP Ledger opening balances for the next period from updated control total details'
					print ''
				End
				
				Set @sSQLString = "UPDATE C
				SET TOTAL = CT1.BALANCE
				FROM CONTROLTOTAL C
				JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
				JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
					FROM CONTROLTOTAL CT
					WHERE CT.TYPE <> 9999 -- Closing Balance
					GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
											AND CT1.ENTITYNO = C.ENTITYNO
											AND CT1.PERIODID = @nCurrentPeriodId)
				WHERE C.LEDGER = 1
				AND C.CATEGORY = 99
				AND C.TYPE = 00 -- OPENING BALANCE
				AND C.PERIODID = @nNextPeriodId
				AND C.TOTAL <> CT1.BALANCE "
				
				If (@pnEntityNo is not NULL)
				Begin 
					Set @sSQLString = @sSQLString + "
				AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
				End

				exec @nErrorCode=sp_executesql @sSQLString,
		      			N'@nCurrentPeriodId	int,	
		      			@nNextPeriodId		int,	
					@pnEntityNo		int',
					@nCurrentPeriodId	= @nCurrentPeriodId,
					@nNextPeriodId		= @nNextPeriodId,
					@pnEntityNo		= @pnEntityNo
					
				If @pbDebug = 1
				Begin
					print @sSQLString
					print ''
				End
			End


			-- Now get the next PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where PERIODID>@nCurrentPeriodId
			AND POSTINGCOMMENCED IS NOT NULL
			
			SET @nNextPeriodId = NULL
		End
	End
End

-- Update for Debtors Ledger:
If (@nErrorCode = 0) AND ((@pnLedger = 2) or (@pnLedger is null))
Begin
		
	If @pbDebug = 1
	Begin 	
		Print 'Insert control totals that are missing based on totals calculated from DEBTORHISTORY'
		SELECT 2, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALVALUE, 0)) AS HISTTOTAL
			FROM DEBTORHISTORY 
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 2)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0
		
		print ''
	End
	
	Begin
		Set @sSQLString = "INSERT INTO [dbo].[CONTROLTOTAL]
		   ([LEDGER], [CATEGORY], [TYPE], [PERIODID], [ENTITYNO], [TOTAL])
		SELECT 2, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALVALUE, 0)) AS HISTTOTAL
			FROM DEBTORHISTORY 
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 2)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0"

		
		If (@pnPeriodId is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(11))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
		If @pbDebug = 1
		Begin
			print @sSQLString
			print ''
		End
	end


	If (@nErrorCode = 0)
	Begin
		
		If @pbDebug = 1
		Begin
			Print 'Update control totals with totals calculated from DEBTORHISTORY'
			SELECT C.LEDGER, C.ENTITYNO, C.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, REFENTITYNO, POSTPERIOD, MOVEMENTCLASS, TRANSTYPE, H.HTOTAL 
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(LOCALVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
				FROM DEBTORHISTORY
				WHERE STATUS <> 0
				GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
												AND H.POSTPERIOD = C.PERIODID
												AND H.TRANSTYPE = C.TYPE
												AND H.MOVEMENTCLASS = C.CATEGORY)												
			WHERE C.LEDGER = 2
			AND C.CATEGORY <> 99
			AND C.TOTAL <> H.HTOTAL
			ORDER BY ENTITYNO, PERIODID, TYPE, CATEGORY
			
			print ''
		End
		
		-- Update Control Total for Debtors Ledger Transactions for specified period
		Set @sSQLString = "
		UPDATE C
		SET TOTAL = H.HTOTAL
		FROM CONTROLTOTAL C
		JOIN (SELECT SUM(ISNULL(LOCALVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
			FROM DEBTORHISTORY
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
											AND H.POSTPERIOD = C.PERIODID
											AND H.TRANSTYPE = C.TYPE
											AND H.MOVEMENTCLASS = C.CATEGORY)						
		WHERE C.LEDGER = 2
		AND C.CATEGORY <> 99
		AND C.TOTAL <> H.HTOTAL"
				
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
		If @pbDebug = 1
		Begin
			print @sSQLString
			print ''
		End
		
	End
	
	If (@nErrorCode = 0)
	Begin
	
		If @pbDebug = 1
		Begin
			Print 'Debtors Ledger opening balances before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = (SELECT TOP 1 PERIODID
													FROM PERIOD
													WHERE ENDDATE < P.STARTDATE
													ORDER BY PERIODID DESC))
			WHERE C.LEDGER = 2
			AND C.CATEGORY = 99
			AND C.TYPE = 00 -- OPENING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
			print ''
			
			Print 'Debtors Ledger closing balances Before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				-- SELECT * 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999
				AND CT.CATEGORY <> 9 -- Equalise
				--AND CT.PERIODID = 200502
				--AND CT.LEDGER = 2
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 2
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
			print ''
		End


		If (@pnPeriodId is not null)
		begin
			SET @nCurrentPeriodId = @pnPeriodId
		End
		Else
		Begin
			-- Get the first PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where POSTINGCOMMENCED IS NOT NULL
		End
		
		While @nCurrentPeriodId is not null
		Begin
			SELECT @dtEndDate = ENDDATE
			FROM PERIOD
			WHERE PERIODID = @nCurrentPeriodId

			SELECT TOP 1 @nNextPeriodId = PERIODID
			-- select *
			FROM PERIOD
			WHERE ENDDATE > @dtEndDate
			ORDER BY ENDDATE
			
			If @pbDebug = 1
			Begin			
				SELECT 	@nCurrentPeriodId AS CURRENTPERIOD, @dtEndDate AS STARTDATE, @nNextPeriodId AS NEXTPERIOD
						
				Print 'Update Debtors Ledger closing balances for the current period from updated control total details'
				print ''
			End
			
			Set @sSQLString = "UPDATE C
			SET TOTAL = CT1.BALANCE
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 2
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			AND C.PERIODID = @nCurrentPeriodId
			AND C.TOTAL <> CT1.BALANCE "
			
			If (@pnEntityNo is not NULL)
			Begin 
				Set @sSQLString = @sSQLString + "
				AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
			End

			exec @nErrorCode=sp_executesql @sSQLString,
		      		N'@nCurrentPeriodId	int,	
				@pnEntityNo		int',
				@nCurrentPeriodId	= @nCurrentPeriodId,
				@pnEntityNo		= @pnEntityNo
			
			
			If @pbDebug = 1
			Begin
				print @sSQLString
				print ''
			End
						
			If (@nErrorCode = 0)
			Begin
				If @pbDebug = 1
				Begin			
					Print 'Update Debtors Ledger opening balances for the next period from updated control total details'
					print ''
				End
				
				Set @sSQLString = "UPDATE C
				SET TOTAL = CT1.BALANCE
				FROM CONTROLTOTAL C
				JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
				JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
					FROM CONTROLTOTAL CT
					WHERE CT.TYPE <> 9999 -- Closing Balance
					AND CT.CATEGORY <> 9 -- Equalise
					GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
											AND CT1.ENTITYNO = C.ENTITYNO
											AND CT1.PERIODID = @nCurrentPeriodId)
				WHERE C.LEDGER = 2
				AND C.CATEGORY = 99
				AND C.TYPE = 00 -- OPENING BALANCE
				AND C.PERIODID = @nNextPeriodId
				AND C.TOTAL <> CT1.BALANCE "
				
				If (@pnEntityNo is not NULL)
				Begin 
					Set @sSQLString = @sSQLString + "
					AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
				End

				exec @nErrorCode=sp_executesql @sSQLString,
		      			N'@nCurrentPeriodId	int,	
		      			@nNextPeriodId		int,	
					@pnEntityNo		int',
					@nCurrentPeriodId	= @nCurrentPeriodId,
					@nNextPeriodId		= @nNextPeriodId,
					@pnEntityNo		= @pnEntityNo
				
				If @pbDebug = 1
				Begin
					print @sSQLString
					print ''
				End
			End

			-- Now get the next PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where PERIODID>@nCurrentPeriodId
			AND POSTINGCOMMENCED IS NOT NULL
			
			SET @nNextPeriodId = NULL
		End
		
		If @pbDebug = 1
		Begin
			Print 'Debtors Ledger opening balances AFTER update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = (SELECT TOP 1 PERIODID
													FROM PERIOD
													WHERE ENDDATE < P.STARTDATE
													ORDER BY PERIODID DESC))
			WHERE C.LEDGER = 2
			AND C.CATEGORY = 99
			AND C.TYPE = 00 -- OPENING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
			print ''
			
			Print 'Debtors Ledger closing balances AFTER update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				-- SELECT * 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999
				AND CT.CATEGORY <> 9 -- Equalise
				--AND CT.PERIODID = 200502
				--AND CT.LEDGER = 2
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 2
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
			print ''
		End
	End
End

-- Update for Cash Ledger:
if (@nErrorCode = 0) AND ((@pnLedger = 4) or (@pnLedger is null))
Begin
		
	If @pbDebug = 1
	Begin 	
		Print 'Insert control totals that are missing based on totals calculated from CASHHISTORY'
		SELECT 4, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALAMOUNT, 0)) AS HISTTOTAL
			FROM CASHHISTORY 
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 4)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0
		
		Print ''
	End
	
	Begin
		Set @sSQLString = "INSERT INTO [dbo].[CONTROLTOTAL]
		   ([LEDGER], [CATEGORY], [TYPE], [PERIODID], [ENTITYNO], [TOTAL])
		SELECT 4, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALAMOUNT, 0)) AS HISTTOTAL
			FROM CASHHISTORY 
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 4)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0"

		
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
		If @pbDebug = 1
		Begin
			print @sSQLString
		End
	end


	If (@nErrorCode = 0)
	Begin
		
		If @pbDebug = 1
		Begin
			Print 'Update control totals with totals calculated from CASHHISTORY'
			SELECT C.LEDGER, C.ENTITYNO, C.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, REFENTITYNO, POSTPERIOD, MOVEMENTCLASS, TRANSTYPE, H.HTOTAL 
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(LOCALAMOUNT,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
				FROM CASHHISTORY
				WHERE STATUS <> 0
				GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
												AND H.POSTPERIOD = C.PERIODID
												AND H.TRANSTYPE = C.TYPE
												AND H.MOVEMENTCLASS = C.CATEGORY)												
			WHERE C.LEDGER = 4
			AND C.CATEGORY <> 99
			AND C.TOTAL <> H.HTOTAL
			ORDER BY ENTITYNO, PERIODID, TYPE, CATEGORY

		End
		
		-- Update Control Total for Cash Ledger Transactions for specified period
		Set @sSQLString = "
		UPDATE C
		SET TOTAL = H.HTOTAL
		FROM CONTROLTOTAL C
		JOIN (SELECT SUM(ISNULL(LOCALAMOUNT,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
			FROM CASHHISTORY
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
											AND H.POSTPERIOD = C.PERIODID
											AND H.TRANSTYPE = C.TYPE
											AND H.MOVEMENTCLASS = C.CATEGORY)						
		WHERE C.LEDGER = 4
		AND C.CATEGORY <> 99
		AND C.TOTAL <> H.HTOTAL"
				
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
	End
	
	If (@nErrorCode = 0)
	Begin
	
		If @pbDebug = 1
		Begin
			Print 'Cash Ledger opening balances before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = (SELECT TOP 1 PERIODID
													FROM PERIOD
													WHERE ENDDATE < P.STARTDATE
													ORDER BY PERIODID DESC))
			WHERE C.LEDGER = 4
			AND C.CATEGORY = 99
			AND C.TYPE = 00 -- OPENING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID

			Print 'Cash Ledger closing balances Before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				-- SELECT * 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				--AND CT.PERIODID = 200502
				--AND CT.LEDGER = 4
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 4
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
		End


		If (@pnPeriodId is not null)
		begin
			SET @nCurrentPeriodId = @pnPeriodId
		End
		Else
		Begin
			-- Get the first PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where POSTINGCOMMENCED IS NOT NULL
		End
		
		While @nCurrentPeriodId is not null
		Begin
			SELECT @dtEndDate = ENDDATE
			FROM PERIOD
			WHERE PERIODID = @nCurrentPeriodId

			SELECT TOP 1 @nNextPeriodId = PERIODID
			-- select *
			FROM PERIOD
			WHERE ENDDATE > @dtEndDate
			ORDER BY ENDDATE
			
			If @pbDebug = 1
			Begin			
				SELECT 	@nCurrentPeriodId AS CURRENTPERIOD, @dtEndDate AS STARTDATE, @nNextPeriodId AS NEXTPERIOD
						
				Print 'Update the Cash Ledger closing balances for the current period from updated control total details'
			End
			
			Set @sSQLString = "UPDATE C
			SET TOTAL = CT1.BALANCE
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 4
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			AND C.PERIODID = @nCurrentPeriodId
			AND C.TOTAL <> CT1.BALANCE "
			
			If (@pnEntityNo is not NULL)
			Begin 
				Set @sSQLString = @sSQLString + "
				AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
			End

			exec @nErrorCode=sp_executesql @sSQLString,
		      		N'@nCurrentPeriodId	int,	
				@pnEntityNo		int',
				@nCurrentPeriodId	= @nCurrentPeriodId,
				@pnEntityNo		= @pnEntityNo

			
			
			If (@nErrorCode = 0)
			Begin
				If @pbDebug = 1
				Begin			
					Print 'Update the Cash Ledger opening balances for the next period from updated control total details'
				End
				
				Set @sSQLString = "UPDATE C
				SET TOTAL = CT1.BALANCE
				FROM CONTROLTOTAL C
				JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
				JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
					FROM CONTROLTOTAL CT
					WHERE CT.TYPE <> 9999 -- Closing Balance
					AND CT.CATEGORY <> 9 -- Equalise
					GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
											AND CT1.ENTITYNO = C.ENTITYNO
											AND CT1.PERIODID = @nCurrentPeriodId)
				WHERE C.LEDGER = 4
				AND C.CATEGORY = 99
				AND C.TYPE = 00 -- OPENING BALANCE
				AND C.PERIODID = @nNextPeriodId
				AND C.TOTAL <> CT1.BALANCE "
				
				If (@pnEntityNo is not NULL)
				Begin 
					Set @sSQLString = @sSQLString + "
				AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
				End

				exec @nErrorCode=sp_executesql @sSQLString,
		      			N'@nCurrentPeriodId	int,	
		      			@nNextPeriodId		int,	
					@pnEntityNo		int',
					@nCurrentPeriodId	= @nCurrentPeriodId,
					@nNextPeriodId		= @nNextPeriodId,
					@pnEntityNo		= @pnEntityNo
				
				If @pbDebug = 1
				Begin
					print @sSQLString
				End
			End

			-- Now get the next PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where PERIODID>@nCurrentPeriodId
			AND POSTINGCOMMENCED IS NOT NULL
			
			SET @nNextPeriodId = NULL
		End
	End
End


-- Update for Bank Ledger:
if (@nErrorCode = 0) AND ((@pnLedger = 5) or (@pnLedger is null))
Begin
		
	If @pbDebug = 1
	Begin 	
		Print 'Insert control totals that are missing based on totals calculated from BANKHISTORY'
		SELECT 5, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.ENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, ENTITYNO, SUM(ISNULL(LOCALNET, 0)) AS HISTTOTAL
			FROM BANKHISTORY 
			WHERE STATUS <> 0
			GROUP BY ENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.ENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 5)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0
		
		Print ''
	End
	
	Begin
		Set @sSQLString = "INSERT INTO [dbo].[CONTROLTOTAL]
		   ([LEDGER], [CATEGORY], [TYPE], [PERIODID], [ENTITYNO], [TOTAL])
		SELECT 5, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.ENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, ENTITYNO, SUM(ISNULL(LOCALNET, 0)) AS HISTTOTAL
			FROM BANKHISTORY 
			WHERE STATUS <> 0
			GROUP BY ENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.ENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 5)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0"

		
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
	end


	If (@nErrorCode = 0)
	Begin
		
		If @pbDebug = 1
		Begin
			Print 'Update control totals with totals calculated from BANKHISTORY'
			SELECT C.LEDGER, C.ENTITYNO, C.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, H.ENTITYNO, H.POSTPERIOD, H.MOVEMENTCLASS, H.TRANSTYPE, H.HTOTAL 
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(LOCALNET,0)) as HTOTAL, ENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
				FROM BANKHISTORY
				WHERE STATUS <> 0
				GROUP BY ENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.ENTITYNO = C.ENTITYNO
												AND H.POSTPERIOD = C.PERIODID
												AND H.TRANSTYPE = C.TYPE
												AND H.MOVEMENTCLASS = C.CATEGORY)												
			WHERE C.LEDGER = 5
			AND C.CATEGORY <> 99
			AND C.TOTAL <> H.HTOTAL
			ORDER BY C.ENTITYNO, C.PERIODID, C.TYPE, C.CATEGORY

		End
		
		-- Update Control Total for Bank Ledger Transactions for specified period
		Set @sSQLString = "
		UPDATE C
		SET TOTAL = H.HTOTAL
		FROM CONTROLTOTAL C
		JOIN (SELECT SUM(ISNULL(LOCALNET,0)) as HTOTAL, ENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
			FROM BANKHISTORY
			WHERE STATUS <> 0
			GROUP BY ENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.ENTITYNO = C.ENTITYNO
											AND H.POSTPERIOD = C.PERIODID
											AND H.TRANSTYPE = C.TYPE
											AND H.MOVEMENTCLASS = C.CATEGORY)						
		WHERE C.LEDGER = 5
		AND C.CATEGORY <> 99
		AND C.TOTAL <> H.HTOTAL"
				
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
	End
	
	If (@nErrorCode = 0)
	Begin
	
		If @pbDebug = 1
		Begin
			Print 'Bank Ledger opening balances before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = (SELECT TOP 1 PERIODID
													FROM PERIOD
													WHERE ENDDATE < P.STARTDATE
													ORDER BY PERIODID DESC))
			WHERE C.LEDGER = 5
			AND C.CATEGORY = 99
			AND C.TYPE = 00 -- OPENING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID

			Print 'Bank Ledger closing balances Before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				-- SELECT * 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				--AND CT.PERIODID = 200502
				--AND CT.LEDGER = 5
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 5
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
		End


		If (@pnPeriodId is not null)
		begin
			SET @nCurrentPeriodId = @pnPeriodId
		End
		Else
		Begin
			-- Get the first PeriodId
			Select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			WHERE POSTINGCOMMENCED IS NOT NULL
		End
		
		While @nCurrentPeriodId is not null
		Begin
			SELECT @dtEndDate = ENDDATE
			FROM PERIOD
			WHERE PERIODID = @nCurrentPeriodId

			SELECT TOP 1 @nNextPeriodId = PERIODID
			-- select *
			FROM PERIOD
			WHERE ENDDATE > @dtEndDate
			ORDER BY ENDDATE
			
			If @pbDebug = 1
			Begin			
				SELECT 	@nCurrentPeriodId AS CURRENTPERIOD, @dtEndDate AS STARTDATE, @nNextPeriodId AS NEXTPERIOD
						
				Print 'Update the Bank Ledger closing balances for the current period from updated control total details'
			End
			
			Set @sSQLString = "UPDATE C
			SET TOTAL = CT1.BALANCE
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 5
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			AND C.PERIODID = @nCurrentPeriodId
			AND C.TOTAL <> CT1.BALANCE "
			
			If (@pnEntityNo is not NULL)
			Begin 
				Set @sSQLString = @sSQLString + "
			AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
			End

			exec @nErrorCode=sp_executesql @sSQLString,
		      		N'@nCurrentPeriodId	int,	
				@pnEntityNo		int',
				@nCurrentPeriodId	= @nCurrentPeriodId,
				@pnEntityNo		= @pnEntityNo

			
			
			If (@nErrorCode = 0)
			Begin
				If @pbDebug = 1
				Begin			
					Print 'Update the Bank Ledger opening balances for the next period from updated control total details'
				End
				
				Set @sSQLString = "UPDATE C
				SET TOTAL = CT1.BALANCE
				FROM CONTROLTOTAL C
				JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
				JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
					FROM CONTROLTOTAL CT
					WHERE CT.TYPE <> 9999 -- Closing Balance
					AND CT.CATEGORY <> 9 -- Equalise
					GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
											AND CT1.ENTITYNO = C.ENTITYNO
											AND CT1.PERIODID = @nCurrentPeriodId)
				WHERE C.LEDGER = 5
				AND C.CATEGORY = 99
				AND C.TYPE = 00 -- OPENING BALANCE
				AND C.PERIODID = @nNextPeriodId
				AND C.TOTAL <> CT1.BALANCE "
				
				If (@pnEntityNo is not NULL)
				Begin 
					Set @sSQLString = @sSQLString + "
					AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
				End

				exec @nErrorCode=sp_executesql @sSQLString,
		      			N'@nCurrentPeriodId	int,	
		      			@nNextPeriodId		int,	
					@pnEntityNo		int',
					@nCurrentPeriodId	= @nCurrentPeriodId,
					@nNextPeriodId		= @nNextPeriodId,
					@pnEntityNo		= @pnEntityNo
				
				If @pbDebug = 1
				Begin
					print @sSQLString
				End
			End

			-- Now get the next PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where PERIODID>@nCurrentPeriodId
			AND POSTINGCOMMENCED IS NOT NULL
			
			SET @nNextPeriodId = NULL
		End
	End
End

-- Update for Creditors Ledger:
if (@nErrorCode = 0) AND ((@pnLedger = 6) or (@pnLedger is null))
Begin
		
	If @pbDebug = 1
	Begin 	
		Print 'Insert control totals that are missing based on totals calculated from CREDITORHISTORY'
		SELECT 6, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALVALUE, 0)) AS HISTTOTAL
			FROM CREDITORHISTORY 
			WHERE STATUS <> 0
			GROUP BY ITEMENTITYNO, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 6)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0
		
		PRINT ''
	End
	
	Begin
		Set @sSQLString = "INSERT INTO [dbo].[CONTROLTOTAL]
		   ([LEDGER], [CATEGORY], [TYPE], [PERIODID], [ENTITYNO], [TOTAL])
		SELECT 6, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALVALUE, 0)) AS HISTTOTAL
			FROM CREDITORHISTORY 
			WHERE STATUS <> 0
			GROUP BY ITEMENTITYNO, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 6)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0"

		
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
	end


	If (@nErrorCode = 0)
	Begin
		
		If @pbDebug = 1
		Begin
			Print 'Update control totals with totals calculated from CREDITORHISTORY'
			SELECT C.LEDGER, C.ENTITYNO, C.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, REFENTITYNO, POSTPERIOD, MOVEMENTCLASS, TRANSTYPE, H.HTOTAL 
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(LOCALVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
				FROM CREDITORHISTORY
				WHERE STATUS <> 0
				GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
												AND H.POSTPERIOD = C.PERIODID
												AND H.TRANSTYPE = C.TYPE
												AND H.MOVEMENTCLASS = C.CATEGORY)												
			WHERE C.LEDGER = 6
			AND C.CATEGORY <> 99
			AND C.TOTAL <> H.HTOTAL
			ORDER BY ENTITYNO, PERIODID, TYPE, CATEGORY

		End
		
		-- Update Control Total for Creditor Ledger Transactions for specified period
		Set @sSQLString = "
		UPDATE C
		SET TOTAL = H.HTOTAL
		FROM CONTROLTOTAL C
		JOIN (SELECT SUM(ISNULL(LOCALVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
			FROM CREDITORHISTORY
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
											AND H.POSTPERIOD = C.PERIODID
											AND H.TRANSTYPE = C.TYPE
											AND H.MOVEMENTCLASS = C.CATEGORY)						
		WHERE C.LEDGER = 6
		AND C.CATEGORY <> 99
		AND C.TOTAL <> H.HTOTAL"
				
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
	End
	
	If (@nErrorCode = 0)
	Begin
	
		If @pbDebug = 1
		Begin
			Print 'Creditor Ledger opening balances before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = (SELECT TOP 1 PERIODID
													FROM PERIOD
													WHERE ENDDATE < P.STARTDATE
													ORDER BY PERIODID DESC))
			WHERE C.LEDGER = 6
			AND C.CATEGORY = 99
			AND C.TYPE = 00 -- OPENING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID

			Print 'Creditors Ledger losing balances Before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				-- SELECT * 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				--AND CT.PERIODID = 200502
				--AND CT.LEDGER = 6
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 6
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
		End


		If (@pnPeriodId is not null)
		begin
			SET @nCurrentPeriodId = @pnPeriodId
		End
		Else
		Begin
			-- Get the first PeriodId
			Select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			WHERE POSTINGCOMMENCED IS NOT NULL
		End
		
		While @nCurrentPeriodId is not null
		Begin
			SELECT @dtEndDate = ENDDATE
			FROM PERIOD
			WHERE PERIODID = @nCurrentPeriodId

			SELECT TOP 1 @nNextPeriodId = PERIODID
			-- select *
			FROM PERIOD
			WHERE ENDDATE > @dtEndDate
			ORDER BY ENDDATE
			
			If @pbDebug = 1
			Begin			
				SELECT 	@nCurrentPeriodId AS CURRENTPERIOD, @dtEndDate AS STARTDATE, @nNextPeriodId AS NEXTPERIOD
						
				Print 'Update the Creditors Ledger closing balances for the current period from updated control total details'
			End
			
			Set @sSQLString = "UPDATE C
			SET TOTAL = CT1.BALANCE
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 6
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			AND C.PERIODID = @nCurrentPeriodId
			AND C.TOTAL <> CT1.BALANCE "
			
			If (@pnEntityNo is not NULL)
			Begin 
				Set @sSQLString = @sSQLString + "
			AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
			End

			exec @nErrorCode=sp_executesql @sSQLString,
		      		N'@nCurrentPeriodId	int,	
				@pnEntityNo		int',
				@nCurrentPeriodId	= @nCurrentPeriodId,
				@pnEntityNo		= @pnEntityNo

			
			
			If (@nErrorCode = 0)
			Begin
				If @pbDebug = 1
				Begin			
					Print 'Update the Creditors Ledger opening balances for the next period from updated control total details'
				End
				
				Set @sSQLString = "UPDATE C
				SET TOTAL = CT1.BALANCE
				FROM CONTROLTOTAL C
				JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
				JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
					FROM CONTROLTOTAL CT
					WHERE CT.TYPE <> 9999 -- Closing Balance
					AND CT.CATEGORY <> 9 -- Equalise
					GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
											AND CT1.ENTITYNO = C.ENTITYNO
											AND CT1.PERIODID = @nCurrentPeriodId)
				WHERE C.LEDGER = 6
				AND C.CATEGORY = 99
				AND C.TYPE = 00 -- OPENING BALANCE
				AND C.PERIODID = @nNextPeriodId
				AND C.TOTAL <> CT1.BALANCE "
				
				If (@pnEntityNo is not NULL)
				Begin 
					Set @sSQLString = @sSQLString + "
					AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
				End

				exec @nErrorCode=sp_executesql @sSQLString,
		      			N'@nCurrentPeriodId	int,	
		      			@nNextPeriodId		int,	
					@pnEntityNo		int',
					@nCurrentPeriodId	= @nCurrentPeriodId,
					@nNextPeriodId		= @nNextPeriodId,
					@pnEntityNo		= @pnEntityNo
				
				If @pbDebug = 1
				Begin
					print @sSQLString
				End
			End

			-- Now get the next PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where PERIODID>@nCurrentPeriodId
			AND POSTINGCOMMENCED IS NOT NULL
			
			SET @nNextPeriodId = NULL
		End
	End
End

-- Update for Trust Ledger:
if (@nErrorCode = 0) AND ((@pnLedger = 8) or (@pnLedger is null))
Begin
		
	If @pbDebug = 1
	Begin 	
		Print 'Insert control totals that are missing based on totals calculated from TRUSTHISTORY'
		SELECT 8, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALVALUE, 0)) AS HISTTOTAL
			FROM TRUSTHISTORY 
			WHERE STATUS <> 0
			GROUP BY ITEMENTITYNO, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 8)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0
		
		PRINT ''
	End
	
	Begin
		Set @sSQLString = "INSERT INTO [dbo].[CONTROLTOTAL]
		   ([LEDGER], [CATEGORY], [TYPE], [PERIODID], [ENTITYNO], [TOTAL])
		SELECT 8, H.MOVEMENTCLASS, H.TRANSTYPE, H.POSTPERIOD, H.REFENTITYNO, H.HISTTOTAL
		FROM (SELECT MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, REFENTITYNO, SUM(ISNULL(LOCALVALUE, 0)) AS HISTTOTAL
			FROM TRUSTHISTORY 
			WHERE STATUS <> 0
			GROUP BY ITEMENTITYNO, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H 
		LEFT JOIN CONTROLTOTAL CT	ON (CT.ENTITYNO = H.REFENTITYNO
						AND CT.PERIODID = H.POSTPERIOD
						AND CT.TYPE = H.TRANSTYPE
						AND CT.CATEGORY = H.MOVEMENTCLASS
						AND CT.LEDGER = 8)
		WHERE CT.ENTITYNO IS NULL
		AND CT.PERIODID IS NULL
		AND CT.TYPE IS NULL
		AND CT.CATEGORY IS NULL
		AND H.HISTTOTAL <> 0"

		
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
	end


	If (@nErrorCode = 0)
	Begin
		
		If @pbDebug = 1
		Begin
			Print 'Update control totals with totals calculated from TRUSTHISTORY'
			SELECT C.LEDGER, C.ENTITYNO, C.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, REFENTITYNO, POSTPERIOD, MOVEMENTCLASS, TRANSTYPE, H.HTOTAL 
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(LOCALVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
				FROM TRUSTHISTORY
				WHERE STATUS <> 0
				GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
												AND H.POSTPERIOD = C.PERIODID
												AND H.TRANSTYPE = C.TYPE
												AND H.MOVEMENTCLASS = C.CATEGORY)												
			WHERE C.LEDGER = 8
			AND C.CATEGORY <> 99
			AND C.TOTAL <> H.HTOTAL
			ORDER BY ENTITYNO, PERIODID, TYPE, CATEGORY

		End
		
		-- Update Control Total for Trust Ledger Transactions for specified period
		Set @sSQLString = "
		UPDATE C
		SET TOTAL = H.HTOTAL
		FROM CONTROLTOTAL C
		JOIN (SELECT SUM(ISNULL(LOCALVALUE,0)) as HTOTAL, REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS
			FROM TRUSTHISTORY
			WHERE STATUS <> 0
			GROUP BY REFENTITYNO, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS) H	ON (H.REFENTITYNO = C.ENTITYNO
											AND H.POSTPERIOD = C.PERIODID
											AND H.TRANSTYPE = C.TYPE
											AND H.MOVEMENTCLASS = C.CATEGORY)						
		WHERE C.LEDGER = 8
		AND C.CATEGORY <> 99
		AND C.TOTAL <> H.HTOTAL"
				
		If (@pnPeriodId is not NULL)
		Begin 
			-- RFC13494 Modify filter to adjust all periods from a specified period.
			Set @sSQLString = @sSQLString + "
			AND H.POSTPERIOD >= " + CAST(@pnPeriodId as NVARCHAR(10))
		End
		
		If (@pnEntityNo is not NULL)
		Begin 
			Set @sSQLString = @sSQLString + "
			AND H.REFENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
		End

		exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnPeriodId		int,	
			@pnEntityNo		int',
			@pnPeriodId	= @pnPeriodId,
			@pnEntityNo	= @pnEntityNo
		
	End
	
	If (@nErrorCode = 0)
	Begin
	
		If @pbDebug = 1
		Begin
			Print 'Trust Ledger opening balances before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = (SELECT TOP 1 PERIODID
													FROM PERIOD
													WHERE ENDDATE < P.STARTDATE
													ORDER BY PERIODID DESC))
			WHERE C.LEDGER = 8
			AND C.CATEGORY = 99
			AND C.TYPE = 00 -- OPENING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID

			Print 'Trust Ledger closing balances Before update'
			SELECT C.ENTITYNO, CT1.ENTITYNO, C.PERIODID, CT1.PERIODID, C.CATEGORY, C.TYPE, C.TOTAL, CT1.BALANCE, CT1.LEDGER
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				-- SELECT * 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				--AND CT.PERIODID = 200502
				--AND CT.LEDGER = 8
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 8
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			ORDER BY C.ENTITYNO, C.PERIODID
		End


		If (@pnPeriodId is not null)
		begin
			SET @nCurrentPeriodId = @pnPeriodId
		End
		Else
		Begin
			-- Get the first PeriodId
			Select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			WHERE POSTINGCOMMENCED IS NOT NULL
		End
		
		While @nCurrentPeriodId is not null
		Begin
			SELECT @dtEndDate = ENDDATE
			FROM PERIOD
			WHERE PERIODID = @nCurrentPeriodId

			SELECT TOP 1 @nNextPeriodId = PERIODID
			-- select *
			FROM PERIOD
			WHERE ENDDATE > @dtEndDate
			ORDER BY ENDDATE
			
			If @pbDebug = 1
			Begin			
				SELECT 	@nCurrentPeriodId AS CURRENTPERIOD, @dtEndDate AS STARTDATE, @nNextPeriodId AS NEXTPERIOD
						
				Print 'Update the Trust Ledger closing balances for the current period from updated control total details'
			End
			
			Set @sSQLString = "UPDATE C
			SET TOTAL = CT1.BALANCE
			FROM CONTROLTOTAL C
			JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID 
				FROM CONTROLTOTAL CT
				WHERE CT.TYPE <> 9999 -- Closing Balance
				AND CT.CATEGORY <> 9 -- Equalise
				GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
										AND CT1.ENTITYNO = C.ENTITYNO
										AND CT1.PERIODID = C.PERIODID)
			WHERE C.LEDGER = 8
			AND C.CATEGORY = 99
			AND C.TYPE = 9999 -- CLOSING BALANCE
			AND C.PERIODID = @nCurrentPeriodId
			AND C.TOTAL <> CT1.BALANCE "
			
			If (@pnEntityNo is not NULL)
			Begin 
				Set @sSQLString = @sSQLString + "
			AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
			End

			exec @nErrorCode=sp_executesql @sSQLString,
		      		N'@nCurrentPeriodId	int,	
				@pnEntityNo		int',
				@nCurrentPeriodId	= @nCurrentPeriodId,
				@pnEntityNo		= @pnEntityNo

			
			
			If (@nErrorCode = 0)
			Begin
				If @pbDebug = 1
				Begin			
					Print 'Update the Trust Ledger opening balances for the next period from updated control total details'
				End
				
				Set @sSQLString = "UPDATE C
				SET TOTAL = CT1.BALANCE
				FROM CONTROLTOTAL C
				JOIN PERIOD P	ON (P.PERIODID = C.PERIODID)
				JOIN (SELECT SUM(ISNULL(TOTAL,0)) AS BALANCE, LEDGER, ENTITYNO, PERIODID  
					FROM CONTROLTOTAL CT
					WHERE CT.TYPE <> 9999 -- Closing Balance
					AND CT.CATEGORY <> 9 -- Equalise
					GROUP BY LEDGER, ENTITYNO, PERIODID  ) CT1	ON (CT1.LEDGER = C.LEDGER
											AND CT1.ENTITYNO = C.ENTITYNO
											AND CT1.PERIODID = @nCurrentPeriodId)
				WHERE C.LEDGER = 8
				AND C.CATEGORY = 99
				AND C.TYPE = 00 -- OPENING BALANCE
				AND C.PERIODID = @nNextPeriodId
				AND C.TOTAL <> CT1.BALANCE "
				
				If (@pnEntityNo is not NULL)
				Begin 
					Set @sSQLString = @sSQLString + "
					AND C.ENTITYNO = " + CAST(@pnEntityNo as NVARCHAR(11))
				End

				exec @nErrorCode=sp_executesql @sSQLString,
		      			N'@nCurrentPeriodId	int,	
		      			@nNextPeriodId		int,	
					@pnEntityNo		int',
					@nCurrentPeriodId	= @nCurrentPeriodId,
					@nNextPeriodId		= @nNextPeriodId,
					@pnEntityNo		= @pnEntityNo
				
				If @pbDebug = 1
				Begin
					print @sSQLString
				End
			End

			-- Now get the next PeriodId
			select @nCurrentPeriodId=min(PERIODID)
			from PERIOD
			where PERIODID>@nCurrentPeriodId
			AND POSTINGCOMMENCED IS NOT NULL
			
			SET @nNextPeriodId = NULL
		End
	End
End


Return @nErrorCode
GO

Grant execute on dbo.ac_ResetControlTotals to public
GO