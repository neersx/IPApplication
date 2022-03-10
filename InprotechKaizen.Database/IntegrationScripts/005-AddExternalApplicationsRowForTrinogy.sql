/******************************************************************************************************************/
/*** RFC25316 Add Trinogy row in External Applications table for its integration with Inprotech			***/
/******************************************************************************************************************/
If not exists(Select 1 from ExternalApplications where Name = 'TRINOGY')
Begin
	Print '**** RFC25316 Adding data ExternalApplications.Name = TRINOGY'
	Insert into ExternalApplications(Name, Code, CreatedOn, CreatedBy)
	Values('TRINOGY', 'TRN', getdate(), -1)
	Print '**** RFC25316 Data successfully added to ExternalApplication table.'
	Print ''
End
Else
	Print '**** RFC25316 ExternalApplications.Name = TRINOGY already exists'
	Print ''
Go