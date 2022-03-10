
select * from dbo.TABLEATTRIBUTES WHERE GENERICKEY = '-14'

declare @n int
exec @n = dbo.cs_DeleteCaseAttribute
	@pnUserIdentityId	= 1,
	@psCulture		= 'en-au',
	@psCaseKey		= '-14',
	@pnAttributeTypeId	= null,
	@psAttributeKey		= '10213'

select @n
select * from dbo.TABLEATTRIBUTES WHERE GENERICKEY = '-14'