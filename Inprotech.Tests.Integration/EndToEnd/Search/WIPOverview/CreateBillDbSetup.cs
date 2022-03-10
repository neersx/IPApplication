using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Search.WIPOverview
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class CreateBillDbSetup : DbSetup
    {
        public dynamic Setup()
        {
            var identityId = 45;
            InprotechKaizen.Model.Cases.Case case1 = null;
            InprotechKaizen.Model.Cases.Case case2 = null;
            DateTime from = DateTime.Today;
            DateTime to = DateTime.Today;
            Query query = null;

            string xmlFilterCriteria = @"<Search><Filtering><wp_ListWorkInProgress>
  <FilterCriteria>
    <EntityKey Operator='0'>-283575757</EntityKey>
    <BelongsTo>
      <ActingAs>
        <IsWipStaff>0</IsWipStaff>
        <AssociatedName>1</AssociatedName>
        <AnyNameType>1</AnyNameType>
      </ActingAs>
    </BelongsTo>
    <Debtor IsRenewalDebtor='0' />
    <ItemDate>
      <DateRange Operator='7'>
        <From>" + from.ToString("yyyy-MM-dd") + @"</From>
        <To>" + to.ToString("yyyy-MM-dd") + @"</To>
      </DateRange>
    </ItemDate>
    <WipStatus>
      <IsActive>1</IsActive>
      <IsLocked>1</IsLocked>
    </WipStatus>
    <RenewalWip>
      <IsRenewal>1</IsRenewal>
      <IsNonRenewal>1</IsNonRenewal>
    </RenewalWip>
    <csw_ListCase>
      <FilterCriteriaGroup>
        <FilterCriteria ID='1'>
          <AccessMode>1</AccessMode>
          <IsAdvancedFilter>false</IsAdvancedFilter>
          <CaseReference Operator='2'>E2E-SingleBill</CaseReference>
          <StandingInstructions IncludeInherited='0' />
          <StatusFlags CheckDeadCaseRestriction='1' />
          <InheritedName />
          <CaseNameGroup />
          <AttributeGroup BooleanOr='0' />
          <Event Operator='' IsRenewalsOnly='0' IsNonRenewalsOnly='0' ByEventDate='1' />
          <Actions />
        </FilterCriteria>
      </FilterCriteriaGroup>
      <ColumnFilterCriteria>
        <DueDates UseEventDates='1' UseAdHocDates='0'>
          <Dates UseDueDate='0' UseReminderDate='0' />
          <Actions IncludeClosed='0' IsRenewalsOnly='1' IsNonRenewalsOnly='1' />
          <DueDateResponsibilityOf IsAnyName='0' IsStaff='0' IsSignatory='0' />
        </DueDates>
      </ColumnFilterCriteria>
    </csw_ListCase>
  </FilterCriteria>
  <AggregateFilterCriteria />
</wp_ListWorkInProgress></Filtering></Search>";

            Do(x =>
            {
                case1 = new CaseBuilder(x.DbContext).Create("E2E-SingleBill1", withDebtor: true);
                case2 = new CaseBuilder(x.DbContext).Create("E2E-SingleBill2", withDebtor: true);
                x.DbContext.SaveChanges();
            });

            RecordWip(identityId, case1);
            RecordWip(identityId, case2);

            Do(x =>
            {
                var filter = Insert(new QueryFilter { ProcedureName = "wp_ListWorkInProgress", XmlFilterCriteria = xmlFilterCriteria });
                query = Insert(new Query { ContextId = 200, Filter = filter, Name = "E2E Test", IdentityId = identityId });
                x.DbContext.SaveChanges();
            });

            return new
            {
                Case1 = case1,
                Case2 = case2,
                IdentityId = identityId,
                QueryKey = query.Id,
                FromDate = from,
                ToDate = to
            };
        }

        void RecordWip(int identityId, InprotechKaizen.Model.Cases.Case @case)
        {
            Do(db =>
            {
                using (var dbCommand = db.DbContext.CreateStoredProcedureCommand("dbo.wp_PostWIP"))
                {
                    dbCommand.Parameters.AddWithValue("pnUserIdentityId", identityId);
                    dbCommand.Parameters.AddWithValue("psCulture", "en-GB");
                    dbCommand.Parameters.AddWithValue("pbCalledFromCentura", 0);
                    dbCommand.Parameters.AddWithValue("pnEntityKey", -283575757);
                    dbCommand.Parameters.AddWithValue("pdtTransDate", DateTime.Today);
                    dbCommand.Parameters.AddWithValue("pnTransactionType", 402);
                    dbCommand.Parameters.AddWithValue("pnWIPToNameNo", @case.CaseNames.First().NameId);
                    dbCommand.Parameters.AddWithValue("pnWIPToCaseId", @case.Id);
                    dbCommand.Parameters.AddWithValue("pnEmployeeNo", @case.Staff().NameId);
                    dbCommand.Parameters.AddWithValue("psProfitCentreCode", @case.ProfitCentreCode);
                    dbCommand.Parameters.AddWithValue("psWIPCode", "COURIE");
                    dbCommand.Parameters.AddWithValue("pnLocalValue", 1100);
                    dbCommand.Parameters.AddWithValue("pnLocalCost", 1000);
                    dbCommand.Parameters.AddWithValue("pnCostCalculation2", 200);
                    dbCommand.Parameters.AddWithValue("pbGeneratedInAdvance", 0);
                    dbCommand.Parameters.AddWithValue("pnNarrativeNo", -483);
                    dbCommand.Parameters.AddWithValue("psNarrative", "Courier charges recovered at cost");
                    dbCommand.Parameters.AddWithValue("pnMarginNo", 1);
                    dbCommand.Parameters.AddWithValue("bIsCreditWIP", 0);
                    dbCommand.ExecuteNonQuery();
                }
            });
        }
    }
}