--UPDATE DIARY SET WIPENTITYNO = NULL, TRANSNO=NULL WHERE TRANSNO >1059
DECLARE @RC int
DECLARE @pnRowsPosted int
DECLARE @pnIncompleteRows int
DECLARE @pnUserIdentityId int
DECLARE @psCulture nvarchar(10)
DECLARE @pbCalledFromCentura bit
DECLARE @pnDebugFlag tinyint
SELECT @pnRowsPosted = NULL
SELECT @pnIncompleteRows = NULL
SELECT @pnUserIdentityId = 5
SELECT @psCulture = NULL
SELECT @pbCalledFromCentura = 0
SELECT @pnDebugFlag = 2
EXEC @RC = [dbo].[ts_PostTime] @pnRowsPosted OUTPUT , @pnIncompleteRows OUTPUT , @pnUserIdentityId, @psCulture, @pbCalledFromCentura,
N'<?xml version="1.0"?>
<ts_PostTime>
	<WipEntityKey>24</WipEntityKey>
	<!-- All the filtering available via time search is also available here. -->
	<ts_ListDiary>
		<FilterCriteria>
			<!-- IsCurrentUser: use the name key of the current user. -->
		    <StaffKey Operator="" IsCurrentUser=""></StaffKey>
		    <EntryNo Operator=""></EntryNo>
			<!-- Use either DateRange or Period, not both. -->
			<EntryDate>
				<DateRange Operator="">
					<From></From>
					<To></To>
				</DateRange>
				<!-- Always searches dates in the past. -->
				<PeriodRange Operator="7">
					<!-- Type: D-Days,W–Weeks,M–Months,Y-Years -->
					<Type>W</Type>
					<!-- From, To: Use positive numbers. -->
					<From>1</From>
					<To></To>
				</PeriodRange>
			</EntryDate>
			<!-- Rows that match any of the EntryType booleans are returned. -->
			<EntryType>
				<IsUnposted>1</IsUnposted>
				<IsContinued>0</IsContinued>
				<IsIncomplete>1</IsIncomplete>
				<IsPosted>0</IsPosted>
				<IsTimer>0</IsTimer>
			</EntryType>
			<!-- Explicitly select/deselect entry dates.
				 Operator may have value 0 - include or 1 - exclude.
				 Date may repeat. -->
			<EntryDateGroup Operator="">
				<Date></Date>
			</EntryDateGroup>
		</FilterCriteria>
	</ts_ListDiary>
</ts_PostTime>', 
@pnDebugFlag
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPNet.dbo.ts_PostTime'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pnRowsPosted = ' + isnull( CONVERT(nvarchar, @pnRowsPosted), '<NULL>' )
PRINT @PrnLine
SELECT @PrnLine = '		@pnIncompleteRows = ' + isnull( CONVERT(nvarchar, @pnIncompleteRows), '<NULL>' )
PRINT @PrnLine