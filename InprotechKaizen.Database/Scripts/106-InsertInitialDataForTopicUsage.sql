if not exists (select * from TOPICUSAGE)
begin

	print '**** R69865 Inserting data into TOPICUSAGE'

	insert into TOPICUSAGE (TOPICNAME, TOPICTITLE, [TYPE])
	select S.SCREENNAME, S.SCREENTITLE, S.SCREENTYPE
	from SCREENS S
	where S.SCREENNAME in (
		'frmText',
		'frmOfficialNo',
		'frmStandingInst',
		'frmRelationships',
		'frmInstructor',
		'frmNames',
		'frmNameGrp',
		'frmClasses',
		'frmCheckList',
		'frmDesignation',
		'frmOtherDetails',
		'frmRenewals')

	print '**** R69865 Data has been successfully added to TOPICUSAGE table.'
	print ''   
end
else
begin
	print '**** R69865 Data for TOPICUSAGE already exists.'
end
print ''
go
