using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.Search.Types
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class BillSearchDbSetup : DbSetup
    {
        public int CreateSavedSearch(int queryContextKey, bool isFinalisedBillSearch = false)
        {
            var identityId = 45;
            Query query = null;

            string xmlFilterCriteria = @"<Search><Filtering><biw_ListBillSummary>
 <FilterCriteria>
    <OpenItem IsFinalised=" + (isFinalisedBillSearch ? "'1'" : "'0'") + @">
      <EntityKey Operator='0'>-283575757</EntityKey>
      <ItemType Operator='0'>510</ItemType>
      <Debtor />
      <Staff />
      <AssociatedNames />
    </OpenItem>
  </FilterCriteria>
  <AggregateFilterCriteria />
</biw_ListBillSummary></Filtering></Search>";

            Do(x =>
            {
                var filter = Insert(new QueryFilter { ProcedureName = "biw_ListBillSummary", XmlFilterCriteria = xmlFilterCriteria });
                query = Insert(new Query { ContextId = queryContextKey, Filter = filter, Name = "E2E-BillSearch-" + Fixture.AlphaNumericString(8), IdentityId = identityId });
                x.DbContext.SaveChanges();
            });

            return query.Id;
        }
    }
}