	/******************************************************************************************************************/
	/*** Insert new Mapping row if inserted DataMap.SourceValue does not have corresponding Mapping.InputCodeID row.***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'ti_SynchroniseMapping')
	   begin
	    PRINT 'Refreshing trigger ti_SynchroniseMapping...'
	    DROP TRIGGER ti_SynchroniseMapping
	   end
	  go

	-- This trigger insert new Mapping row only if inserted DataMap.SourceValue does not have 
	-- corresponding Mapping.InputCodeID row whenever a new DATAMAP/DATAMAPs is inserted

	CREATE TRIGGER ti_SynchroniseMapping
		ON DATAMAP
		FOR INSERT NOT FOR REPLICATION AS
	
			Declare @nErrorCode 	int			
			
			Set @nErrorCode = 0

			insert into MAPPING (STRUCTUREID, INPUTCODEID, OUTPUTVALUE)
			Select EV.STRUCTUREID, EV.CODEID, i.MAPVALUE 
			FROM inserted i
			join MAPSTRUCTURE MS	on (MS.KEYCOLUMNAME = i.MAPCOLUMN
						and MS.TABLENAME = i.MAPTABLE)
			join ENCODEDVALUE EV 	on (EV.CODE = i.SOURCEVALUE
						and EV.STRUCTUREID = MS.STRUCTUREID
						and EV.SCHEMEID = -1)
			where not exists (Select 1
					  from MAPPING MP					  
					  where MP.DATASOURCEID is null
					  and   MP.INPUTCODEID = EV.CODEID  
					  and   MP.STRUCTUREID = EV.STRUCTUREID)

			Set @nErrorCode = @@Error
					  

			if @nErrorCode <> 0
			Begin
				Raiserror  ( 'Error %d inserting Mapping information', 16,1, @nErrorCode)
				Rollback
			End
	go
