-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetFileRequestItems
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetFileRequestItems') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetFileRequestItems.'
	drop function dbo.fn_GetFileRequestItems
	print '**** Creating function dbo.fn_GetFileRequestItems...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetFileRequestItems
	(
		@pnRequestId		int,
		@psType                 nvarchar(10) -- 0 for Has RFID Items, 1 for All file items delivered
	)
Returns bit

-- FUNCTION :	fn_GetFileRequestItems
-- VERSION :	1
-- DESCRIPTION:	This function returns the data regarding whether the file request has RFID Items or not
--              and whether all the file parts of the given request has been delivered

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 22/11/2011	MS 	R11208  1	Function created

AS
Begin
        Declare @bHasValue	                bit
        DECLARE @nCount                         int
        DECLARE @nDeliveredItemsCount           int

        Set @bHasValue                          = 0
        SET @nCount                             = 0
        SET @nDeliveredItemsCount               = 0


        If @psType = '0' or @psType is null -- Has RFID Items
        Begin
                SELECT @bHasValue = CASE WHEN count(FPR.FILEPART) > 0 THEN 1 ELSE 0 END
	        FROM FILEPARTREQUEST FPR
                JOIN FILEPART FP on (FP.CASEID = FPR.CASEID and FP.FILEPART = FPR.FILEPART)
                WHERE REQUESTID=@pnRequestId
                and FP.RFID is not null and RTRIM(FP.RFID) <> ''
	End
	Else If @psType = '1' -- Are all items delivered i.e. all the file parts have search status = 'PICKED' and Request is still not processed.
	Begin
	        SELECT @nCount = Count(FILEPART) 
	        FROM FILEPARTREQUEST 
	        WHERE REQUESTID = @pnRequestId
	        
	        SELECT @nDeliveredItemsCount = count(FILEPART)
		FROM  FILEPARTREQUEST FP
		JOIN RFIDFILEREQUEST RF on (RF.REQUESTID = FP.REQUESTID)
                WHERE RF.REQUESTID=@pnRequestId
                AND FP.SEARCHSTATUS = 1
                AND RF.STATUS not in (2,3)
                        
                If @nDeliveredItemsCount > 0 and @nCount = @nDeliveredItemsCount       
                Begin
                        Set @bHasValue = 1
                End  
	End

Return @bHasValue
End
go

grant execute on dbo.fn_GetFileRequestItems to public
GO
