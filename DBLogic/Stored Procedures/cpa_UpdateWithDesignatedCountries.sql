-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_UpdateWithDesignatedCountries
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_UpdateWithDesignatedCountries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_UpdateWithDesignatedCountries.'
	drop procedure dbo.cpa_UpdateWithDesignatedCountries
end
print '**** Creating procedure dbo.cpa_UpdateWithDesignatedCountries...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_UpdateWithDesignatedCountries
as
-- PROCEDURE :	cpa_UpdateWithDesignatedCountries
-- VERSION :	3
-- DESCRIPTION:	Gets the list of Designated Countries for the cases being exported and concatenates
--		them into a single row to be sent to CPA.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28/03/2002	MF			Procedure Created
-- 05 Aug 2004	AB	8035	1	Add collate database_default to temp table definitions
-- 27 Apr 2005	MF	11200	2	Determine if a designated country is still live by using
--					the status from the CountryFlags table.
-- 19 Mar 2008	MF	16121	3	Strip trailing spaces from individual Country Codes as they are
--					concatenated together into a single string.

set nocount on
set concat_null_yields_null off

declare	@ErrorCode	int
declare @nCount		int
declare @nCaseId	int
declare	@sSQLString	nvarchar(4000)
declare @sCountryList	varchar(200)

Set	@ErrorCode=0

-- Loop through each Case that may have Designated Countries

If @ErrorCode=0
Begin
	Set @sSQLString="
		select @nCaseId=min(T.CASEID)
		from #TEMPDATATOSEND T
		join RELATEDCASE RC	on (RC.CASEID=T.CASEID	
					and RC.RELATIONSHIP='DC1'
					and RC.COUNTRYCODE is not null)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCaseId		int	OUTPUT',
					  @nCaseId=@nCaseId		OUTPUT

End

WHILE @nCaseId is not null
and   @ErrorCode=0
Begin
	set @sCountryList=null
	set @nCount=0
	
	Set @sSQLString="
	Select @sCountryList=@sCountryList+rtrim(RC.COUNTRYCODE),
		@nCount=@nCount+1
	from #TEMPDATATOSEND T
	join CASES C		on (C.CASEID=T.CASEID)
	join RELATEDCASE RC	on (RC.CASEID=C.CASEID
				and RC.RELATIONSHIP='DC1')
	join COUNTRYFLAGS CF	on (CF.COUNTRYCODE=C.COUNTRYCODE
				and CF.FLAGNUMBER=RC.CURRENTSTATUS
				and CF.STATUS>0)	-- Indicates the Status is live
	where C.CASEID=@nCaseId
	Order by RC.COUNTRYCODE"
	
	exec sp_executesql @sSQLString,
				N'@sCountryList		nvarchar(200)	output,
				  @nCount		int		output,
				  @nCaseId		int',
				  @sCountryList=@sCountryList		output,
				  @nCount=@nCount			output,
				  @nCaseId=@nCaseId

	-- Update each #TEMPCPASEND row with the concatenated list of designated
	-- countries and also the number of designated countries.

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		update	#TEMPCPASEND
		set	DESIGNATEDSTATES=@sCountryList,
			NUMBEROFSTATES  =@nCount
		from	#TEMPCPASEND T
		where T.CASEID=@nCaseId"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int,
						  @nCount		int,
						  @sCountryList		nvarchar(200)',
						  @nCaseId=@nCaseId,
						  @nCount=@nCount,
						  @sCountryList=@sCountryList

	End

	-- Now get the next country to concatenate which is greater than the last Country

	If @ErrorCode=0
	Begin
		
		Set @sSQLString="
			select @nCaseId=min(T.CASEID)
			from #TEMPDATATOSEND T
			join RELATEDCASE RC	on (RC.CASEID=T.CASEID	
						and RC.RELATIONSHIP='DC1'
						and RC.COUNTRYCODE is not null)
			where T.CASEID>@nCaseId"
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int	OUTPUT',
						  @nCaseId=@nCaseId		OUTPUT

	End
End
	
Return @ErrorCode
go

grant execute on dbo.cpa_UpdateWithDesignatedCountries to public
go
