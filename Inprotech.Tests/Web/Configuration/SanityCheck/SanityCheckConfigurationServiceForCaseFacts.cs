using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.SanityCheck;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.DataValidation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.SanityCheck
{
    public class SanityCheckConfigurationServiceForCaseFacts : FactBase
    {
        CommonQueryParameters _defaultParam = new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" };

        [Fact]
        public async Task GetCaseValidationRulesProperty()
        {
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            var data = fixture.Setup();
            fixture.CultureResolver.Resolve().ReturnsForAnyArgs("EN");

            var filters = new SanityCheckCaseViewModel
            {
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    PropertyType = data.propertyType.Code,
                    StatusIncludePending = false,
                    StatusIncludeRegistered = false,
                    StatusIncludeDead = false
                },
                Event = new EventModel
                {
                    IncludeDue = false,
                    IncludeOccurred = false
                }
            };

            var result = await fixture.Subject.GetCaseValidationRules(filters, _defaultParam);
            Assert.Empty(result);

            filters.CaseCharacteristics.PropertyTypeExclude = true;
            result = await fixture.Subject.GetCaseValidationRules(filters, _defaultParam);
            Assert.Single(result);
        }

        [Fact]
        public async Task GetCaseValidationRulesBasis()
        {
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            var data = fixture.Setup();
            fixture.CultureResolver.Resolve().ReturnsForAnyArgs("EN");

            var filters = new SanityCheckCaseViewModel
            {
                CaseCharacteristics = new CaseCharacteristicsModel()
                {
                    Basis = data.basis.Code,
                    StatusIncludePending = false,
                    StatusIncludeRegistered = false,
                    StatusIncludeDead = false
                },
                Event = new EventModel
                {
                    IncludeDue = false,
                    IncludeOccurred = false
                }
            };

            var param = new CommonQueryParameters { SortBy = "ruleDescription" };
            var result = await fixture.Subject.GetCaseValidationRules(filters, param);
            Assert.Single(result);

            filters.CaseCharacteristics.BasisExclude = true;
            result = await fixture.Subject.GetCaseValidationRules(filters, param);
            Assert.Single(result);
        }

        [Fact]
        public async Task GetCaseValidationRulesCountry()
        {
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            var data = fixture.Setup();
            fixture.CultureResolver.Resolve().ReturnsForAnyArgs("EN");

            var filters = new SanityCheckCaseViewModel
            {
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    Jurisdiction = data.country1.Id,
                    StatusIncludePending = false,
                    StatusIncludeRegistered = false,
                    StatusIncludeDead = false
                },
                Event = new EventModel
                {
                    IncludeDue = false,
                    IncludeOccurred = false
                }
            };

            var result = await fixture.Subject.GetCaseValidationRules(filters, _defaultParam);
            Assert.Equal(2, result.Count());

            filters.CaseCharacteristics.JurisdictionExclude = true;
            result = await fixture.Subject.GetCaseValidationRules(filters, _defaultParam);
            Assert.Empty(result);
        }

        [Fact]
        public async Task GetCaseValidationRulesStatus()
        {
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            var data = fixture.Setup();

            fixture.CultureResolver.Resolve().ReturnsForAnyArgs("EN");

            var filters = new SanityCheckCaseViewModel
            {
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    Jurisdiction = data.country1.Id,
                    StatusIncludePending = false,
                    StatusIncludeRegistered = false,
                    StatusIncludeDead = false
                },
                Event = new EventModel
                {
                    IncludeDue = false,
                    IncludeOccurred = false
                }
            };

            var result = await fixture.Subject.GetCaseValidationRules(filters, new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" });
            Assert.Equal(2, result.Count());

            filters.CaseCharacteristics.StatusIncludePending = false;
            filters.CaseCharacteristics.StatusIncludeDead = true;

            result = await fixture.Subject.GetCaseValidationRules(filters, new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" });
            Assert.Single(result);
        }

        [Fact]
        public async Task GetCaseValidationRulesTexts()
        {
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            fixture.Setup();

            var filters = new SanityCheckCaseViewModel
            {
                RuleOverview = new RuleOverviewModel
                {
                    DisplayMessage = "application"
                },
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    StatusIncludePending = false,
                    StatusIncludeRegistered = false,
                    StatusIncludeDead = false
                },
                Event = new EventModel
                {
                    IncludeDue = false,
                    IncludeOccurred = false
                }
            };

            var result = await fixture.Subject.GetCaseValidationRules(filters, new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" });
            Assert.Equal(2, result.Count());

            filters.RuleOverview.DisplayMessage = string.Empty;
            filters.RuleOverview.Notes = "notes3";
            result = await fixture.Subject.GetCaseValidationRules(filters, new CommonQueryParameters { SortBy = "ruleDescription", SortDir = "asc" });
            Assert.Single(result);
        }

        [Fact]
        public async Task GetCaseValidationRulesInclude()
        {
            var param = new CommonQueryParameters { SortBy = "ruleDescription" };
            var fixture = new SanityCheckConfigurationServiceFixture(Db);
            fixture.Setup();

            var filters = new SanityCheckCaseViewModel
            {
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    StatusIncludePending = false,
                    StatusIncludeRegistered = false,
                    StatusIncludeDead = false
                }
            };

            Assert.Equal(4, Db.Set<DataValidation>().Count());

            var result = await fixture.Subject.GetCaseValidationRules(filters, param);
            Assert.Equal(3, result.Count());

            filters.RuleOverview.InUse = true;
            result = await fixture.Subject.GetCaseValidationRules(filters, param);
            Assert.Equal(2, result.Count());

            filters.RuleOverview.Deferred = true;
            filters.RuleOverview.InUse = false;
            result = await fixture.Subject.GetCaseValidationRules(filters, param);
            Assert.Equal(1, result.Count());

            filters.RuleOverview.Deferred = null;
            filters.RuleOverview.InUse = null;
            result = await fixture.Subject.GetCaseValidationRules(filters, param);
            Assert.Equal(3, result.Count());
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

            public (DataValidation validation1, DataValidation validation2, DataValidation validation3, Office office,
                CaseType caseType, Country country1, PropertyType propertyType, CaseCategory caseCategory,
                SubType subType, ApplicationBasis basis) Setup()
            {
                var office = new OfficeBuilder().Build().In(Db);
                var caseType = new CaseTypeBuilder().Build().In(Db);
                var jurisdiction = new CountryBuilder().Build().In(Db);
                var propertyType = new PropertyTypeBuilder().Build().In(Db);
                var propertyType2 = new PropertyTypeBuilder().Build().In(Db);
                var caseCategory = new CaseCategoryBuilder().Build().In(Db);
                var subtype = new SubTypeBuilder().Build().In(Db);
                var basis = new ApplicationBasisBuilder().Build().In(Db);
                var validBasis = new ValidBasisBuilder()
                {
                    Basis = basis,
                    Country = jurisdiction,
                    PropertyType = propertyType
                };

                var dataValidation1 = new DataValidation
                {
                    FunctionalArea = KnownFunctionalArea.Case,
                    RuleDescription = "description1",
                    PropertyType = propertyType.Code,
                    NotPropertyType = true,
                    CaseType = caseType.Code,
                    DisplayMessage = "application display message1",
                    Notes = "application display notes",
                    Basis = basis.Code,
                    CountryCode = jurisdiction.Id,
                    StatusFlag = 2,
                    NotBasis = true,
                    InUseFlag = true,
                    DeferredFlag = false
                }.In(Db);

                var dataValidation2 = new DataValidation
                {
                    FunctionalArea = KnownFunctionalArea.Case,
                    RuleDescription = "description2",
                    PropertyType = propertyType2.Code,
                    OfficeId = office.Id,
                    StatusFlag = 1,
                    CaseCategory = caseCategory.CaseCategoryId,
                    DisplayMessage = "test",
                    Notes = "notes",
                    InUseFlag = false,
                    DeferredFlag = true
                }.In(Db);

                var dataValidation3 = new DataValidation
                {
                    FunctionalArea = KnownFunctionalArea.Case,
                    RuleDescription = "description3",
                    DisplayMessage = "application display message3",
                    Notes = "application display notes3",
                    Basis = validBasis.Basis.Code,
                    StatusFlag = 0,
                    CaseCategory = caseCategory.CaseCategoryId,
                    CountryCode = jurisdiction.Id,
                    InUseFlag = true,
                    DeferredFlag = true
                }.In(Db);

                new DataValidation
                {
                    RuleDescription = "description4",
                    DisplayMessage = "application display message4",
                    Notes = "application display notes4",
                    Basis = validBasis.Basis.Code,
                    StatusFlag = 0,
                    FunctionalArea = "N"
                }.In(Db);

                return (dataValidation1, dataValidation2, dataValidation3, office, caseType, jurisdiction,
                    propertyType, caseCategory, subtype, basis);
            }
        }
    }
}