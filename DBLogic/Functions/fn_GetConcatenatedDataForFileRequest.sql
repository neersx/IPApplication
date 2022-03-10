-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedDataForFileRequest
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedDataForFileRequest') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedDataForFileRequest.'
	drop function dbo.fn_GetConcatenatedDataForFileRequest
	print '**** Creating function dbo.fn_GetConcatenatedDataForFileRequest...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedDataForFileRequest
	(
		@pnRequestId		int,
		@psType                 nvarchar(10)
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetConcatenatedDataForFileRequest
-- VERSION :	2
-- DESCRIPTION:	This function accepts a RequestId, gets the data based on the RequestId 
--		and concatenates them with the Separator between each value.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 22/11/2011	MS 	R11208  1	Function created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

AS
Begin
        Declare @sReturnList	NVARCHAR(max)
        Declare @sNewLineChar   CHAR(2)
        Declare @sSeperator     CHAR(1)
        
        Set @sNewLineChar       = CHAR(13) + CHAR(10)
        Set @sSeperator         = ','

        If @psType = 'CASE' or @psType is null
        Begin
	        Select @sReturnList=nullif(@sReturnList + @sSeperator, @sSeperator)+ cast(CASEID as nvarchar(11))  
	        From RFIDFILEREQUESTCASES
	        Where REQUESTID  = @pnRequestId
	        order by CASEID
	End
	Else If @psType = 'DEVICE'
	Begin
	        Select @sReturnList=nullif(@sReturnList + @sNewLineChar, @sNewLineChar)+ R.DESCRIPTION  
	        From FILEREQASSIGNEDDEVICE FAD
	        join RESOURCE R on (R.RESOURCENO = FAD.RESOURCENO)
	        Where REQUESTID  = @pnRequestId
	        order by R.DESCRIPTION	
	End
	Else If @psType = 'STAFF'
	Begin
	        Select @sReturnList=nullif(@sReturnList + @sNewLineChar, @sNewLineChar)+ 
	                dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
	        From FILEREQASSIGNEDEMP FAE
	        join NAME N on (N.NAMENO = FAE.NAMENO)
	        Where REQUESTID  = @pnRequestId
	        order by N.[NAME]	
	End

Return @sReturnList
End
go

grant execute on dbo.fn_GetConcatenatedDataForFileRequest to public
GO
