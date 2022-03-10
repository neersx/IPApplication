/******************************************************************************************************************/
/*** RFC25316 Add Inprotech row in External Applications table for its integration with Inprotech Integration   ***/
/******************************************************************************************************************/
If not exists(Select 1 from ExternalApplications where Name = 'INPROTECH')
Begin
	Print '**** RFC25316 Adding data ExternalApplications.Name = INPROTECH'
	Insert into ExternalApplications(Name, Code, CreatedOn, CreatedBy)
	Values('INPROTECH', 'INPROTECH', getdate(), -1)
	Print '**** RFC25316 Data successfully added to ExternalApplication table.'
	Print ''
End
Else
	Print '**** RFC25316 ExternalApplications.Name = INPROTECH already exists'
	Print ''
Go