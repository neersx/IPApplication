if exists (select 1 from QUERYCOLUMN where COLUMNLABEL = 'DisplayNameCodeFlag')
Begin
	print 'updating QUERYCOLUMN.COLUMNLABEL to "Display Name Code Flag"'
	update QUERYCOLUMN set COLUMNLABEL = 'Display Name Code Flag' where COLUMNLABEL = 'DisplayNameCodeFlag'
	print 'updated QUERYCOLUMN.COLUMNLABEL to "Display Name Code Flag"'
End
Go