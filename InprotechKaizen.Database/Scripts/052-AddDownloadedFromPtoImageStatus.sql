If not exists (select * from TABLECODES where TABLECODE = -1102 AND TABLETYPE = 11)
Begin
	Print '**** R50906 - Adding Downloaded from PTO image status.'
	Insert into TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
	values (-1102, 11, 'Downloaded from PTO')
	Print '**** R50906 - Downloaded from PTO image status added.'
	Print ''
End
Else
Begin
	Print '**** R50906 - Downloaded from PTO image status already added.'
	Print ''
End
go

If not exists (select * from PROTECTCODES WHERE TABLECODE = -1102)
Begin
	Print '**** R50906 - Adding Downloaded from PTO image status to protected codes.'
	Insert into PROTECTCODES (PROTECTKEY, TABLECODE)
	select max(PROTECTKEY) + 1, -1102 from PROTECTCODES
	Print '**** R50906 - Downloaded from PTO image status added to protected codes.'
	Print ''
End
Else
Begin
	Print '**** R50906 - Downloaded from PTO image status already added to protected codes.'
	Print ''
End
go