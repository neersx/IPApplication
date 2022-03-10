using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class CriteriaMaintenanceValidatorFacts : FactBase
    {
        [Theory]
        [InlineData(CriteriaPurposeCodes.EventsAndEntries)]
        [InlineData(CriteriaPurposeCodes.CheckList)]
        public void DuplicateCriteriaNameShouldNotBeAllowed(string purposeCode)
        {
            var f = new CriteriaMaintenanceValidatorFixture(Db);

            var c = new CriteriaBuilder {PurposeCode = purposeCode}.Build().In(Db);
            var r = f.Subject.ValidateCriteriaName(c.Description);

            Assert.Equal("criteriaName", r.Field);
            Assert.Equal("notunique", r.Message);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public void DuplicateChecklistCriteriaShouldNotBeAllowed(bool inUse)
        {
            var f = new CriteriaMaintenanceValidatorFixture(Db);
            var c = new Criteria
            {
                Id = Fixture.Integer(),
                Description = Fixture.String("Description"),
                CaseTypeId = Fixture.RandomString(1),
                PurposeCode = CriteriaPurposeCodes.CheckList,
                CountryId = Fixture.RandomString(3),
                RuleInUse = 1,
                ChecklistType = Fixture.Short()
            }.In(Db);

            var criteria = new Criteria
            {
                Description = c.Description,
                RuleInUse = inUse ? 1 : 0,
                CaseTypeId = c.CaseTypeId,
                CountryId = c.CountryId,
                PurposeCode = CriteriaPurposeCodes.CheckList,
                ChecklistType = c.ChecklistType
            }.WithUnknownToDefault();
            
            var r = f.Subject.ValidateDuplicateCriteria(criteria, true);
            Assert.Equal("criteriaDuplicate", r.Field);
            Assert.Equal(c.Id.ToString(), r.Message);
        }

        [Fact]
        public void DuplicateEventsAndEntriesCriteriaShouldNotBeAllowed()
        {
            var f = new CriteriaMaintenanceValidatorFixture(Db);
            var c = new Criteria
            {
                Id = Fixture.Integer(),
                Description = Fixture.String("Description"),
                CaseTypeId = Fixture.RandomString(1),
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                CountryId = Fixture.RandomString(3),
                RuleInUse = 1,
                ActionId = Fixture.RandomString(2)
            }.In(Db);

            var criteria = new Criteria
            {
                Description = c.Description,
                RuleInUse = 1,
                CaseTypeId = c.CaseTypeId,
                CountryId = c.CountryId,
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                ActionId = c.ActionId
            }.WithUnknownToDefault();
            
            var r = f.Subject.ValidateDuplicateCriteria(criteria);
            Assert.Equal("characteristicsDuplicate", r.Field);
            Assert.Equal(c.Id.ToString(), r.Message);
        }
    }

    public class CriteriaMaintenanceValidatorFixture : IFixture<CriteriaMaintenanceValidator>
    {
        public CriteriaMaintenanceValidatorFixture(InMemoryDbContext db)
        {
            Subject = new CriteriaMaintenanceValidator(db);
        }
        public CriteriaMaintenanceValidator Subject { get; }
    }
}
