using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Accounting.Billing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing
{
    public class BestNarrativeResolverFacts
    {
        public class ForActivityOnly : FactBase
        {
            [Fact]
            public async Task ShouldReturnNarrativeForWip()
            {
                var activityKey = Fixture.RandomString(6);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db).Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer());
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }

            [Fact]
            public async Task ShouldReturnNullForMultiWipMatches()
            {
                var activityKey = Fixture.RandomString(6);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer());
                Assert.Null(result);
            }

            [Fact]
            public async Task ShouldReturnWipOnlyMatches()
            {
                var activityKey = Fixture.RandomString(6);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = Fixture.RandomString(3)}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, CountryCode = Fixture.RandomString(3)}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, PropertyTypeId = Fixture.RandomString(3)}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseCategoryId = Fixture.RandomString(3)}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, SubTypeId = Fixture.RandomString(3)}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, TypeOfMarkId = Fixture.Integer()}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer());
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }
        }

        public class ForActivityCaseOrDebtor : FactBase
        {
            [Fact]
            public async Task ShouldReturnNarrativeMatchingWipWhereNoCaseCriteriaApplied()
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                new CaseBuilder().BuildWithId(caseKey).In(Db);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db).Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, caseKey);
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnNarrativeMatchingWipForDebtorOnly(bool withMatch)
            {
                var activityKey = Fixture.RandomString(6);
                var debtorKey = Fixture.Integer();
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db).Build();
                var defaultNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, DebtorId = debtorKey}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer(), debtorId: withMatch ? debtorKey : debtorKey + 1);
                Assert.Equal(withMatch ? wipNarrative.NarrativeId : defaultNarrative.NarrativeId, result.Key);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnNarrativeMatchingWipForTheCurrentStaff(bool withMatch)
            {
                var activityKey = Fixture.RandomString(6);
                var debtorKey = Fixture.Integer();
                var staffNameId = Fixture.Integer();
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db).Build();
                var defaultNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, DebtorId = debtorKey}.Build();
                var f = new DefaultNarrativeFixture(Db);
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, DebtorId = debtorKey, StaffId = withMatch ? staffNameId : staffNameId + 1}.Build();
                var result = await f.Subject.Resolve("en", activityKey, staffNameId, debtorId: debtorKey);
                Assert.Equal(withMatch ? wipNarrative.NarrativeId : defaultNarrative.NarrativeId, result.Key);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnNarrativeMatchingWipAndCaseDebtor(bool withMatch)
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var caseInfo = new CaseBuilder().BuildWithId(caseKey).In(Db);
                var debtorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(Db);
                var debtor = new CaseNameBuilder(Db) {Name = new NameBuilder(Db).Build(), NameType = debtorNameType}.BuildWithCase(caseInfo).In(Db);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                var caseNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, DebtorId = withMatch ? debtor.NameId : debtor.NameId + 1}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer(), caseKey);
                Assert.Equal(withMatch ? wipNarrative.NarrativeId : caseNarrative.NarrativeId, result.Key);
            }

            [Fact]
            public async Task ShouldReturnNarrativeMatchingWipAndCaseTypeCriteria()
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var caseInfo = new CaseBuilder().BuildWithId(caseKey).In(Db);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer(), caseKey);
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }

            [Fact]
            public async Task ShouldReturnNarrativeMatchingWipAndPropertyTypeCriteria()
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var caseInfo = new CaseBuilder().BuildWithId(caseKey).In(Db);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId, PropertyTypeId = caseInfo.PropertyTypeId}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer(), caseKey);
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }

            [Fact]
            public async Task ShouldReturnNarrativeMatchingWipAndCaseCategoryCriteria()
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var caseInfo = new CaseBuilder().BuildWithId(caseKey).In(Db);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId, PropertyTypeId = caseInfo.PropertyTypeId}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId, PropertyTypeId = caseInfo.PropertyTypeId, CaseCategoryId = caseInfo.Category.CaseCategoryId}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer(), caseKey);
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }

            [Fact]
            public async Task ShouldReturnNarrativeMatchingWipAndSubTypeCriteria()
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var caseInfo = new CaseBuilder().BuildWithId(caseKey).In(Db);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId, PropertyTypeId = caseInfo.PropertyTypeId, CaseCategoryId = caseInfo.Category.CaseCategoryId}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId, PropertyTypeId = caseInfo.PropertyTypeId, CaseCategoryId = caseInfo.Category.CaseCategoryId, SubTypeId = caseInfo.SubType.Code}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer(), caseKey);
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnNarrativeMatchingWipAndIsLocalCountry(bool isLocalCountry)
            {
                var activityKey = Fixture.RandomString(6);
                var caseKey = Fixture.Integer();
                var caseInfo = new CaseBuilder().BuildWithId(caseKey).In(Db);
                var builder = TableAttributesBuilder.ForCountry(isLocalCountry ? caseInfo.Country : new CountryBuilder().Build());
                builder.TableCodeId = 5002;
                builder.TableTypeId = 50;
                builder.Build().In(Db);
                new NarrativeRuleBuilder(Db).Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey}.Build();
                new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId, PropertyTypeId = caseInfo.PropertyTypeId, CaseCategoryId = caseInfo.Category.CaseCategoryId}.Build();
                var wipNarrative = new NarrativeRuleBuilder(Db) {WipCode = activityKey, CaseTypeId = caseInfo.TypeId, PropertyTypeId = caseInfo.PropertyTypeId, CaseCategoryId = caseInfo.Category.CaseCategoryId, SubTypeId = caseInfo.SubType.Code, IsLocalCountry = isLocalCountry, IsForeignCountry = !isLocalCountry}.Build();

                var f = new DefaultNarrativeFixture(Db);
                var result = await f.Subject.Resolve("en", activityKey, Fixture.Integer(), caseKey);
                Assert.Equal(wipNarrative.NarrativeId, result.Key);
            }
        }

        public class DefaultNarrativeFixture : IFixture<BestNarrativeResolver>
        {
            public DefaultNarrativeFixture(InMemoryDbContext db)
            {
                TranslatedNarrative = Substitute.For<ITranslatedNarrative>();
                
                Subject = new BestNarrativeResolver(db);
            }

            public ITranslatedNarrative TranslatedNarrative { get; set; }

            public ISiteControlReader SiteControlReader { get; set; }

            public BestNarrativeResolver Subject { get; }
        }
    }
}