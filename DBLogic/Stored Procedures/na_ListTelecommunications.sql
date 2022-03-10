----------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListTelecommunications
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListTelecommunications]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListTelecommunications'
	drop procedure [dbo].[na_ListTelecommunications]
	Print '**** Creating Stored Procedure dbo.na_ListTelecommunications...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create      PROCEDURE dbo.na_ListTelecommunications

-- PROCEDURE :	na_ListTelecommunications
-- VERSION :	5
-- DESCRIPTON:	Populate the Telecommnunication table in the NameDetails typed dataset.
--	 	Plus all the Telecommunication details of the names associated with the nameno.
-- CALLED BY :	

-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18/06/2002	SF			Procedure created	
-- 25/02/2004	TM	RFC867	5	Modify the logic extracting the 'Main Email' to use new Name.MainEmail column.

	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo			int
AS
begin
	-- disable row counts
	set nocount on
	set concat_null_yields_null off

	-- declare variables
	declare	@ErrorCode	int

	select @ErrorCode=0
	
	If @ErrorCode=0
	begin

		select 
		TELETYPE.DESCRIPTION	as 'DeviceTypeDescription',
		CASE 	WHEN TEL.ISD IS NOT NULL 
			THEN TEL.ISD + ' ' ELSE '' 
		END  +
		CASE 	WHEN TEL.AREACODE IS NOT NULL 
			THEN TEL.AREACODE  + ' ' ELSE '' 
		END +
		TEL.TELECOMNUMBER +
		CASE 	WHEN TEL.EXTENSION IS NOT NULL 
			THEN ' x' + TEL.EXTENSION ELSE '' 
		END			as 'DisplayTelecomNumber',
		CASE 
			WHEN TEL.TELECODE = N.MAINPHONE
			THEN 1	/* Main Phone */
			WHEN TEL.TELECODE = N.FAX
			THEN 2	/* Main Fax */
			WHEN TEL.TELECODE = N.MAINEMAIL
			THEN 3	/* Main Email */
		ELSE
			null	/* Undefined */
		END 			as 'TelecomTypeId'	
		from NAMETELECOM NT
		left join TELECOMMUNICATION TEL on (NT.TELECODE		= TEL.TELECODE)
		left join TABLECODES TELETYPE 	on (TEL.TELECOMTYPE	= TELETYPE.TABLECODE
						and TELETYPE.TABLETYPE 	= 19)

		left join NAME N		on (NT.NAMENO  		= N.NAMENO)
		
		where 	(NT.NAMENO 	= @pnNameNo )

		
	end
	RETURN @ErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_ListTelecommunications to public
go
