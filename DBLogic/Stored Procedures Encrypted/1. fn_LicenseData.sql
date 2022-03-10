-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_LicenseData 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_LicenseData ') and xtype='TF')
begin
	print '**** Drop function dbo.fn_LicenseData .'
	drop function dbo.fn_LicenseData 
end
print '**** Creating function dbo.fn_LicenseData ...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_LicenseData()
RETURNS @tLicenseData TABLE
  (
        DATA 			nvarchar(268) collate database_default,
	PRICINGMODEL		int,
	MAXCASES		int,
	MODULEID		int,
	MODULEUSERS		int,
	FIRMNAME		nvarchar(210) collate database_default,
	EXPIRYDATE		datetime,
	EXPIRYACTION		bit,
	EXPIRYWARNINGDAYS	int
   )
With ENCRYPTION

-- FUNCTION :	fn_LicenseData 
-- VERSION :	7
-- DESCRIPTION:	Returns all the information about the license

-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 31 Aug 2004	TM	RFC1516	1	Function created
-- 11 Nov 2004	JEK	RFC869	2	Set parameter to request basic encryption
-- 29 May 2006	vql	11588	3	Create three extra column on temp table for expiry date information.
-- 10 Nov 2009	clg	14697	4	Add collate database_default to temp table
-- 17 Nov 2008	vql	16320	5	Cater for upgrading licences from Client Server to WorkBenches
-- 14 Sep 2009	DL	S18056 6	Add collate database_default to temp table.
-- 20 Jan 2014	vql	S30034 7	Correctly convert the expiry date.


as
Begin		
	Insert into @tLicenseData (DATA)
	select dbo.fn_Decrypt(DATA, 0) from LICENSE
	
	If (select TOP 1 len(DATA) from LICENSE) <= 254
	Begin
		Update @tLicenseData
		Set 	PRICINGMODEL 	= CAST( SUBSTRING(DATA, 8, 1) as int),
			MAXCASES 	= CAST( SUBSTRING(DATA, 9, 10) as int),
			MODULEID	= CAST( SUBSTRING(DATA, 19, 6) as int),
			MODULEUSERS	= CAST( SUBSTRING(DATA, 25, 10) as int),
			FIRMNAME 	=       SUBSTRING(DATA, 35, 210)
		where 	CAST( SUBSTRING(DATA, 245, 10) as int) = dbo.fn_GenCheckSum(SUBSTRING(DATA, 1, 244))   	
	End
	Else
	Begin
		Update @tLicenseData
		Set 	PRICINGMODEL 		= CAST( SUBSTRING(DATA, 8, 1) as int),
			MAXCASES 		= CAST( SUBSTRING(DATA, 9, 10) as int),
			MODULEID		= CAST( SUBSTRING(DATA, 19, 6) as int),
			MODULEUSERS		= CAST( SUBSTRING(DATA, 25, 10) as int),
			FIRMNAME 		=       SUBSTRING(DATA, 35, 210),
			EXPIRYDATE		= CASE WHEN LEN( LTRIM( SUBSTRING(DATA, 245, 10) ) ) = 0 THEN NULL
						  ELSE CONVERT( datetime, SUBSTRING(DATA, 245, 10), 126 ) END,
			EXPIRYACTION		= CASE WHEN LEN( LTRIM( SUBSTRING(DATA, 255, 1) ) ) = 0 THEN NULL
						  ELSE CAST( SUBSTRING(DATA, 255, 1) as bit) END,
			EXPIRYWARNINGDAYS	= CASE WHEN LEN( LTRIM( SUBSTRING(DATA, 256, 3) ) ) = 0 THEN NULL
						  ELSE CAST( SUBSTRING(DATA, 256, 3) as int) END
		where 	CAST( SUBSTRING(DATA, 259, 10) as int) = dbo.fn_GenCheckSum(SUBSTRING(DATA, 1, 258))
	End

	-- if client has module 28 convert it into a module 2 and module 21.
	If (select 1 from @tLicenseData where MODULEID = 28) = 1
	Begin
		Insert into @tLicenseData (PRICINGMODEL,MAXCASES,MODULEID,MODULEUSERS,FIRMNAME,EXPIRYDATE,EXPIRYACTION,EXPIRYWARNINGDAYS)
		select PRICINGMODEL,MAXCASES,2,MODULEUSERS,FIRMNAME,EXPIRYDATE,EXPIRYACTION,EXPIRYWARNINGDAYS from @tLicenseData where MODULEID = 28

		Insert into @tLicenseData (PRICINGMODEL,MAXCASES,MODULEID,MODULEUSERS,FIRMNAME,EXPIRYDATE,EXPIRYACTION,EXPIRYWARNINGDAYS)
		select PRICINGMODEL,MAXCASES,21,MODULEUSERS,FIRMNAME,EXPIRYDATE,EXPIRYACTION,EXPIRYWARNINGDAYS from @tLicenseData where MODULEID = 28
	End

	Return
End
go

grant REFERENCES, SELECT on dbo.fn_LicenseData  to public
GO
