-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [ipw_FetchDocItem] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_FetchDocItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[ipw_FetchDocItem].'
	drop procedure dbo.[ipw_FetchDocItem]
end
print '**** Creating procedure dbo.[ipw_FetchDocItem]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[ipw_FetchDocItem]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@psDocItem		nvarchar(40),
				@psEntryPoint		nvarchar(1000)    = null, -- CASE
				@psEntryPointP1		nvarchar(40)    = null, -- LANGUAGE
				@psEntryPointP2		nvarchar(40)    = null, --	DEBTOR NAME TYPE
				@psEntryPointP3		nvarchar(40)    = null, -- DEBTORNO
				@psEntryPointP4		nvarchar(40)    = null, -- OPENITEMNO
				@bIsCSVEntryPoint	bit             = null,
				@pbOutputToVariable	bit             = 0,
				@psOutputString		nvarchar(max)   = null output
				
as
-- PROCEDURE :	ipw_FetchDocItem
---- VERSION :	11
-- DESCRIPTION:	A procedure that returns a Doc Item
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 14-Oct-2009	AT	RFC3605		1	Procedure created
-- 29-Apr-2010	AT	RFC8292		2	Modified to cater for stored procedure doc items.
-- 16-Feb-2012	AT	RFC11307	3	Enable output to a return parameter.
-- 13-Jun-2012	LP	RFC12408	4	Prepend string to docitem query when setting output into a variable
-- 04-Mar-2013	DV	RFC13018	5	Fixed issue where the user was getting syntax error if the docitem query 
--									contained an ORDER BY clause
-- 14-Sep-2015  MS  RFC35248	6   Added @pnUserIdentityId and @psCulture in fetching docitem
-- 10-Oct-2015	DV	RFC53528	7	Fixed issue where DocItem from stored procedure containing userid and cuslture was not working
-- 05-Feb-2016	KR	R57619		8	Check if @pnUserIdentityId is null before replacing
-- 08 Apr 2016  MS  R52206          9       Addded fn_WrapQuotes for entry points to avoid sql injection
-- 24 Jul 2017  AK  R71993          10       Used fn_WrapQuotes properly for @psEntryPoint
-- 22-Aug-2017	MS	R72174		11	Increase length of parameter @psEntryPoint to 1000 from 40

set nocount on
set concat_null_yields_null off

Declare	@ErrorCode	int
Declare	@nRowCount	int
Declare	@sSQLString	nvarchar(max)
Declare	@sEntryPoint nvarchar(1000)
Declare	@nItemType	int

Set @ErrorCode = 0

If @pbOutputToVariable = 1
Begin
        CREATE TABLE #FETCHDOCITEM_OUTPUTTABLE (OUTPUTSTRING NVARCHAR(MAX) collate database_default)
End

If @ErrorCode = 0
Begin
	Set @sSQLString = "Select @nItemType = ITEM_TYPE
			From ITEM 
			Where ITEM_NAME = @psDocItem"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nItemType int OUTPUT,
				@psDocItem nvarchar(40)',
				@nItemType = @nItemType OUTPUT,
				@psDocItem = @psDocItem
End

If @ErrorCode = 0
Begin
	select @sSQLString = SQL_QUERY from ITEM WHERE ITEM_NAME = @psDocItem

	if (@bIsCSVEntryPoint = 1)
		Begin
			Set @sSQLString = replace(@sSQLString, "=:gstrEntryPoint", " in (:gstrEntryPoint)")
			Set @sSQLString = replace(@sSQLString, "= :gstrEntryPoint", " in (:gstrEntryPoint)")
			Set @sEntryPoint = 'select Parameter from dbo.fn_Tokenise(' + dbo.fn_WrapQuotes(ISNULL(@psEntryPoint,''),0,0)  + ','','')' 
						      
		End
	ELSE
		Begin
			Set @sEntryPoint = dbo.fn_WrapQuotes(ISNULL(@psEntryPoint,''),0,0)
		End      
        
	If @ErrorCode = 0 and @nItemType = 0
	Begin
               
            If @pnUserIdentityId is not null
				Set @sSQLString  = replace(@sSQLString,':gstrUserId',    dbo.fn_WrapQuotes(@pnUserIdentityId,0,0))
            If @psCulture is not null
				Set @sSQLString  = replace(@sSQLString,':gstrCulture',   dbo.fn_WrapQuotes(@psCulture,0,0))
	        else
		        Set @sSQLString  = replace(@sSQLString,':gstrCulture',   "''")
                
		Set @sSQLString = 
					replace(
						replace(
							replace(
								replace(
									replace(@sSQLString, ':gstrEntryPoint', @sEntryPoint)
								, ':p1', dbo.fn_WrapQuotes(ISNULL(@psEntryPointP1,''),0,0))
							, ':p2', dbo.fn_WrapQuotes(ISNULL(@psEntryPointP2,''),0,0))
						, ':p3', dbo.fn_WrapQuotes(ISNULL(@psEntryPointP3,''),0,0))
					, ':p4', dbo.fn_WrapQuotes(ISNULL(@psEntryPointP4,''),0,0)) 
                
		If (@pbOutputToVariable = 1)
		Begin
			Set @sSQLString = 'Select @psOutputString = (' + @sSQLString + ')'
		End
                
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOutputString nvarchar(max) output',
					@psOutputString = @psOutputString output
					
	End
        Else If @ErrorCode = 0 and @nItemType = 1 and @psEntryPoint is not null
        Begin
	        If @pbOutputToVariable = 0
	        Begin
		        exec @sSQLString @psEntryPoint,  -- IRN
				        @psEntryPointP1, -- @psLanguage
				        @psEntryPointP2, -- @psNameType 
				        @psEntryPointP3, -- @psDebtorNo
				        @psEntryPointP4	 -- @psOpenItemNo 

		        Set @ErrorCode = @@ERROR
	        End
	        Else
	        Begin
		        Begin try
			        insert into #FETCHDOCITEM_OUTPUTTABLE (OUTPUTSTRING)
			        exec @sSQLString @psEntryPoint,  -- IRN
				        @psEntryPointP1, -- @psLanguage
				        @psEntryPointP2, -- @psNameType 
				        @psEntryPointP3, -- @psDebtorNo
				        @psEntryPointP4	 -- @psOpenItemNo 
		        End try
		        Begin catch
			        insert into #FETCHDOCITEM_OUTPUTTABLE (OUTPUTSTRING)
			        values (cast(ERROR_NUMBER() as nvarchar(10)) + char(10) + ERROR_MESSAGE())
		        End catch

		        SELECT @psOutputString = @psOutputString + OUTPUTSTRING FROM #FETCHDOCITEM_OUTPUTTABLE

		        Drop table #FETCHDOCITEM_OUTPUTTABLE
	        End
        End
        Else If @ErrorCode = 0 and @nItemType = 1 and @psEntryPoint is null
        Begin
                Declare @sUserSQL nvarchar(max)

                Set @sUserSQL = @sSQLString

	        -----------------------------------------
	        -- Check if the stored procedure has a
	        -- parameter to accept the UserIdentityId
	        -----------------------------------------
	        If exists(select 1 from INFORMATION_SCHEMA.PARAMETERS 
	                  where SPECIFIC_NAME=@sUserSQL
	                  and ORDINAL_POSITION=1
	                  and DATA_TYPE='int')
		        Set @sSQLString=@sSQLString + ' ' +CAST(@pnUserIdentityId as nvarchar)
	
	        -----------------------------------------
	        -- Check if the stored procedure has a
	        -- parameter to accept the Culter
	        -----------------------------------------
	        If exists(select 1 from INFORMATION_SCHEMA.PARAMETERS 
	                  where SPECIFIC_NAME=@sUserSQL
	                  and ORDINAL_POSITION=2
	                  and DATA_TYPE='nvarchar') and @psCulture is not null
		        Set @sSQLString=@sSQLString + ', ' + dbo.fn_WrapQuotes(@psCulture,0,0)

                If @pbOutputToVariable = 0
	        Begin
                        exec (@sSQLString)
                End
                Else
	        Begin
		        Begin try
			        insert into #FETCHDOCITEM_OUTPUTTABLE (OUTPUTSTRING)
			        exec (@sSQLString)
		        End try
		        Begin catch
			        insert into #FETCHDOCITEM_OUTPUTTABLE (OUTPUTSTRING)
			        values (cast(ERROR_NUMBER() as nvarchar(10)) + char(10) + ERROR_MESSAGE())
		        End catch

		        SELECT @psOutputString = @psOutputString + OUTPUTSTRING FROM #FETCHDOCITEM_OUTPUTTABLE

		        Drop table #FETCHDOCITEM_OUTPUTTABLE
	        End
        End
End

return @ErrorCode
go

grant execute on dbo.[ipw_FetchDocItem]  to public
go