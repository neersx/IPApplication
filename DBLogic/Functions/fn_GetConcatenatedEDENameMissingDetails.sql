-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedEDENameMissingDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedEDENameMissingDetails') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedEDENameMissingDetails.'
	drop function dbo.fn_GetConcatenatedEDENameMissingDetails
	print '**** Creating function dbo.fn_GetConcatenatedEDENameMissingDetails...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedEDENameMissingDetails
	(
		@pnBatchNo		int,
		@psSeparator		nvarchar(10)
	)
Returns nvarchar(254)

-- FUNCTION :	fn_GetConcatenatedEDENameMissingDetails
-- VERSION :	2
-- DESCRIPTION:	This function accepts an EDE Batch and locates the Transactions 
--		that have not no name details.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 06 Oct 2006	vql 	12995	1	Function created
-- 14 Apr 2011	MF	10475	2	Change nvarchar(4000) to nvarchar(max)

AS
Begin
	Declare @sTransactionList	nvarchar(max)

	Select @sTransactionList=CASE WHEN(@sTransactionList is not null) 
				THEN @sTransactionList+@psSeparator+TRANSACTIONIDENTIFIER
				ELSE TRANSACTIONIDENTIFIER
			   END
	From EDEADDRESSBOOK
	Where BATCHNO =@pnBatchNo
	and   MISSINGNAMEDETAILS = 1
	order by TRANSACTIONIDENTIFIER

Return @sTransactionList
--Return substring(@sTransactionList,1,254)
End
go

grant execute on dbo.fn_GetConcatenatedEDENameMissingDetails to public
GO
