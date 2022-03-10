-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_Modules 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_Modules') and xtype='TF')
begin
	print '**** Drop function dbo.fn_Modules.'
	drop function dbo.fn_Modules
	print '**** Creating function dbo.fn_Modules...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_Modules(
	@pdtToday	datetime
)
RETURNS @tLicenseData TABLE
  (
        DATA 		nvarchar(254) collate database_default,
	PRICINGMODEL	int,
	MODULEID	int,
	MODULEUSERS	int,
	INTERNALUSE	tinyint, -- Needs to be int to allow sum() later
	EXTERNALUSE	tinyint
   )
With ENCRYPTION

-- FUNCTION :	fn_Modules
-- VERSION :	6
-- DESCRIPTION:	A minimal version of fn_LicenseData() to improve performance for
--		frequent access.  Decrypts less data, does not return MAXCASES or FIRMNAME, 
--		and does not test the checksum.
--		Also creates implied Administration licenses for external modules.  This
--		is done here to avoid the need to decrypt the license data again.
--		Note: the checksum is still tested when user first logs in.


-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 May 2005	JEK	RFC2594	1	Function created.
-- 11 Jul 2006	SW	RFC3828	2	EXPIRYDATE and EXPIRYACTION check.
-- 10 Nov 2009	CG	14697	3	Add collate database_default to temp table.
-- 17 Nov 2008	vql	16320	4	Cater for upgrading licences from Client Server to WorkBenches
-- 14 Sep 2009	DL	S18056	5	Add collate database_default to temp table.
-- 20 Jan 2014	vql	S30034	6	Correctly convert the expiry date.
as
Begin	
	-- Return anything that is not expired or warning action.
	Insert into @tLicenseData (DATA)
	select 	dbo.fn_Decrypt(SUBSTRING(LICENSE.DATA,1,34), 0)
	from 	LICENSE
		-- EXPIRYDATE >= @pdtToday
	where	CASE WHEN LEN( LTRIM( SUBSTRING( dbo.fn_Decrypt(DATA, 0),245,10) ) ) = 0 THEN @pdtToday
		     ELSE CONVERT( datetime, SUBSTRING( dbo.fn_Decrypt(DATA, 0),245,10), 126 )
		END >= @pdtToday
		-- EXPIRYACTION = 0 (Warning)
	or	CASE WHEN LEN( LTRIM( SUBSTRING( dbo.fn_Decrypt(DATA, 0), 255, 1) ) ) = 0 THEN NULL
		     ELSE CAST( SUBSTRING( dbo.fn_Decrypt(DATA, 0), 255, 1) as bit)
		END = 0

	Update @tLicenseData
	Set 	PRICINGMODEL 	= CAST( SUBSTRING(DATA, 8, 1) as int),
		MODULEID	= CAST( SUBSTRING(DATA, 19, 6) as int),
		MODULEUSERS	= CAST( SUBSTRING(DATA, 25, 10) as int),
		INTERNALUSE	= M.InternalUse,
		EXTERNALUSE	= M.ExternalUse
	from dbo.fn_ModuleDetails() M
	where M.ModuleID = CAST( SUBSTRING(DATA, 19, 6) as int)

	-- if client has module 28 convert it into a module 2 and module 21.
	If (select 1 from @tLicenseData where MODULEID = 28) = 1
	Begin
		Insert into @tLicenseData (PRICINGMODEL,MODULEID,MODULEUSERS,INTERNALUSE,EXTERNALUSE)
		select PRICINGMODEL,2,MODULEUSERS,INTERNALUSE,EXTERNALUSE from @tLicenseData where MODULEID = 28

		Insert into @tLicenseData (PRICINGMODEL,MODULEID,MODULEUSERS,INTERNALUSE,EXTERNALUSE)
		select PRICINGMODEL,21,MODULEUSERS,INTERNALUSE,EXTERNALUSE from @tLicenseData where MODULEID = 28
	End

	-- Add in implied Administrative license for any external modules
	Insert into @tLicenseData(PRICINGMODEL,MODULEID,MODULEUSERS,INTERNALUSE,EXTERNALUSE)
	Select 	1,
		MODULEID+500,
		-1,
		1 as INTERNALUSE, 
		0 as EXTERNALUSE
	from @tLicenseData
	where EXTERNALUSE = 1
	and   (PRICINGMODEL = 1 or		-- unlimited users
	       MODULEUSERS > 0)
			
	Return
End
go

grant REFERENCES, SELECT on dbo.fn_Modules to public
GO
