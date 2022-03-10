-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FormatAddress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FormatAddress') and xtype='FN')
begin
	print '**** Drop function dbo.fn_FormatAddress.'
	drop function dbo.fn_FormatAddress
	print '**** Creating function dbo.fn_FormatAddress...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

set CONCAT_NULL_YIELDS_NULL off
go

Create Function dbo.fn_FormatAddress
			(
			@psStreet1		nvarchar(254),
			@psStreet2		nvarchar(254),
			@psCity			nvarchar(254),
			@psState		nvarchar(254),
			@psStateName		nvarchar(254),
			@psPostCode		nvarchar(254),
			@psCountry		nvarchar(254),
			@pnPostCodeFirst	tinyint,
			@pnStateAbbreviated	tinyint,	
			@psPostcodeLiteral 	nvarchar(254),
			@pnAddressStyle		int
			)
Returns nvarchar(254)

-- FUNCTION :	fn_FormatAddress
-- VERSION :	9
-- DESCRIPTION:	This function accepts the components of an address and returns
--		it as formatted text string.  Note that the Country may be passed
--		as NULL if you require the formatting to exclude the Country.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description 
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Mar 2002	MF			Function created
-- 28 Sep 2004	TM	RFC1806		Implemet new address style 7208 for the Chinese format.
-- 04 Jan 2005	MF	10671	6
-- 02 Jun 2005	TM	RFC2484	7	Check all the necessary parts of address before the formatting
--					and correct the @pnStateAbbreviated logic for 7207 address style.
-- 02 Jul 2008	MF	16635	8	Strip out address components that are either an empty string or only spaces.
-- 04 Aug 2008	MF	16761	9	Handle when components of Address are null.

as
Begin
	declare @sFormattedAddress	nvarchar(254)
	declare @sLine2			nvarchar(254)
	declare @sNextLine		nvarchar(3)

	Set @sNextLine=CHAR(13)+CHAR(10)

	----------------------------------------------------
	-- SQA16635
	-- Preprocessing to ensure that the input parameters
	-- are not empty strings or contain spaces only
	----------------------------------------------------
	if len(ltrim(rtrim(@psStreet1)))=0
		Set @psStreet1=NULL

	if len(ltrim(rtrim(@psStreet2)))=0
		Set @psStreet2=NULL

	if len(ltrim(rtrim(@psCity)))=0
		Set @psCity=NULL

	if len(ltrim(rtrim(@psState)))=0
		Set @psState=NULL

	if len(ltrim(rtrim(@psStateName)))=0
		Set @psStateName=NULL

	if len(ltrim(rtrim(@psPostCode)))=0
		Set @psPostCode=NULL

	if len(ltrim(rtrim(@psCountry)))=0
		Set @psCountry=NULL

	if len(ltrim(rtrim(@psPostcodeLiteral)))=0
		Set @psPostcodeLiteral=NULL

	-- The Address styles are hardcode values as follows :
	-- 7201        Post Code before City - Full State
	-- 7202        Post Code before City - Short State
	-- 7203        Post Code before City - No State
	-- 7204        City before PostCode - Full State
	-- 7205        City before PostCode - Short State
	-- 7206        City before PostCode - No State
	-- 7207        Country First, Postcode, Full State, City then Street
	-- 7208        [Country postal name] + [Full State] + [City] + [Street Address 1]
	--	       [PostcodeLiteral]: [Postcode]
	

	If @pnAddressStyle=7207
	begin
		-- Country first
		
		Select @sFormattedAddress= @psCountry

		if @psPostCode is not null		
		begin
			Select @sLine2= @psPostCode+' '
		end

		if (@pnStateAbbreviated=1
		and @psStateName is not null)
		or (@psState is not null
		and @pnStateAbbreviated<>1)
		begin
			Select @sLine2= ltrim(@sLine2)+CASE WHEN(@pnStateAbbreviated=1) THEN @psState ELSE @psStateName END+' '
		end

		Select @sLine2= ltrim(@sLine2)+@psCity
	
		If  @sFormattedAddress is not null
		and @sLine2            is not null
		begin
			Set @sFormattedAddress=@sFormattedAddress+@sNextLine+@sLine2
		end
		else If @sLine2 is not null
			Set @sFormattedAddress=@sLine2

		If  @sFormattedAddress is not null
		and @psStreet1         is not null
		begin
			Set @sFormattedAddress=@sFormattedAddress+@sNextLine+@psStreet1
		end
		Else If @psStreet1 is not null
			Set @sFormattedAddress=@psStreet1

		If  @sFormattedAddress is not null
		and @psStreet2         is not null
		begin
			Set @sFormattedAddress=@sFormattedAddress+@sNextLine+@psStreet2
		end
		Else If @psStreet2 is not null
			Set @sFormattedAddress=@psStreet2
	End	
	Else If @pnAddressStyle=7208 
	Begin
		-- [Country postal name] + [Full State] + [City] + [Street Address 1]
		-- [PostcodeLiteral]: [Postcode]
		
		If @psCountry is not null
		Begin
			Set @sFormattedAddress = @psCountry + ' '
		End

		If @psStateName is not null
		Begin
			Set @sFormattedAddress = @sFormattedAddress + @psStateName + ' '
		End

		If @psCity is not null
		Begin
			Set @sFormattedAddress = @sFormattedAddress + @psCity + ' ' 
		End
				
		If @psStreet1 is not null
		Begin
			Set @sFormattedAddress = @sFormattedAddress + @psStreet1
		End

		Set @sFormattedAddress = rtrim(@sFormattedAddress)

		if @psPostCode is not null
		begin
			Set @sLine2=@psPostcodeLiteral
		end

		If @sLine2 is not null
		and @psPostCode is not null
		Begin
			Set @sLine2=@sLine2 + ': ' + @psPostCode
		End
		Else If @sLine2 is null
		and @psPostCode is not null
		Begin
			Set @sLine2=@psPostCode
		End

		If  @sFormattedAddress is not null
		and @sLine2            is not null
		Begin
			Set @sFormattedAddress=@sFormattedAddress+@sNextLine+@sLine2
		End
		Else If @sLine2 is not null
		Begin
			Set @sFormattedAddress=@sLine2
		End
		
	End
	Else begin
		Select @sFormattedAddress=isnull(@psStreet1,'')

		If  @sFormattedAddress <> ''
		and @psStreet2          is not null
		begin
			Set @sFormattedAddress=@sFormattedAddress+@sNextLine+@psStreet2
		end

		If  @pnAddressStyle in (7201, 7202, 7203)
		OR (@pnAddressStyle is null and @pnPostCodeFirst=1)
		begin
			if @psPostCode is not null
			begin			
				Select @sLine2=@psPostCode+' '
			end

			if @psCity is not null
			begin
				Select @sLine2=ltrim(@sLine2)+@psCity+' '
			end
				
			If @sLine2 is not null
			begin
				If  @pnAddressStyle=7201  	-- full State
				OR (@pnAddressStyle is null and isnull(@pnStateAbbreviated,0)=0)
				begin
					If @psStateName is not null
					Begin
						Set @sLine2=ltrim(rtrim(@sLine2))+@sNextLine+@psStateName
					End
				end
				Else If(@pnAddressStyle=7202	-- abbreviated State
				OR (@pnAddressStyle is null and @pnStateAbbreviated=1))
				and @psState is not null
				begin
					Set @sLine2=@sLine2+@psState
				end
			end
			else begin
				If @pnAddressStyle=7201  	-- full State
				OR (@pnAddressStyle is null and isnull(@pnStateAbbreviated,0)=0)
				begin
					Set @sLine2=@psStateName
				end
				Else If @pnAddressStyle=7202	-- abbreviated State
				     OR (@pnAddressStyle is null and @pnStateAbbreviated=1)
				begin
					Set @sLine2=@psState
				end
			end
		end
		Else if  @pnAddressStyle in (7204, 7205, 7206)
		     OR (@pnAddressStyle is null and isnull(@pnPostCodeFirst,0)=0)
		begin
			If @psCity is not null 
			begin
				Select @sLine2=@psCity+' '
			end
	
			If @sLine2 is not null
			begin
				If  @pnAddressStyle=7204	-- full State
				OR (@pnAddressStyle is null and isnull(@pnStateAbbreviated,0)=0)
				begin
					If @psStateName is not null
						Set @sLine2=ltrim(rtrim(@sLine2))+@sNextLine+@psStateName
					else
						Set @sLine2=ltrim(rtrim(@sLine2))	

					If @psPostCode is not null
						Set @sLine2=ltrim(rtrim(@sLine2))+@sNextLine+@psPostCode
					
				end
				else If  @pnAddressStyle=7205	-- abbreviated State
				     OR (@pnAddressStyle is null and @pnStateAbbreviated=1)
				begin
					if @psState is not null
					begin
						Set @sLine2=@sLine2+@psState+' '
					end

					If @psPostCode is not null
						Set @sLine2=ltrim(@sLine2)+@psPostCode
					else
						Set @sLine2=ltrim(@sLine2)
				end
				else begin
					If @psPostCode is not null
						Set @sLine2=ltrim(@sLine2)+@psPostCode
					else
						Set @sLine2=ltrim(@sLine2)
				end
			end
			else begin
				If  @pnAddressStyle=7204  	-- full State
				OR (@pnAddressStyle is null and isnull(@pnStateAbbreviated,0)=0)
				begin
					Select @sLine2=@psStateName

					If  @psPostCode is not null
					begin
						If @sLine2 is not null
							Set @sLine2=@sLine2+@sNextLine+@psPostCode
						else
							Set @sLine2=@psPostCode
					end
				end
				Else If  @pnAddressStyle=7205	-- abbreviated State
				     OR (@pnAddressStyle is null and @pnStateAbbreviated=1)
				begin
					if @psState is not null
					begin
						Set @sLine2=@psState+' '
					end
					
					If @psPostCode is not null
						Set @sLine2=ltrim(isnull(@sLine2,''))+@psPostCode
					Else
						Set @sLine2=ltrim(@sLine2)
				end
				else begin
					Set @sLine2=@psPostCode
				end
			end
		end
	
		If @sLine2 is not null
		begin
			If  @sFormattedAddress = ''
				Set @sFormattedAddress=@sLine2
			else
				Set @sFormattedAddress=@sFormattedAddress+@sNextLine+@sLine2
		end
	
		If @psCountry is not null
		begin
			If  @sFormattedAddress = ''
				Set @sFormattedAddress=@psCountry
			else
				Set @sFormattedAddress=@sFormattedAddress+@sNextLine+@psCountry
		end
	end
	
	If @sFormattedAddress=''
		Set @sFormattedAddress=NULL

	Return ltrim(rtrim(@sFormattedAddress))
End
go

grant execute on dbo.fn_FormatAddress to public
GO
