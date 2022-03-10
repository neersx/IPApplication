
/** DR-62616 New Due Date Calculation adjustment to 'Add 1 day' **/

IF NOT EXISTS ( SELECT 1 FROM [dbo].[ADJUSTMENT] WHERE [ADJUSTMENT] = N'1P')
BEGIN
	Print 'Adding "Plus 1 day" option to Adjustment table'
	INSERT INTO  [dbo].[ADJUSTMENT] ([ADJUSTMENT], [ADJUSTMENTDESC], [ADJUSTDAY], [ADJUSTMONTH], [ADJUSTYEAR], [ADJUSTAMOUNT], [PERIODTYPE]) 
	VALUES ( N'1P', N'Plus 1 day', NULL, NULL, NULL, 1, N'D' );
	Print 'Added "Plus 1 day" option to Adjustment table'
END
ELSE
BEGIN
	Print ' "Plus 1 day" option already exists.'
END
Go