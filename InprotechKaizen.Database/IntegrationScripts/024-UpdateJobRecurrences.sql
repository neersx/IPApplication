PRINT '***** RFC45804 Updating job recurrences to new values ...'    
if exists (select 1 from dbo.[Jobs] WHERE [Type] = 'BackFillCorrelationId' AND [Recurrence] = 1)
BEGIN
    PRINT '***** RFC45804 - Updating BackFillCorrelationId job recurrence ...'
    UPDATE dbo.[Jobs] SET [Recurrence] = 60 WHERE [Type] = 'BackFillCorrelationId' AND [Recurrence] = 1
END
ELSE
BEGIN
    PRINT '***** RFC45624 - BackFillCorrelationId job does not exist...'
END
GO

