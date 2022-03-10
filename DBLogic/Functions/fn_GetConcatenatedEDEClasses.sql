-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedEDEClasses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedEDEClasses') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedEDEClasses.'
	drop function dbo.fn_GetConcatenatedEDEClasses
	print '**** Creating function dbo.fn_GetConcatenatedEDEClasses...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedEDEClasses
	(
		@pnBatchNo		int,
		@psTransId		nvarchar(50),
		@psClassType		nvarchar(50),
		@psSeparator		nvarchar(10)
	)
Returns nvarchar(254)

-- FUNCTION :	fn_GetConcatenatedEDEClasses
-- VERSION :	4
-- DESCRIPTION:	This function accepts an EDE Transaction and locates the Classes
--		contained as separate rows and concatenates them together with a
--		user specified separator.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 06 Oct 2006	MF 	12413	1	Function created
-- 08 Sep 2009	MF	18014	2	Exclude a class number with the value of 'and'
-- 14 Apr 2011	MF	10475	3	Change nvarchar(4000) to nvarchar(max)
-- 14 Sep 2015	MF	51926	4	When CLASSNUMBER is a single non zero digit then concatenate a leading zero.

AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sClassList	nvarchar(max)

	Select @sClassList=CASE WHEN(@sClassList is not null) 
				THEN @sClassList+@psSeparator+CASE WHEN(isnumeric(CLASSNUMBER)=1)
									THEN CASE WHEN(CAST(CLASSNUMBER as NUMERIC) between 1 and 9)
										THEN '0'+cast(cast(CLASSNUMBER as tinyint) as char(1))
										ELSE CLASSNUMBER
									     END
									ELSE CLASSNUMBER
							       END
				ELSE CASE WHEN(isnumeric(CLASSNUMBER)=1)
						THEN CASE WHEN(CAST(CLASSNUMBER as NUMERIC) between 1 and 9)
							THEN '0'+cast(cast(CLASSNUMBER as tinyint) as char(1))
							ELSE CLASSNUMBER
						     END
						ELSE CLASSNUMBER
				     END
			   END
	From EDECLASSDESCRIPTION C
	Where C.BATCHNO =@pnBatchNo
	and   C.TRANSACTIONIDENTIFIER=@psTransId
	and   C.CLASSIFICATIONTYPECODE=@psClassType
	and   C.CLASSNUMBER not in ('and')

	-- replace the word "and" with a comma and remove embedded spaces
	Set @sClassList=replace(replace(@sClassList,'and',','),' ','')

Return substring(@sClassList,1,254)
End
go

grant execute on dbo.fn_GetConcatenatedEDEClasses to public
GO
