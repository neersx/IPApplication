-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ip_InstallCertificate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InstallCertificate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ip_InstallCertificate.'
	Drop procedure [dbo].[ip_InstallCertificate]
end
print '**** Creating Stored Procedure dbo.ip_InstallCertificate...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ip_InstallCertificate
With ENCRYPTION
AS
-- PROCEDURE :	ip_InstallCertificate
-- VERSION :	5
-- DESCRIPTION:	Certificates & Signatures is a method for controlling security access to database objects.  It limits
--		the users rights to stored procedure scope which can perform functions that the users don't have 
--		explicit rights to.  For instance users don't need to be granted rights to execute system 
--		stored procedures,  however the user is granted execute on a stored proc which calls system stored
--		proc.  
-- 
--		This stored proc contains encrypted scripts to create certificates and sign them against the required stored procedures for: 
--			- Sending db email with attachment 
--			- Background processing (e.g. policing, global name change, EDE...)
--			- Getting information about processes that are running on an instance of SQL Server
--			- Getting information about currently active lock manager resources in SQL Server
--
-- TEST SCRIPT: exec ip_InstallCertificate
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global
-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 03/11/2014	DL		R39102		1		Procedure created
-- 06/11/2017	DL		R72690		2		Running continuous policing on multiple databases on the same server
-- 07/12/2017	AK		R72645		3		Make compatible with case sensitive server with case insensitive database.
-- 21/01/2020	BS		DR-44505	4		Install certificate for fn_GetSysProcesses and fn_GetSysLockInformation.
-- 26/05/2020	BS		DR-53425	5		Install certificate for fn_GetSysActiveSessions.

BEGIN
	declare @sSql nvarchar(4000)		
	declare @sCertificate nvarchar(200)
	declare @sCertificateLogin nvarchar(200)

	---------------------------------------------------------------------------------------------------------
	-- Drop old certificate and login created previously with the old name format - i.e. without dbname affixed.
	---------------------------------------------------------------------------------------------------------

	-- drop signatures and certificate created previously with the old name format - i.e. without dbname affixed.
	If exists (select 1 from sys.certificates where name = 'Inprotech_Certificate_Builtin')
	Begin 
		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = 'Inprotech_Certificate_Builtin'
					and  sys.objects.name = 'ip_SendEmailViaCertificate')		
			DROP SIGNATURE FROM dbo.ip_SendEmailViaCertificate BY CERTIFICATE Inprotech_Certificate_Builtin;

		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = 'Inprotech_Certificate_Builtin'
					and  sys.objects.name = 'ipu_AsyncCommand')		
			DROP SIGNATURE FROM dbo.ipu_AsyncCommand BY CERTIFICATE Inprotech_Certificate_Builtin;
		
		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = 'Inprotech_Certificate_Builtin'
					and  sys.objects.name = 'fn_GetSysProcesses')		
			DROP SIGNATURE FROM dbo.fn_GetSysProcesses BY CERTIFICATE Inprotech_Certificate_Builtin;

		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = 'Inprotech_Certificate_Builtin'
					and  sys.objects.name = 'fn_GetSysLockInformation')		
			DROP SIGNATURE FROM dbo.fn_GetSysLockInformation BY CERTIFICATE Inprotech_Certificate_Builtin;

		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = 'Inprotech_Certificate_Builtin'
					and  sys.objects.name = 'fn_GetSysActiveSessions')		
			DROP SIGNATURE FROM dbo.fn_GetSysActiveSessions BY CERTIFICATE Inprotech_Certificate_Builtin;

		-- drop certificate
		drop CERTIFICATE Inprotech_Certificate_Builtin;
	End

	-- Drop the Certificate and login from the Master Database created previously with the old name format - i.e. without dbname affixed.
	Set @sSql = "
	USE [master]
	If exists (select 1 from sys.certificates where name = 'Inprotech_Certificate_Builtin')
	Begin
		If exists (select 1 from    
			sys.certificates c
			join sys.server_principals sp on sp.sid = c.sid
			where c.name = 'Inprotech_Certificate_Builtin')	
			Drop login [INPROTECH_CERTIFICATE]
			
		DROP CERTIFICATE [Inprotech_Certificate_Builtin] 
	End"
	exec (@sSql)

	-- Drop the certificate user from the MSDB Database created previously with the old name format - i.e. without dbname affixed.
	Set @sSql = "
	Use msdb
	If exists (select 1 from sys.sysusers su where su.name = 'INPROTECH_CERTIFICATE')
		DROP USER [INPROTECH_CERTIFICATE];
	" 
	exec (@sSql)


	---------------------------------------------------------------------------------------------------------
	-- Create new certificate with db name affixed.
	---------------------------------------------------------------------------------------------------------


	set @sCertificate  = 'Inprotech_Certificate_Builtin_' + db_name()
	set @sCertificateLogin  = 'INPROTECH_CERTIFICATE_' + db_name()

	-- create a temp table to hold cerficate name and login for accessing from the master database
	if exists(select * from tempdb.dbo.sysobjects where name = '##certificate_global_variables')
		drop table ##certificate_global_variables
	create table ##certificate_global_variables(certificate_name nvarchar(200), certificate_login nvarchar(200))
	insert into ##certificate_global_variables (certificate_name, certificate_login) values (@sCertificate, @sCertificateLogin)

	-- Create the certificate.  New certificate name has the dbname affixed.
	If not exists (select 1 from sys.certificates where name = @sCertificate)
	Begin 
		PRINT '**** SQA19181 create certificate ' + @sCertificate + ' on the Inpro database.'
		Set @sSql = "
		CREATE CERTIFICATE " + @sCertificate + " 
		ENCRYPTION BY PASSWORD = 'Certificate_1_InPr0Tech_Password'       
		WITH SUBJECT = 'Certificate for enabling use of Database Mail as well as Background processing and Server process information',  
		START_DATE = '2010-01-01',        
		EXPIRY_DATE = '2100-01-01'"

		exec (@sSql)
	End
	ELSE begin
		PRINT '*** drop and recreate the certificate'

		-- drop all signatures and certificate to recreate them
		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'ip_SendEmailViaCertificate')		
		Begin
			Set @sSql = "DROP SIGNATURE FROM dbo.ip_SendEmailViaCertificate BY CERTIFICATE " + @sCertificate
			exec (@sSql)
		End


		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'ipu_AsyncCommand')		
		Begin
			Set @sSql = "DROP SIGNATURE FROM dbo.ipu_AsyncCommand BY CERTIFICATE " + @sCertificate
			exec (@sSql)
		End

		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'fn_GetSysProcesses')		
		Begin
			Set @sSql = "DROP SIGNATURE FROM dbo.fn_GetSysProcesses BY CERTIFICATE " + @sCertificate
			exec (@sSql)
		End

		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'fn_GetSysLockInformation')		
		Begin
			Set @sSql = "DROP SIGNATURE FROM dbo.fn_GetSysLockInformation BY CERTIFICATE " + @sCertificate
			exec (@sSql)
		End

		If exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'fn_GetSysActiveSessions')		
		Begin
			Set @sSql = "DROP SIGNATURE FROM dbo.fn_GetSysActiveSessions BY CERTIFICATE " + @sCertificate
			exec (@sSql)
		End

		-- drop certificate
		set @sSql = "drop CERTIFICATE " + @sCertificate
		exec (@sSql)

		
		PRINT '**** SQA19181 create certificate ' + @sCertificate + ' on the Inpro database.'
		Set @sSql = "
		CREATE CERTIFICATE " + @sCertificate + " 
		ENCRYPTION BY PASSWORD = 'Certificate_1_InPr0Tech_Password'       
		WITH SUBJECT = 'Certificate for enabling use of Database Mail as well as Background processing and Server process information',     
		START_DATE = '2010-01-01',        
		EXPIRY_DATE = '2100-01-01'"
		exec (@sSql)
	end	

	-- enable xp_cmdshell to allow calling external commands like dos commands
	If exists (Select value from sys.configurations where name = 'xp_cmdshell' and value = 0)
	Begin
		exec sp_configure 'show advanced options', 1;
		RECONFIGURE;
		exec sp_configure 'xp_cmdshell', '1' 
		RECONFIGURE;

		-- create a dummy temp table to indicate that the xp_cmdshell option needs to be turned off before exit.
		if exists(select * from tempdb.dbo.sysobjects where name = '##certificate_cmdshell_enabled')
		    drop table ##certificate_cmdshell_enabled
		create table ##certificate_cmdshell_enabled(dummy int)
	End


	-- make a temp directory on the server for storing the certificate temporary
	EXEC xp_cmdshell 'md c:\temp' , no_output;

	-- delete the certificate backup file if exists
	exec xp_cmdshell 'del c:\temp\Inprotech_Certificate_Builtin.cer', no_output;

	-- Backup certificate so it can be create on the master database
	Set @sSql = "BACKUP CERTIFICATE " + @sCertificate + "
				TO FILE = 'c:\temp\Inprotech_Certificate_Builtin.CER'"
	exec (@sSql)


	Set @sSql = "
	USE [master]

	declare @sCertificate nvarchar(200)
	declare @sCertificateLogin nvarchar(200)

	-- Get the certificate name created on the inpro database
	select @sCertificate = certificate_name, @sCertificateLogin = certificate_login from ##certificate_global_variables

	-- Add the Certificate to Master Database
	If not exists (select 1 from sys.certificates where name = @sCertificate)
	Begin
		PRINT '**** SQA19181 create certificate " + @sCertificate + " on the master database.'

		CREATE CERTIFICATE " + @sCertificate + " 
		FROM FILE = 'c:\temp\Inprotech_Certificate_Builtin.CER';
	End
	ELSE Begin
		
		PRINT ''
		
		PRINT '**** drop and re-create certificate " + @sCertificate + " on the master database.'
		If exists (select 1 from    
			sys.certificates c
			join sys.server_principals sp on sp.sid = c.sid
			where c.name =  @sCertificate )
			Drop login " + @sCertificateLogin + ";
			
		DROP CERTIFICATE " + @sCertificate + " 

		CREATE CERTIFICATE " + @sCertificate + " 
		FROM FILE = 'c:\temp\Inprotech_Certificate_Builtin.CER';			
	End

	-- Create a login on the Master database from the certificate
	If not exists (select 1 from    
					sys.certificates c
					join sys.server_principals sp on sp.sid = c.sid
					where c.name = @sCertificate)
	Begin		
		PRINT '**** SQA19181 create a login " + @sCertificateLogin + " for the certificate on the master database.'
			
		CREATE LOGIN " + @sCertificateLogin + " 
		FROM CERTIFICATE " + @sCertificate + ";
	End

	-- Grant access to the certificate user
	-- The Login must have Authenticate Sever to access server scoped system tables
	GRANT AUTHENTICATE SERVER TO " + @sCertificateLogin + "
	
	GRANT VIEW SERVER STATE TO " + @sCertificateLogin

	exec (@sSql)

	-- delete the certificate backup
	exec xp_cmdshell 'del c:\temp\Inprotech_Certificate_Builtin.cer', no_output

	-- disable xp_cmdshell if it was initally disabled.
	If exists(select * from tempdb.dbo.sysobjects where name = '##testcertificate')
	Begin
		exec sp_configure 'xp_cmdshell', '0' 
		RECONFIGURE;
	    drop table ##certificate_cmdshell_enabled
	End


	-- create a user on the msdb database from the above login and add it to the DatabaseMailUserRole
	Set @sSql = "
	Use msdb

	declare @sCertificate nvarchar(200)
	declare @sCertificateLogin nvarchar(200)

	-- Get the certificate name created on the inpro database
	select @sCertificate = certificate_name, @sCertificateLogin = certificate_login from ##certificate_global_variables

	If not exists (select 1 from sys.sysusers su where su.name = @sCertificateLogin)
	Begin
		PRINT '**** SQA19181 create user on the msdb database for the login " + @sCertificateLogin + ".'

		Create USER " + @sCertificateLogin + " for login " + @sCertificateLogin + ";
		Exec sys.sp_addrolemember @rolename=DatabaseMailUserRole, @membername= '" + @sCertificateLogin + "' ;
	End	
	" 
	exec (@sSql)

	-- Finally sign the stored procedure(s), which sends emails, with the certificate.
	-- NOTE: The signature is required to be resigned if the stored procedure updated.  
	--		 Thefore it is safer to sign it when upgrade.
	If not exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'ip_SendEmailViaCertificate')
	Begin
		PRINT ''  
		PRINT '**** SQA19181 Sign the stored proc ip_SendEmailViaCertificate with the certificate ' + @sCertificate + '.'

		-- sign the proc
		Set @sSql = "ADD SIGNATURE TO OBJECT::[ip_SendEmailViaCertificate]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End
	Else Begin
		PRINT ''
		PRINT '**** SQA19181 Drop and resign the stored proc ip_SendEmailViaCertificate with the certificate ' + @sCertificate + '.'

		-- drop it first then...
		Set @sSql = "DROP SIGNATURE FROM dbo.ip_SendEmailViaCertificate BY CERTIFICATE " + @sCertificate
		exec (@sSql)

		-- resign the proc.
		Set @sSql = "ADD SIGNATURE TO OBJECT::[ip_SendEmailViaCertificate]
					BY CERTIFICATE " + @sCertificate + "
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End

	-- Sign stored procedure which activates background task to enable access to external database (e.g. logging on a different database) 
	If not exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'ipu_AsyncCommand')
	Begin  
		PRINT ''
		PRINT '**** SQA19181 Sign the stored proc ipu_AsyncCommand with the  certificate ' + @sCertificate + '.'

		-- sign the proc
		Set @sSql = "ADD SIGNATURE TO OBJECT::[ipu_AsyncCommand]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End
	Else Begin
		PRINT ''
		PRINT '**** SQA19181 Drop and resign the stored proc ipu_AsyncCommand with the certificate ' + @sCertificate + '.'

		-- drop it first then...
		Set @sSql = "DROP SIGNATURE FROM dbo.ipu_AsyncCommand BY CERTIFICATE " + @sCertificate
		exec (@sSql)

		-- resign the proc.
		Set @sSql = "ADD SIGNATURE TO OBJECT::[ipu_AsyncCommand]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End
	
	-- Sign stored procedure which gets information about processes that are running on an instance of SQL Server
	If not exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'fn_GetSysProcesses')
	Begin  
		PRINT ''
		PRINT '**** DR-44505 Sign the stored proc fn_GetSysProcesses with the  certificate ' + @sCertificate + '.'

		-- sign the proc
		Set @sSql = "ADD SIGNATURE TO OBJECT::[fn_GetSysProcesses]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End
	Else Begin
		PRINT ''
		PRINT '**** DR-44505 Drop and resign the stored proc fn_GetSysProcesses with the certificate ' + @sCertificate + '.'

		-- drop it first then...
		Set @sSql = "DROP SIGNATURE FROM dbo.fn_GetSysProcesses BY CERTIFICATE " + @sCertificate
		exec (@sSql)

		-- resign the proc.
		Set @sSql = "ADD SIGNATURE TO OBJECT::[fn_GetSysProcesses]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End

	-- Sign stored procedure which gets information about currently active lock manager resources in SQL Server 
	If not exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'fn_GetSysLockInformation')
	Begin  
		PRINT ''
		PRINT '**** DR-44505 Sign the stored proc fn_GetSysLockInformation with the  certificate ' + @sCertificate + '.'

		-- sign the proc
		Set @sSql = "ADD SIGNATURE TO OBJECT::[fn_GetSysLockInformation]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End
	Else Begin
		PRINT ''
		PRINT '**** DR-44505 Drop and resign the stored proc fn_GetSysLockInformation with the certificate ' + @sCertificate + '.'

		-- drop it first then...
		Set @sSql = "DROP SIGNATURE FROM dbo.fn_GetSysLockInformation BY CERTIFICATE " + @sCertificate
		exec (@sSql)

		-- resign the proc.
		Set @sSql = "ADD SIGNATURE TO OBJECT::[fn_GetSysLockInformation]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End

	-- Sign stored procedure which gets information about currently active lock manager resources in SQL Server 
	If not exists (  select sys.objects.name, sys.certificates.name
					from sys.certificates 
					inner join sys.crypt_properties  on sys.crypt_properties.thumbprint = sys.certificates.thumbprint
					left join sys.objects   on sys.objects.[object_id] = sys.crypt_properties.major_id
					where sys.certificates.name = @sCertificate
					and  sys.objects.name = 'fn_GetSysActiveSessions')
	Begin  
		PRINT ''
		PRINT '**** DR-53425 Sign the stored proc fn_GetSysActiveSessions with the  certificate ' + @sCertificate + '.'

		-- sign the proc
		Set @sSql = "ADD SIGNATURE TO OBJECT::[fn_GetSysActiveSessions]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End
	Else Begin
		PRINT ''
		PRINT '**** DR-53425 Drop and resign the stored proc fn_GetSysActiveSessions with the certificate ' + @sCertificate + '.'

		-- drop it first then...
		Set @sSql = "DROP SIGNATURE FROM dbo.fn_GetSysActiveSessions BY CERTIFICATE " + @sCertificate
		exec (@sSql)

		-- resign the proc.
		Set @sSql = "ADD SIGNATURE TO OBJECT::[fn_GetSysActiveSessions]
					BY CERTIFICATE " + @sCertificate + " 
					WITH PASSWORD = 'Certificate_1_InPr0Tech_Password'"
		exec (@sSql)
	End
	---- Remove the certificate to prevent it being signed to other tasks.
	If exists ( Select 1 from sys.certificates where sys.certificates.name = 'Inprotech_Certificate_Builtin' and pvt_key_encryption_type_desc <> 'NO_PRIVATE_KEY' )
	Begin
		ALTER CERTIFICATE Inprotech_Certificate_Builtin
		REMOVE PRIVATE KEY;
	End

	if exists(select * from tempdb.dbo.sysobjects where name = '##certificate_global_variables')
		drop table ##certificate_global_variables
END

GO
grant execute on dbo.ip_InstallCertificate   to public
go
