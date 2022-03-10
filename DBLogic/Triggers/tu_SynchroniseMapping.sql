if exists (select * from sysobjects where type='TR' and name = 'tu_SynchroniseMapping')
begin
	PRINT 'Refreshing trigger tu_SynchroniseMapping...'
	DROP TRIGGER tu_SynchroniseMapping
end
go 

CREATE TRIGGER tu_SynchroniseMapping ON DATAMAP
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tu_SynchroniseMapping  
-- VERSION:	2
-- DESCRIPTION:	This trigger inserts/updates Mapping as required. 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	Declare @nErrorCode 	int			
				
	Set @nErrorCode = 0

	-- If Mapping.InputCodeID already exists on the Mapping table then 
	-- the script will update corresponding Mapping.OutputValue if required.
	
	Update  MAPPING 
	Set 	OUTPUTVALUE	= i.MAPVALUE 
	from MAPPING MP
	join ENCODEDVALUE EV	on (EV.CODEID = MP.INPUTCODEID
				and MP.STRUCTUREID = EV.STRUCTUREID
				and EV.SCHEMEID = -1)					  
	join MAPSTRUCTURE MS	on (MS.STRUCTUREID = EV.STRUCTUREID)
	join inserted i		on (i.MAPCOLUMN = MS.KEYCOLUMNAME
				and i.MAPTABLE = MS.TABLENAME
				and i.SOURCEVALUE = EV.CODE)
	where MP.DATASOURCEID is null
	and exists(select 1 
	      	  from deleted d 
		  where  d.MAPNO 	=  i.MAPNO
		  and    d.SOURCEVALUE 	=  i.SOURCEVALUE
		  and    d.MAPTABLE	=  i.MAPTABLE
		  and    d.MAPCOLUMN 	=  i.MAPCOLUMN 					
		  and    d.MAPVALUE	<> i.MAPVALUE)
	
	Set @nErrorCode = @@Error

	if @nErrorCode = 0
	Begin
		-- If Mapping.InputCodeID does not exists on the Mapping table then 
		-- new row will be inserted into the Mapping table for the Mapping. 
		insert into MAPPING (STRUCTUREID, INPUTCODEID, OUTPUTVALUE)
		Select EV.STRUCTUREID, EV.CODEID, i.MAPVALUE 
		FROM inserted i
		join MAPSTRUCTURE MS	on (MS.KEYCOLUMNAME = i.MAPCOLUMN
					and MS.TABLENAME = i.MAPTABLE)
		join ENCODEDVALUE EV 	on (EV.CODE = i.SOURCEVALUE
					and EV.STRUCTUREID = MS.STRUCTUREID
					and EV.SCHEMEID = -1)
		where not exists (Select 1
				  from  MAPPING MP					  
				  where MP.DATASOURCEID is null
				  and   MP.INPUTCODEID = EV.CODEID  
				  and   MP.STRUCTUREID = EV.STRUCTUREID)				

		Set @nErrorCode = @@Error
	End

	if @nErrorCode <> 0
	Begin
		Raiserror  ( 'Error %d updating Mapping information', 16,1, @nErrorCode)
		Rollback
	End
End
go


