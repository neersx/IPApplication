-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_TokeniseAddressLine
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_TokeniseAddressLine]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)

begin
	Print '**** Drop Stored Procedure dbo.ede_TokeniseAddressLine.'
	Drop procedure [dbo].[ede_TokeniseAddressLine]
end
Print '**** Creating Stored Procedure dbo.ede_TokeniseAddressLine...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE dbo.ede_TokeniseAddressLine 
		@psAddressList nvarchar(100)
AS
-- PROCEDURE :	ede_TokeniseAddressLine
-- VERSION :	2
-- DESCRIPTION:	Tokenise ADDRESS.STREET1 into multiple lines delimitted by carriage return.
--	Parameters:
--	- 	@psAddressList is a global table to contain the parsed addresses.  
--		The table structure includes ADDRESSCODE, STREET1 and SEQUENCENO columns.
--
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 12/01/2007	DL	12304	1	Procedure created
-- 13/06/2008	DL	16439	2	Split the address lines within this SP instead of using fn_tokenise to enhance performance.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

CREATE TABLE #TEMPADDRESS(
	ROWID 		int identity(1,1),
	ADDRESSCODE	int,
	STREET1		nvarchar(254) collate database_default
)


Declare 	@sSQLString 		nvarchar(4000),
		@nRowId			int,
		@nCaseId		int,
		@nErrorCode		int,
		@nNumberOfAddress	int,
		@sStreet1		nvarchar(254),
		@nAddressCode		int,
		@nSeq			int,
		@nFirstDelimiter	int,
		@sParsedAddressLine	nvarchar(254)



set @nRowId = 1
set @nErrorCode = 0


-- Load address.street1  for the list of address codes
If @nErrorCode = 0
Begin
	Set @sSQLString="
		Insert into #TEMPADDRESS ( ADDRESSCODE, STREET1)
		Select AL.ADDRESSCODE, A.STREET1
		from " + @psAddressList + " AL
		join ADDRESS A on (A.ADDRESSCODE = AL.ADDRESSCODE)"
	exec @nErrorCode=sp_executesql @sSQLString
	set @nNumberOfAddress = @@rowcount
End


-- clear the address table before inserting parsed address street1
If @nErrorCode = 0
Begin
	Set @sSQLString="
		Truncate table " + @psAddressList 
	exec @nErrorCode=sp_executesql @sSQLString
End


-- tokenise address.street1
If @nErrorCode = 0
Begin
	Set @nRowId = 1
	While (@nErrorCode = 0) and  (@nRowId <= @nNumberOfAddress)
	Begin
		Set @sSQLString="
			Select @sStreet1 = replace (STREET1, char(13)+char(10), char(27)),
			@nAddressCode = ADDRESSCODE
			from #TEMPADDRESS
			where ROWID = @nRowId
		"
		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@sStreet1		nvarchar(254) output,
		  @nAddressCode		int output, 	
		  @nRowId		int',
		  @sStreet1		= @sStreet1 output,
		  @nAddressCode		= @nAddressCode output,
		  @nRowId		= @nRowId		

--		Set @sSQLString="
--			Insert into " + @psAddressList + " (ADDRESSCODE, ADDRESSLINE, SEQUENCENUMBER)
--			Select @nAddressCode, TADDR.Parameter, TADDR.InsertOrder
--			from fn_Tokenise( @sStreet1, '^~^') TADDR
--		"
--		Exec @nErrorCode=sp_executesql @sSQLString,
--		N'@nAddressCode		int,
--		  @sStreet1				nvarchar(254)',
--		  @nAddressCode		= @nAddressCode,
--		  @sStreet1				= @sStreet1

		-- If the string does not end in a delimiter then insert one
		if @sStreet1 not like '%'+char(27)
			set @sStreet1 = @sStreet1+char(27)

		set @nSeq = 1
		While datalength(ltrim(@sStreet1))>0
		Begin
			set @nFirstDelimiter=patindex('%'+char(27)+'%',@sStreet1)
			set @sParsedAddressLine = rtrim(ltrim(substring(@sStreet1, 1, @nFirstDelimiter-1)))

			if datalength(ltrim(@sParsedAddressLine))>0 
			begin
				Set @sSQLString="
					Insert into " + @psAddressList + " (ADDRESSCODE, ADDRESSLINE, SEQUENCENUMBER)
					values( @nAddressCode, @sParsedAddressLine, @nSeq )
				"
				Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nAddressCode		int,
				  @sParsedAddressLine	nvarchar(254),
				  @nSeq int',
				  @nAddressCode		= @nAddressCode,
				  @sParsedAddressLine	= @sParsedAddressLine,
				  @nSeq			= @nSeq

				set @nSeq = @nSeq + 1
			end

			-- Now remove the parameter just extracted
			set @sStreet1=substring(@sStreet1,@nFirstDelimiter+1,4000)
		End

		-- process next address
		set @nRowId = @nRowId + 1

	End  -- end while loop
End


RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant execute on dbo.ede_TokeniseAddressLine to public
GO

