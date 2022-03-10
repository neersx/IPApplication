-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetAlertXML
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetAlertXML') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetAlertXML.'
	drop function dbo.fn_GetAlertXML
end
print '**** Creating function dbo.fn_GetAlertXML...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET CONCAT_NULL_YIELDS_NULL OFF
GO

CREATE  FUNCTION dbo.fn_GetAlertXML
(
	@psAlertID nvarchar(10),
	@psMessage nvarchar(254),
	@psSubstitute0 nvarchar(254)=null,
	@psSubstitute1 nvarchar(254)=null,
	@psSubstitute2 nvarchar(254)=null,
	@psSubstitute3 nvarchar(254)=null,
	@psSubstitute4 nvarchar(254)=null
)

RETURNS nvarchar(400)
AS

-- FUNCTION:	fn_GetAlertXML
-- VERSION :	4
-- DESCRIPTION:	Returns an Alert request formatted as XML
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 07 Mar 2003	JEK	1	RFC82 Localise SP errors
-- 20 Mar 2003	JEK	2	Handle null @psMessage
-- 10 Sep 2003  AB	3	Remove SET ANSI_NULLS OFF (SQA 9222)
-- 22 Jun 2005	JEK	4	Make <Message> the last element.  Limit total lenght to 400 characters.

BEGIN

	Declare @sXML 		as nvarchar(400)
	Declare @nLenght 	as int

	set @sXML = 	'<Alert>'+char(10)+
			char(9)+ '<AlertID>' + @psAlertID + '</AlertID>' +char(10)
			
	if (@psSubstitute0 is not null) and
	   (@psSubstitute0 != '')
	begin
		set @sXML = @sXML +
			char(9)+ '<Substitute>' + @psSubstitute0 + '</Substitute>' +char(10)
	end

	if (@psSubstitute1 is not null) and
	   (@psSubstitute1 != '')
	begin
		set @sXML = @sXML +
			char(9)+ '<Substitute>' + @psSubstitute1 + '</Substitute>' +char(10)
	end

	if (@psSubstitute2 is not null) and
	   (@psSubstitute2 != '')
	begin
		set @sXML = @sXML +
			char(9)+ '<Substitute>' + @psSubstitute2 + '</Substitute>' +char(10)
	end

	if (@psSubstitute3 is not null) and
	   (@psSubstitute3 != '')
	begin
		set @sXML = @sXML +
			char(9)+ '<Substitute>' + @psSubstitute3 + '</Substitute>' +char(10)
	end

	if (@psSubstitute4 is not null) and
	   (@psSubstitute4 != '')
	begin
		set @sXML = @sXML +
			char(9)+ '<Substitute>' + @psSubstitute4 + '</Substitute>' +char(10)
	end

	if (@psMessage is not null) and
	   (@psMessage != '')
	begin
		if len(@sXML) > 372
		begin
			set @psMessage = null
		end
		else if len(@sXML)+len(@psMessage) > 371
		begin
			set @psMessage = left(@psMessage, 371-len(@sXML))
		end
	end

	if (@psMessage is not null) and
	   (@psMessage != '')
	begin
		set @sXML = @sXML +
			char(9)+ '<Message>' + @psMessage + '</Message>' +char(10)
	end
	else
	begin
		set @sXML = @sXML +
			char(9)+ '<Message></Message>' +char(10)
	end

	set @sXML = @sXML + '</Alert>'

	RETURN @sXML
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

grant execute on dbo.fn_GetAlertXML to public
GO
