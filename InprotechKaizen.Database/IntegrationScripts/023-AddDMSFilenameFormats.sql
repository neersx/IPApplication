PRINT '***** RFC45624 Adding DMSIntegration filename formats ...'    
if not exists (select 1 from dbo.ConfigurationSettings where [Key] = 'DMSIntegration.PrivatePairFilenameFormat')
BEGIN
    PRINT '***** RFC45624 - Adding DMSIntegration private pair filename format ...'
    INSERT INTO dbo.ConfigurationSettings ([Key], [Value]) VALUES ('DMSIntegration.PrivatePairFilenameFormat', '{AN}-{CDT:yyyyMMddHHMMss}-{ID}.pdf')
END
ELSE
BEGIN
    PRINT '***** RFC45624 - DMSIntegration private pair filename format already exists...'
END
GO
if not exists (select 1 from dbo.ConfigurationSettings where [Key] = 'DMSIntegration.TsdrFilenameFormat')
BEGIN
    PRINT '***** RFC45624 - Adding DMSIntegration tsdr filename format ...'
    INSERT INTO dbo.ConfigurationSettings ([Key], [Value]) VALUES ('DMSIntegration.TsdrFilenameFormat', '{AN}-{CDT:yyyyMMddHHMMss}-{ID}.pdf')
END
ELSE
BEGIN
    PRINT '***** RFC45624 - DMSIntegration tsdr filename format already exists...'
END
GO
