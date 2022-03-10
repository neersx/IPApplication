set CONCAT_NULL_YIELDS_NULL ON
DECLARE @RC int
DECLARE @pnRowCount int
DECLARE @pnUserIdentityId int
DECLARE @psCulture nvarchar(10)
DECLARE @pnCaseKey int
DECLARE @pbIsUpdatedFromParent BIT
DECLARE @pbCalledFromCentura bit
SELECT @pnUserIdentityId = 5
SELECT @psCulture = 'pt-BR'
SELECT @pnCaseKey = 195
SELECT @pbCalledFromCentura = 0
EXEC @RC = [IPNet].[dbo].[csw_FetchDefaultCaseName] @pnRowCount OUTPUT , @pnUserIdentityId, @psCulture, @pnCaseKey,
N'<CaseNameData>
	<CaseNameDetails>
		<NameTypeCode>I</NameTypeCode>
		<NameKey>-493</NameKey>
		<AttentionKey>-486</AttentionKey>
		<AddressKey>-497</AddressKey>
	</CaseNameDetails>
	<CaseNameDetails>
		<NameTypeCode>EMP</NameTypeCode>
		<NameKey>3</NameKey>
		<AttentionKey></AttentionKey>
		<AddressKey></AddressKey>
	</CaseNameDetails>
</CaseNameData>', 
@pbCalledFromCentura,
@pbDebugFlag=0
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPNet.dbo.csw_FetchDefaultCaseName'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@pnRowCount = ' + isnull( CONVERT(nvarchar, @pnRowCount), '<NULL>' )
PRINT @PrnLine