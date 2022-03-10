-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ObjectLicense
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ObjectLicense') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fn_ObjectLicense'
	Drop function [dbo].[fn_ObjectLicense]
End
Print '**** Creating Function dbo.fn_ObjectLicense...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_ObjectLicense
(
	@pnObjectIntegerKey	int,	
	@pnObjectLevel int
) 

RETURNS TABLE
With ENCRYPTION
AS
-- Function :	fn_ObjectLicense
-- VERSION :	2
-- SCOPE :	WorkBenches
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given the object key and level return all licenses where object is available


-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Jun 08	SF	RFC6643	1	Function created
-- 02 Jul 08	MF/AT	RFC6643 2	Modified join conditions to be pre SQL2000 SP4 compatible

Return
	Select L.MODULEID
	from LICENSEMODULE L
	join MODULE M on (M.MODULEID = @pnObjectIntegerKey)
	join VALIDOBJECT VOB on (VOB.TYPE = @pnObjectLevel)
	where @pnObjectLevel = 10
	and L.MODULEID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3) as int) 
	and M.MODULEID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),4,10) as int)
	union
	Select L.MODULEID
	from LICENSEMODULE L
	join TASK T on (T.TASKID = @pnObjectIntegerKey)
	join VALIDOBJECT VOB on (VOB.TYPE = @pnObjectLevel)
	where @pnObjectLevel = 20
	and L.MODULEID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3) as int) 
	and T.TASKID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),4,10) as int)
GO

grant REFERENCES, SELECT on dbo.fn_ObjectLicense to public
go

