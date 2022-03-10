declare @controlId nvarchar(50)='Inprotech Web Apps Version';

if not exists(select * from ConfigurationSettings where [Key]=@controlId)
	begin
		insert into ConfigurationSettings([Key], Value)  values(@controlId, '');
	end