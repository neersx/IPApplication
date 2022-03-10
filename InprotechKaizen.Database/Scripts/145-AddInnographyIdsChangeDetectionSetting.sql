if not exists(select * from EXTERNALSETTINGS where PROVIDERNAME = 'InnographyId')
begin

	declare @since datetime

	select @since = DATEADD(Day, -1, min(LOGDATETIMESTAMP))
	from CPAGLOBALIDENTIFIER

	insert EXTERNALSETTINGS (PROVIDERNAME, SETTINGS, ISCOMPLETE)
	values ('InnographyId', convert(varchar(10), isnull(@since, GETUTCDATE()), 121), 1)

end
go