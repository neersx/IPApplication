using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class CaseViewFacts
    {
        public class GetNamesMethod : FactBase
        {
            [Theory]
            [InlineData(KnownNameTypes.Instructor, true)]
            [InlineData(KnownNameTypes.Owner, true)]
            [InlineData(KnownNameTypes.Inventor, true)]
            [InlineData(KnownNameTypes.Signatory, false)]
            [InlineData(KnownNameTypes.Agent, false)]
            [InlineData(KnownNameTypes.StaffMember, false)]
            public async Task GetNamesForExternalUser(string nameTypeCode, bool shouldReturnData)
            {
                var f = new CaseViewFixture(Db)
                        .WithUser(true)
                        .WithCase(out var @case)
                        .WithCaseNames(@case, nameTypeCode, out _);
                var r = (await f.Subject.GetNames(@case.Id)).ToArray();
                Assert.Equal(shouldReturnData ? 1 : 0, r.Length);
            }

            [Theory]
            [InlineData(KnownNameTypes.Instructor, true)]
            [InlineData(KnownNameTypes.Owner, true)]
            [InlineData(KnownNameTypes.Signatory, true)]
            [InlineData(KnownNameTypes.Agent, true)]
            [InlineData(KnownNameTypes.StaffMember, true)]
            [InlineData(KnownNameTypes.Inventor, false)]
            [InlineData(KnownNameTypes.ChallengerOurSide, true)]
            [InlineData(KnownNameTypes.CopiesTo, false)]
            [InlineData(KnownNameTypes.Debtor, false)]
            public async Task GetNamesForInternalUser(string nameTypeCode, bool shouldReturnData)
            {
                var f = new CaseViewFixture(Db)
                        .WithUser()
                        .WithCase(out var @case)
                        .WithCaseNames(@case, nameTypeCode, out _);
                var r = (await f.Subject.GetNames(@case.Id)).ToArray();
                Assert.Equal(shouldReturnData ? 1 : 0, r.Length);
                Assert.True(!shouldReturnData || !r[0].CanView);
            }

            [Theory]
            [InlineData(KnownNameTypes.Instructor, true)]
            [InlineData(KnownNameTypes.Owner, false)]
            [InlineData(KnownNameTypes.Signatory, false)]
            [InlineData(KnownNameTypes.Agent, false)]
            [InlineData(KnownNameTypes.StaffMember, true)]
            [InlineData(KnownNameTypes.ChallengerOurSide, false)]
            public async Task GetFilteredNamesForInternalUser(string nameTypeCode, bool shouldFilter)
            {
                var f = new CaseViewFixture(Db)
                        .WithUser()
                        .WithCase(out var @case)
                        .WithCaseNames(@case, nameTypeCode, out _);
                if (shouldFilter)
                {
                    f.NameFilter.AccessibleNames().ReturnsForAnyArgs(Task.FromResult(new[] {0} as IEnumerable<int>));
                }

                var r = (await f.Subject.GetNames(@case.Id)).ToArray();
                Assert.Single(r);
                Assert.True(!shouldFilter || r[0].CanView);
            }

            [Fact]
            public async Task GetNamesForExternalUserExcludesResponsibilityFor()
            {
                var f = new CaseViewFixture(Db)
                        .WithUser(true)
                        .WithCase(out var @case)
                        .WithCaseNames(@case, KnownNameTypes.Instructor, out _)
                        .WithCaseNames(@case, KnownNameTypes.Owner, out var caseName)
                        .WithAssociatedName(@case, caseName)
                        .WithNameRelation();
                var r = (await f.Subject.GetNames(@case.Id)).ToArray();
                Assert.Equal(2, r.Length);
            }

            [Fact]
            public async Task GetNamesForInternalUserWithResponsibilityFor()
            {
                var f = new CaseViewFixture(Db)
                        .WithUser()
                        .WithCase(out var @case)
                        .WithCaseNames(@case, KnownNameTypes.Agent, out _)
                        .WithCaseNames(@case, KnownNameTypes.Owner, out var caseName)
                        .WithAssociatedName(@case, caseName)
                        .WithNameRelation();
                var r = (await f.Subject.GetNames(@case.Id)).ToArray();
                Assert.Equal(3, r.Length);
            }

            [Fact]
            public async Task GetNamesWithoutAccessReturnEmpty()
            {
                var f = new CaseViewFixture(Db)
                        .WithUser()
                        .WithCase(out var @case)
                        .WithCaseNames(@case, KnownNameTypes.Owner, out var caseName)
                        .WithRestrictedCaseType(@case, KnownNameTypes.Agent, out var nameType)
                        .WithAssociatedName(@case, caseName)
                        .WithNameRelation();
                var r = (await f.Subject.GetNames(@case.Id)).ToArray();
                Assert.Equal(2, r.Length);

                var restrictedName = r.SingleOrDefault(t => t.NameType.Equals(nameType.Name));
                Assert.Null(restrictedName);
            }
        }

        class CaseViewFixture : IFixture<CaseView>
        {
            readonly string _culture = Fixture.String();

            public CaseViewFixture(InMemoryDbContext db)
            {
                Db = db;
                var preferedCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferedCultureResolver.Resolve().Returns(_culture);
                NameFilter = Substitute.For<INameAuthorization>();
                SecurityContext = Substitute.For<ISecurityContext>();
                Subject = new CaseView(Db, SecurityContext, preferedCultureResolver, NameFilter);
            }

            public INameAuthorization NameFilter { get; }

            InMemoryDbContext Db { get; }
            ISecurityContext SecurityContext { get; }
            public CaseView Subject { get; }

            public CaseViewFixture WithUser(bool isExternal = false)
            {
                SecurityContext.User.Returns(new User(Fixture.String(), isExternal));
                return this;
            }

            public CaseViewFixture WithCase(out Case @case)
            {
                @case = new CaseBuilder().Build().In(Db);
                new ValidPropertyBuilder
                {
                    CountryCode = @case.CountryId,
                    CountryName = @case.Country.Name,
                    PropertyTypeId = @case.PropertyType.Code,
                    PropertyTypeName = @case.PropertyType.Name
                }.Build().In(Db);
                return this;
            }

            public CaseViewFixture WithCategory(Case @case, out string categoryDescription)
            {
                var category = new ValidCategoryBuilder
                {
                    Country = @case.Country,
                    PropertyType = @case.PropertyType,
                    CaseCategory = @case.Category,
                    CaseType = @case.Type
                }.Build().In(Db);
                @case.CategoryId = category.CaseCategoryId;
                categoryDescription = category.CaseCategoryDesc;
                return this;
            }

            public CaseViewFixture WithCaseNames(Case @case, string nameTypeCode, out CaseName caseName)
            {
                var nameType = new NameTypeBuilder
                {
                    NameTypeCode = nameTypeCode
                }.Build().In(Db);
                caseName = new CaseNameBuilder(Db) {Case = @case, NameType = nameType}.Build().In(Db);
                new FilteredUserNameTypes
                {
                    Description = nameType.Name,
                    NameType = nameType.NameTypeCode
                }.In(Db);

                NameFilter.AccessibleNames().ReturnsForAnyArgs(Task.FromResult(new[] {caseName.NameId} as IEnumerable<int>));

                return this;
            }

            public CaseViewFixture WithRestrictedCaseType(Case @case, string nameTypeCode, out NameType nameType)
            {
                nameType = new NameTypeBuilder
                {
                    NameTypeCode = nameTypeCode
                }.Build().In(Db);

                new CaseNameBuilder(Db) {Case = @case, NameType = nameType}.Build().In(Db);
                return this;
            }

            public CaseViewFixture WithAssociatedName(Case @case, CaseName caseName)
            {
                new AssociatedNameBuilder(Db)
                {
                    Name = caseName.Name,
                    Relationship = KnownNameRelations.ResponsibilityOf,
                    PropertyType = @case.PropertyType,
                    Sequence = caseName.Sequence
                }.Build().In(Db);
                return this;
            }

            public CaseViewFixture WithNameRelation()
            {
                new NameRelation(
                                 KnownNameRelations.ResponsibilityOf,
                                 Fixture.String("RelationDesc"),
                                 Fixture.String("ReverseDesc"),
                                 Fixture.Decimal(),
                                 null,
                                 new byte()).In(Db);
                return this;
            }
        }

        public class GetSummaryMethod : FactBase
        {
            [Fact]
            public void GetNamesReturnsDataIncludingCaseCategory()
            {
                var f = new CaseViewFixture(Db)
                        .WithCase(out var @case)
                        .WithCategory(@case, out var caseCategory);
                var r = f.Subject.GetSummary(@case.Id).FirstOrDefault();
                Assert.NotNull(r);
                Assert.Equal(@case.PropertyType.Name, r.PropertyType);
                Assert.Equal(@case.Title, r.Title);
                Assert.Equal(caseCategory, r.CaseCategory);
            }

            [Fact]
            public void GetSummaryReturnsData()
            {
                var f = new CaseViewFixture(Db)
                    .WithCase(out var @case);
                var r = f.Subject.GetSummary(@case.Id).FirstOrDefault();
                Assert.NotNull(r);
                Assert.Equal(@case.PropertyType.Name, r.PropertyType);
                Assert.Equal(@case.Title, r.Title);
                Assert.Null(r.CaseCategory);
            }
        }
    }
}