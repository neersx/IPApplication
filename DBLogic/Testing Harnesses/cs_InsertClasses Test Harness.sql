
-- TESTING cs_InsertClasses

declare @err int
declare @sCaseId nvarchar(10)

select top 1 @sCaseId = CAST(CASEID as nvarchar(10)) from CASES C
	join TMCLASS T on T.COUNTRYCODE = C.COUNTRYCODE
-- OR
select top 1 @sCaseId = CAST(CASEID as nvarchar(10)) from CASES C
	where C.COUNTRYCODE not in (Select T.COUNTRYCODE from TMCLASS T)


Select * from CASES where CASEID = '-484'
exec @err = dbo.cs_InsertClasses
	@pnUserIdentityId		= 1,
	@psCulture			= null,
	@psCaseKey			= @sCaseId, 
	@psTrademarkClass		= null,
	@psTrademarkClassKey		= '32',
	@psTrademarkClassHeading	= null,
	@psTrademarkClassText		= 'hello'


Select NOOFCLASSES, LOCALCLASSES, INTCLASSES from CASES where CASEID = @sCaseId
Select * from CASETEXT where CASEID = @sCaseId
SELECT @err 