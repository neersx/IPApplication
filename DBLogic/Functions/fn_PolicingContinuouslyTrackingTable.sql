-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PolicingContinuouslyTrackingTable
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PolicingContinuouslyTrackingTable') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_PolicingContinuouslyTrackingTable'
	Drop function [dbo].[fn_PolicingContinuouslyTrackingTable]
End
Print '**** Creating Function dbo.fn_PolicingContinuouslyTrackingTable...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PolicingContinuouslyTrackingTable
(
	@pnQualifier nvarchar(20)
)
RETURNS nvarchar(100)
AS
-- Function :	fn_PolicingContinuouslyTrackingTable
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the name of the table to be used for tracking a policing continuous process 

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 JAN 2017	SF		DR21394	1		Function created

Begin
	-- double hash in middle to deliminate
	declare @q varchar(20)
	
	set @q = @pnQualifier;

	if (isnumeric(@pnQualifier)=1)
	begin
		set @q = cast(@pnQualifier as varchar(20))
	end

	return  '##policing_is_running_continuously_' + DB_NAME() + '##_' + @q
End
GO

grant execute on dbo.fn_PolicingContinuouslyTrackingTable to public
go
