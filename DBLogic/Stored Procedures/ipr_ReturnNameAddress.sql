-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_ReturnNameAddress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_ReturnNameAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_ReturnNameAddress.'
	drop procedure dbo.ipr_ReturnNameAddress
end
print '**** Creating procedure dbo.ipr_ReturnNameAddress...'
print ''
go

create procedure dbo.ipr_ReturnNameAddress
	@pnNameNo int,
	@pbIncludeAttention int
as
-- PROCEDURE :	ipr_ReturnNameAddress
-- VERSION :	2.1.0
-- DESCRIPTION:	Format the Name, Attention (optional) and Postal Address into a single string separated by Carriage 
-- 		Returns for use as the return name & address to place on correspondence.
-- 		Note the address always contains the country.
-- CALLED BY :	

-- Date		USER	SQA#	MODIFICTION HISTORY
-- ====         ====	====	===================
-- 11/07/2001 	AvdA	6730 	NameAddress formatting
-- 07/10/2003	AB	8394	Add dbo. to create procedure
-- 14/10/2003	AB	8394	Modify drop statement to work for non existing circumstance.

DECLARE @nAttention INT, @nAddress INT,
	@sClientName varchar(254), @sAttention varchar(254),
	@sAddress varchar(254), @sNameWhere varchar(25)

IF @pnNameNo IS NULL
	RETURN
ELSE
	BEGIN
	EXEC ipo_FormatName @pnNameNo = @pnNameNo, @prsFormattedName = @sClientName OUTPUT
	select @nAttention = MAINCONTACT, @nAddress = POSTALADDRESS
		from NAME
		where NAMENO = @pnNameNo
	If ( (@pbIncludeAttention = 1) AND
	     (@nAttention IS NOT NULL) )
		BEGIN
		EXEC ipo_FormatName @pnNameNo = @nAttention, @prsFormattedName = @sAttention OUTPUT
		END
	Else
		BEGIN
		Select @sAttention = NULL
		END
	EXEC ipo_FormatReturnAddress @pnAddressCode = @nAddress, @prsFormattedAddress = @sAddress OUTPUT 

	--Find where the country usually puts the name (before or after the address)
	select @sNameWhere = USERCODE 
	from ADDRESS A, COUNTRY CT,  TABLECODES ADS
	where A.COUNTRYCODE = CT.COUNTRYCODE
	and ADS.TABLECODE = CT.ADDRESSSTYLE 
	and ADS.TABLETYPE = 72 
	and A.ADDRESSCODE = @nAddress 

	select convert( varchar(254),  CASE 
		WHEN @sNameWhere = 'NameBefore'
			THEN 
			CASE WHEN @sClientName IS NOT NULL THEN @sClientName + char(13) + char(10) END
			+ CASE WHEN @sAttention IS NOT NULL THEN @sAttention + char(13) + char(10) END
			+ @sAddress
		WHEN @sNameWhere = 'NameAfter'	
			THEN
			CASE WHEN @sAddress IS NOT NULL THEN @sAddress + char(13) + char(10) END
			+ CASE WHEN @sAttention IS NOT NULL THEN @sAttention + char(13) + char(10) END
			+ @sClientName  
		END)

	END

Return 0
GO

grant execute on dbo.ipr_ReturnNameAddress TO public
GO
