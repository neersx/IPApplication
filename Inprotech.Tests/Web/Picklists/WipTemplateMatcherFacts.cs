using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using WipCategory = InprotechKaizen.Model.Accounting.WipCategory;

namespace Inprotech.Tests.Web.Picklists
{
    public class WipTemplateMatcherFacts : FactBase
    {
        [Fact]
        public async Task ReturnsServiceChargeAndTimesheetActivitiesOnly()
        {
            var f = new WipTemplateMatcherFixture(Db);
            new WipTemplate {WipType = f.RecoverableType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = Fixture.String()}.In(Db);
            var valid = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            var result = await f.Subject.Get(string.Empty);
            var matches = result.ToArray();
            Assert.Equal(valid.WipCode, matches.Single().Key);
        }

        [Fact]
        public async Task ReturnsMatchesOnSearchFilter()
        {

            var search = Fixture.String();
            var f = new WipTemplateMatcherFixture(Db);
            new WipTemplate {WipType = f.RecoverableType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search}.In(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search}.In(Db);
            
            var valid1 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search}.In(Db);
            var valid2 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = search + "-WIP", UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            
            var result = await f.Subject.Get(search);
            var matches = result.ToArray();
            var timesheetWipTemplates = matches.Length;
            Assert.Equal(2, timesheetWipTemplates);
            Assert.Equal(valid1.Description, matches.Single(_ => _.Key == valid1.WipCode).Value);
            Assert.Equal(valid2.Description, matches.Single(_ => _.Key == valid2.WipCode).Value);

            var resultWithAllTemplates = await f.Subject.Get(search, false);
            var totalTemplates = resultWithAllTemplates.ToArray();
            Assert.Equal(5, totalTemplates.Length);
            Assert.NotEqual(timesheetWipTemplates, totalTemplates.Length);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(true, false)]
        [InlineData(false, true)]
        [InlineData(false, false)]
        public async Task ExcludesNonMatchingCaseType(bool withSearch, bool withOpenAction)
        {
            var search = withSearch ? Fixture.String() : string.Empty;
            var f = new WipTemplateMatcherFixture(Db, withOpenAction);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, CaseTypeId = f.ForCase.TypeId+"A"}.In(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, CaseTypeId = f.ForCase.TypeId}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search, CaseTypeId = f.ForCase.TypeId}.In(Db);
            new WipTemplate {WipType = f.RecoverableType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search, CaseTypeId = f.ForCase.TypeId}.In(Db);
            
            var valid1 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search}.In(Db);
            var valid2 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = search+"-WIP", UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            var valid3 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search + Fixture.String(), CaseTypeId = f.ForCase.TypeId}.In(Db);
            
            var result = await f.Subject.Get(search, true, f.ForCase.Id);
            var matches = result.ToArray();
            Assert.Equal(3, matches.Length);
            Assert.Equal(valid1.Description, matches.Single(_ => _.Key == valid1.WipCode).Value);
            Assert.Equal(valid2.Description, matches.Single(_ => _.Key == valid2.WipCode).Value);
            Assert.Equal(valid3.Description, matches.Single(_ => _.Key == valid3.WipCode).Value);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(true, false)]
        [InlineData(false, true)]
        [InlineData(false, false)]
        public async Task ExcludesNonMatchingPropertyType(bool withSearch, bool withOpenAction)
        {
            var search = withSearch ? Fixture.String() : string.Empty;
            var f = new WipTemplateMatcherFixture(Db, withOpenAction);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, PropertyTypeId = f.ForCase.PropertyTypeId+"A"}.In(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, PropertyTypeId = f.ForCase.PropertyTypeId}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search, PropertyTypeId = f.ForCase.PropertyTypeId}.In(Db);
            new WipTemplate {WipType = f.RecoverableType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search, PropertyTypeId = f.ForCase.PropertyTypeId}.In(Db);
            
            var valid1 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search}.In(Db);
            var valid2 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = search + "-WIP", UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            var valid3 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search + Fixture.String(), PropertyTypeId = f.ForCase.PropertyTypeId}.In(Db);
            
            var result = await f.Subject.Get(search, true, f.ForCase.Id);
            var matches = result.ToArray();
            Assert.Equal(3, matches.Length);
            Assert.Equal(valid1.Description, matches.Single(_ => _.Key == valid1.WipCode).Value);
            Assert.Equal(valid2.Description, matches.Single(_ => _.Key == valid2.WipCode).Value);
            Assert.Equal(valid3.Description, matches.Single(_ => _.Key == valid3.WipCode).Value);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(true, false)]
        [InlineData(false, true)]
        [InlineData(false, false)]
        public async Task ExcludesNonMatchingCountry(bool withSearch, bool withOpenAction)
        {
            var search = withSearch ? Fixture.String() : string.Empty;
            var f = new WipTemplateMatcherFixture(Db, withOpenAction);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, CountryCode = f.ForCase.CountryId+"X"}.In(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, CountryCode = f.ForCase.CountryId}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search, CountryCode = f.ForCase.CountryId}.In(Db);
            new WipTemplate {WipType = f.RecoverableType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search, CountryCode = f.ForCase.CountryId}.In(Db);
            
            var valid1 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search}.In(Db);
            var valid2 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = search + "-WIP", UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            var valid3 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search + Fixture.String(), CountryCode = f.ForCase.CountryId}.In(Db);
            
            var result = await f.Subject.Get(search, true, f.ForCase.Id);
            var matches = result.ToArray();
            Assert.Equal(3, matches.Length);
            Assert.Equal(valid1.Description, matches.Single(_ => _.Key == valid1.WipCode).Value);
            Assert.Equal(valid2.Description, matches.Single(_ => _.Key == valid2.WipCode).Value);
            Assert.Equal(valid3.Description, matches.Single(_ => _.Key == valid3.WipCode).Value);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(true, false)]
        [InlineData(false, true)]
        [InlineData(false, false)]
        public async Task ExcludesNonMatchingAction(bool withSearch, bool withOpenAction)
        {
            var @case = new CaseBuilder().Build().In(Db);
            var openAction = new OpenActionBuilder(Db){Case = @case, IsOpen = true }.Build().In(Db);
            new OpenActionBuilder(Db){Case = @case, IsOpen = false }.Build().In(Db);
            var search = withSearch ? Fixture.String() : string.Empty;

            var f = new WipTemplateMatcherFixture(Db, withOpenAction);
            new WipTemplate {WipType = f.RecoverableType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, ActionId = openAction.ActionId}.In(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search, ActionId = openAction.ActionId}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Wip, Description = search, ActionId = openAction.ActionId}.In(Db);
            
            var valid1 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search}.In(Db);
            var valid2 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = search + "-WIP", UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            var valid3 = new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String(), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = search + Fixture.String(), ActionId = openAction.ActionId}.In(Db);
            
            var result = await f.Subject.Get(search, true, @case.Id);
            var matches = result.ToArray();
            Assert.Equal(3, matches.Length);
            Assert.Equal(valid1.Description, matches.Single(_ => _.Key == valid1.WipCode).Value);
            Assert.Equal(valid2.Description, matches.Single(_ => _.Key == valid2.WipCode).Value);
            Assert.Equal(valid3.Description, matches.Single(_ => _.Key == valid3.WipCode).Value);
        }

        [Fact]
        public async Task ExcludesNotInUse()
        {
            var f = new WipTemplateMatcherFixture(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String("valid-"), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String("valid-"), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String(), IsNotInUse = false}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String("invalid-"), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String(), IsNotInUse = true}.In(Db);
            var result = await f.Subject.Get(string.Empty);
            var matches = result.ToArray();
            Assert.Equal(2, matches.Length);
            Assert.True(matches.All(_ => _.Key.StartsWith("valid-")));
        }

        [Fact]
        public async Task IncludesDisbursementsOnly()
        {
            var f = new WipTemplateMatcherFixture(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String("valid-"), Description = Fixture.String()}.In(Db);
            new WipTemplate {WipType = f.DisbursementType, WipCode = Fixture.String("valid-"), Description = Fixture.String(), IsNotInUse = false}.In(Db);
            new WipTemplate {WipType = f.ServiceChargeType, WipCode = Fixture.String("invalid-"), UsedBy = (int)KnownApplicationUsage.Timesheet, Description = Fixture.String()}.In(Db);
            var result = await f.Subject.Get(string.Empty, false, null, true);
            var matches = result.ToArray();
            Assert.Equal(2, matches.Length);
            Assert.True(matches.All(_ => _.Key.StartsWith("valid-")));
        }
    }

    public class WipTemplateMatcherFixture : IFixture<WipTemplateMatcher>
    {
        public readonly WipType ServiceChargeType;
        public readonly WipType RecoverableType;
        public readonly WipType DisbursementType;
        public WipTemplateMatcher Subject { get; }
        IPreferredCultureResolver CultureResolver { get; set; }
        public Case ForCase { get; set; }
        public OpenAction OpenAction { get; set; }
        public WipTemplateMatcherFixture(InMemoryDbContext db, bool withOpenActionForCase = false)
        {
            var sc = new InprotechKaizen.Model.Accounting.Work.WipCategory {Id = WipCategory.ServiceCharge}.In(db);
            var pd = new InprotechKaizen.Model.Accounting.Work.WipCategory {Id = WipCategory.Disbursements}.In(db);
            var rc = new InprotechKaizen.Model.Accounting.Work.WipCategory {Id = WipCategory.Recoverables}.In(db);
            new OpenActionBuilder(db){IsOpen = true }.Build().In(db);
            ForCase = new CaseBuilder().Build().In(db);
            if (withOpenActionForCase)
            {
                OpenAction = new OpenActionBuilder(db){Case = ForCase, IsOpen = true }.Build().In(db);   
            }
            ServiceChargeType = new WipType {Category = sc, Id = "SCW"}.In(db);
            RecoverableType = new WipType {Category = rc, Id = "ORW"}.In(db);
            DisbursementType = new WipType {Category = pd, Id = "PDW"}.In(db);
            CultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new WipTemplateMatcher(db, CultureResolver);
        }
    }
}