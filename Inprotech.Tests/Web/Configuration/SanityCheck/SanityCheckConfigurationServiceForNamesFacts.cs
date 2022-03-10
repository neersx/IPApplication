using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.SanityCheck;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.SanityCheck
{
    public class SanityCheckConfigurationServiceForNamesFacts : FactBase
    {
        CommonQueryParameters _defaultParam = new() { SortBy = "ruleDescription", SortDir = "asc" };

        [Fact]
        public async Task GetNameValidationRulesTexts()
        {
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            fixture.Setup();

            var filters = new SanityCheckNameViewModel
            {
                RuleOverview = new RuleOverviewModel
                {
                    DisplayMessage = "application"
                }
            };

            var result = await fixture.Subject.GetNameValidationRules(filters, new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" });
            Assert.Equal(2, result.Count());

            filters.RuleOverview.DisplayMessage = string.Empty;
            filters.RuleOverview.Notes = "notes3";
            result = await fixture.Subject.GetNameValidationRules(filters, new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" });
            Assert.Single(result);
        }

        [Fact]
        public async Task GetFormattedName()
        {
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            var data = fixture.Setup();
            var name = new Name(Fixture.Integer())
            {
                FirstName = Fixture.String(),
                LastName = Fixture.String(),
                Title = Fixture.String()
            }.In(Db);
            data.validation1.NameId = name.Id;

            var filters = new SanityCheckNameViewModel
            {
                RuleOverview = new RuleOverviewModel
                {
                    DisplayMessage = "application display message1"
                }
            };

            var result = await fixture.Subject.GetNameValidationRules(filters, new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" });
            Assert.Single(result);
            Assert.Equal(name.FormattedWithDefaultStyle(), result.First().Name);
        }

        public class SanityCheckConfigurationServiceFixture : IFixture<ISanityCheckService>
        {
            public SanityCheckConfigurationServiceFixture(InMemoryDbContext db)
            {
                Db = db;
                CultureResolver = Substitute.For<IPreferredCultureResolver>();
                CultureResolver.Resolve().ReturnsForAnyArgs("EN");
                Subject = new SanityCheckService(Db, CultureResolver);
            }

            InMemoryDbContext Db { get; }
            public IPreferredCultureResolver CultureResolver { get; set; }
            public ISanityCheckService Subject { get; set; }

            public (DataValidation validation1, DataValidation validation2, DataValidation validation3, Country country1) Setup()
            {
                var jurisdiction = new CountryBuilder().Build().In(Db);
                var dataValidation1 = new DataValidation
                {
                    FunctionalArea = KnownFunctionalArea.Name,
                    RuleDescription = "description1",
                    DisplayMessage = "application display message1",
                    Notes = "application display notes",
                    CountryCode = jurisdiction.Id,
                    StatusFlag = 2,
                    UsedasFlag = 1,
                    SupplierFlag = false,
                    Category = 1,
                    InUseFlag = true,
                    DeferredFlag = false
                }.In(Db);

                var dataValidation2 = new DataValidation
                {
                    FunctionalArea = KnownFunctionalArea.Name,
                    RuleDescription = "description2",
                    StatusFlag = 1,
                    DisplayMessage = "test",
                    Notes = "notes",
                    InUseFlag = false,
                    DeferredFlag = true,
                    UsedasFlag = 1,
                    SupplierFlag = false,
                    Category = 1
                }.In(Db);

                var dataValidation3 = new DataValidation
                {
                    FunctionalArea = KnownFunctionalArea.Name,
                    RuleDescription = "description3",
                    DisplayMessage = "application display message3",
                    Notes = "application display notes3",
                    UsedasFlag = 1,
                    SupplierFlag = true,
                    Category = 1,
                    StatusFlag = 0,
                    CountryCode = jurisdiction.Id,
                    InUseFlag = true,
                    DeferredFlag = true
                }.In(Db);

                new DataValidation
                {
                    RuleDescription = "description4",
                    DisplayMessage = "application display message4",
                    Notes = "application display notes4",
                    StatusFlag = 0,
                    FunctionalArea = KnownFunctionalArea.Case,
                    UsedasFlag = 4,
                    SupplierFlag = false,
                    Category = null
                }.In(Db);

                return (dataValidation1, dataValidation2, dataValidation3, jurisdiction);
            }
        }
    }
}