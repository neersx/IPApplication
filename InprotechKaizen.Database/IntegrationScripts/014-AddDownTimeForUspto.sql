	If NOT exists (SELECT * from DataSourceAvailability where Source = 0)
		BEGIN

			INSERT DataSourceAvailability (Source, UnavailableDays, StartTime, EndTime, Timezone)
			values (0, 'Sun,Mon,Tue,Wed,Thu,Fri,Sat', '04:30', '05:30', 'Eastern Standard Time')
		END
	go 

	If NOT exists (SELECT * from DataSourceAvailability where Source = 1)
		BEGIN

			INSERT DataSourceAvailability (Source, UnavailableDays, StartTime, EndTime, Timezone)
			values (1, 'Sun,Mon,Tue,Wed,Thu,Fri,Sat', '04:30', '05:30', 'Eastern Standard Time')
		END
	go 	