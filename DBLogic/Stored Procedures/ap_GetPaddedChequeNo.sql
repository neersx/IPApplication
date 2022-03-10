-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_GetPaddedChequeNo stored procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ap_GetPaddedChequeNo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ap_GetPaddedChequeNo.'
	drop procedure dbo.ap_GetPaddedChequeNo
End
print '**** Creating procedure dbo.ap_GetPaddedChequeNo...'
print ''
go

CREATE PROCEDURE dbo.ap_GetPaddedChequeNo
(
	@psChequeNo 			nvarchar(30)	= null	output,
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null)
As
-- Procedure :	ap_GetPaddedChequeNo
-- VERSION :	2
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11/06/2003	CR	SQA8182	1	Created
-- 09 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

Begin
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @sChequeNo 	nvarchar(100),
		@ErrorCode	int,
		@nLength	int,
		@sPadding	char(1)

	SET @sChequeNo = @psChequeNo
	set @ErrorCode=0
	set @sPadding = '0'


		-- If the @sChequeNo is numeric then pad it with zeros to the 
		-- predefined length
		If isnumeric(@sChequeNo)=1
		Begin
			SELECT @nLength= S.COLINTEGER
			From SITECONTROL S
			Where S.CONTROLID='ChequeNo Length'

			SET @psChequeNo = CAST(dbo.fn_GetPaddedString(@sChequeNo, @nLength, @sPadding, 1) AS NVARCHAR(30))
		End

	SELECT  @psChequeNo

	SET	@pnRowCount=@@Rowcount
	SET	@ErrorCode=@@Error

	return @ErrorCode
End
GO

grant execute on dbo.ap_GetPaddedChequeNo to public
go
