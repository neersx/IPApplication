
if not exists (select * 
				from SITECONTROLCOMPONENTS SC
				join SITECONTROL S on S.CONTROLID = 'Kind Codes For US Granted Patents' and S.ID = SC.SITECONTROLID
				join COMPONENTS C on COMPONENTNAME = 'x-obsolete' and SC.COMPONENTID = C.COMPONENTID)

begin
	-- obsoletion of 'Kind Codes For US Granted Patents' site control

	delete SC
	from SITECONTROLCOMPONENTS SC
	join SITECONTROL S on S.CONTROLID = 'Kind Codes For US Granted Patents' and S.ID = SC.SITECONTROLID

	insert SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
	select S.ID, C.COMPONENTID
	from SITECONTROL S 
	left join COMPONENTS C on COMPONENTNAME = 'x-obsolete'
	where S.CONTROLID = 'Kind Codes For US Granted Patents'
end
go