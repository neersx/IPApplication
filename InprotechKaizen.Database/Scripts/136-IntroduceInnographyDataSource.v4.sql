if not exists (select * from EXTERNALSYSTEM where SYSTEMID = -5 and SYSTEMCODE = 'Innography')
begin	
	insert EXTERNALSYSTEM (SYSTEMID, SYSTEMNAME, SYSTEMCODE, DATAEXTRACTID)
	values (-5, 'Innography', 'Innography', null)
end
go

if not exists (select * from DATAEXTRACTMODULE where SYSTEMID = -5 and DATAEXTRACTID = 5)
begin
	insert DATAEXTRACTMODULE (DATAEXTRACTID, SYSTEMID, EXTRACTNAME)
	values (5, -5, 'Innography')
end
go

---------------------------------
-- Add Data Source --
---------------------------------

if not exists (select * from DATASOURCE where DATASOURCEID = -5 and SYSTEMID = -5 and DATASOURCECODE = 'Innography')
begin
    set identity_insert DATASOURCE on

	insert DATASOURCE (DATASOURCEID, SYSTEMID, ISPROTECTED, DATASOURCECODE)
	values (-5, -5, 1, 'Innography')

	set identity_insert DATASOURCE off
end
go

---------------------------------
-- Add Map Scenario -Events  --
---------------------------------

if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 5 and MS.SYSTEMID = -5 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-5, 5, -3, 1)
end
go

---------------------------------
-- Add Map Scenario -Name Type --
---------------------------------

if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 2 and MS.SYSTEMID = -5 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-5, 2, -3, 0)
end
go

---------------------------------
-- Add Map Scenario -Number Type --
---------------------------------

if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 1 and MS.SYSTEMID = -5 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-5, 1, -3, 0)
end
go

---------------------------------
-- Add Map Scenario -Country --
---------------------------------

if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 4 and MS.SYSTEMID = -5 and MS.SCHEMEID = -2)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-5, 4, -2, 0)
end
go

----------------------------------
-- All Patents --
----------------------------------

if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'P') and
	not exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'P' and DATAEXTRACTID = 5)
begin
	declare @next int
	select @next = max(CRITERIANO)+1
	from CRITERIA 

	insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
	values ('D', 'A', 'P', 0, 1, 'Innography for Patents', 5, @next)
	
	update	LASTINTERNALCODE 
	set		INTERNALSEQUENCE = @next
	where TABLENAME = 'CRITERIA'
end
go

----------------------------------
-- All Designs --
----------------------------------

if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'D') and
	not exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'D' and DATAEXTRACTID = 5)
begin
	declare @next int
	select @next = max(CRITERIANO)+1
	from CRITERIA 

	insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
	values ('D', 'A', 'D', 0, 1, 'Innography for Designs', 5, @next)
	
	update	LASTINTERNALCODE 
	set		INTERNALSEQUENCE = @next
	where TABLENAME = 'CRITERIA'
end
go

----------------------------------
-- All Innovation Patents around the world --
----------------------------------

if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'N') and
	not exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'N' and DATAEXTRACTID = 5)
begin
	declare @next int
	select @next = max(CRITERIANO)+1
	from CRITERIA 

	insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
	values ('D', 'A', 'N', 0, 1, 'Innography for Innovation Patents', 5, @next)
	
	update	LASTINTERNALCODE 
	set		INTERNALSEQUENCE = @next
	where TABLENAME = 'CRITERIA'
end
go

---------------------------------------
-- All Utility Models / Petty Patents --
---------------------------------------

if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'U') and
	not exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'U' and DATAEXTRACTID = 5)
begin
	declare @next int
	select @next = max(CRITERIANO)+1
	from CRITERIA 

	insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
	values ('D', 'A', 'U', 0, 1, 'Innography for Utility Models / Petty Patents', 5, @next)
	
	update	LASTINTERNALCODE 
	set		INTERNALSEQUENCE = @next
	where TABLENAME = 'CRITERIA'
end
go

---------------------------------------
-- All Plant Variety Rights --
---------------------------------------

if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'V') and
	not exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'V' and DATAEXTRACTID = 5)
begin
	declare @next int
	select @next = max(CRITERIANO)+1
	from CRITERIA 

	insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
	values ('D', 'A', 'V', 0, 1, 'Innography for Plant Variety Rights', 5, @next)
	
	update	LASTINTERNALCODE 
	set		INTERNALSEQUENCE = @next
	where TABLENAME = 'CRITERIA'
end
go

----------------------------------
-- All Trademarks --
----------------------------------

if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'T') and
	not exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'T' and DATAEXTRACTID = 5)
begin
	declare @next int
	select @next = max(CRITERIANO)+1
	from CRITERIA 

	insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
	values ('D', 'A', 'T', 0, 1, 'Innography for Trademarks', 5, @next)
	
	update	LASTINTERNALCODE 
	set		INTERNALSEQUENCE = @next
	where TABLENAME = 'CRITERIA'
end
go
