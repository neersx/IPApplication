using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Tests.Web.Search.CaseSupportData;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class PropertyTypesFacts : FactBase
    {
        [Fact]
        public void ReturnsValidPropertiesForCountry()
        {
            var f = new PropertyTypesFixture(Db);

            var validProperty = new ValidProperty {PropertyType = new PropertyType("1", Fixture.UniqueName()), CountryId = "c1", PropertyName = "a"}.In(Db);
            validProperty.PropertyTypeId = validProperty.PropertyType.Code;

            var results = f.Subject.Get(string.Empty, new[] {"c1"}).ToArray();

            Assert.Single(results);
            Assert.Equal("1", results.Single().Key);
        }

        [Fact]
        public void ShouldFilterByQuery()
        {
            var f = new PropertyTypesFixture(Db);

            new ValidProperty {PropertyType = new PropertyType("1", Fixture.UniqueName()), CountryId = "c1", PropertyName = "a"}.In(Db);
            new ValidProperty {PropertyType = new PropertyType("2", Fixture.UniqueName()), CountryId = "c1", PropertyName = "b"}.In(Db);

            var results = f.Subject.Get("a", new[] {"c1"});

            Assert.Single(results);
        }

        [Fact]
        public void ShouldForwardCorrectSqlParametersToCommandForPropertyType()
        {
            var f = new PropertyTypesFixture(null, false);
            var user = new UserBuilder(Db) {IsExternalUser = true}.Build();
            f.WithUser(user)
             .WithCulture("a")
             .WithSqlResults<PropertyTypeListItem>();

            f.Subject.Get(null, null);

            f.DbContext
             .Received(1)
             .SqlQuery<PropertyTypeListItem>(
                                             FixtureBase.ListCaseSupportCommand,
                                             user.Id,
                                             "a",
                                             "PropertyTypeWithCRM",
                                             null,
                                             1,
                                             user.IsExternalUser);
        }

        [Fact]
        public void ShouldReturnAllByDefault()
        {
            var f = new PropertyTypesFixture(null, false);

            f.WithUser(new UserBuilder(Db).Build())
             .WithCulture(string.Empty)
             .WithSqlResults(new PropertyTypeListItem
             {
                 PropertyTypeKey = "1",
                 PropertyTypeDescription = "ab",
                 CountryKey = "c1",
                 IsDefaultCountry = 1
             }, new PropertyTypeListItem
             {
                 PropertyTypeKey = "2",
                 PropertyTypeDescription = "cd",
                 CountryKey = "c2",
                 IsDefaultCountry = 0
             });

            var results = f.Subject.Get(null, null);

            Assert.Equal(2, results.Count());
        }

        [Fact]
        public void ShouldReturnBasePropertyTypeDescriptionWhenNotMatched()
        {
            var f = new PropertyTypesFixture(Db);

            var p1 = new ValidProperty {PropertyType = new PropertyType("1", Fixture.UniqueName()), CountryId = "c1", PropertyName = "a"}.In(Db);
            var p2 = new PropertyType("2", Fixture.UniqueName()).In(Db);

            var @case = new CaseBuilder().Build().In(Db);
            @case.Country = new Country(p1.CountryId, Fixture.String()).In(Db);
            @case.PropertyType = p2;

            var result = f.Subject.GetCasePropertyType(@case);

            Assert.Equal(p2.Name, result);
        }

        [Fact]
        public void ShouldReturnValidPropertyTypeDescriptionWhenMatched()
        {
            var f = new PropertyTypesFixture(Db);

            var p1 = new ValidProperty {PropertyType = new PropertyType("1", Fixture.UniqueName()), CountryId = "c1", PropertyName = "a", PropertyTypeId = "1"}.In(Db);
            new ValidProperty {PropertyType = new PropertyType("2", Fixture.UniqueName()), CountryId = "c1", PropertyName = "b", PropertyTypeId = "2"}.In(Db);

            var @case = new CaseBuilder().Build().In(Db);
            @case.Country = new Country(p1.CountryId, Fixture.String()).In(Db);
            @case.PropertyType = p1.PropertyType;

            var result = f.Subject.GetCasePropertyType(@case);

            Assert.Equal(p1.PropertyName, result);
        }

        [Fact]
        public void UsesDefaultCountryIfNoValidProperties()
        {
            var f = new PropertyTypesFixture(Db);

            var validProperty = new ValidProperty {PropertyType = new PropertyType("1", Fixture.UniqueName()), CountryId = "ZZZ", PropertyName = "a"}.In(Db);
            validProperty.PropertyTypeId = validProperty.PropertyType.Code;

            var r = f.Subject.Get(string.Empty, new[] {"c3"}).Single();

            Assert.Equal("1", r.Key);
        }
    }

    public class PropertyTypesFixture : FixtureBase, IFixture<IPropertyTypes>
    {
        public PropertyTypesFixture(InMemoryDbContext db, bool useInMemoryDb = true)
        {
            UserAccessSecurity = Substitute.For<IUserAccessSecurity>();

            Subject = new PropertyTypes(
                                        useInMemoryDb ? db : DbContext,
                                        SecurityContext,
                                        PreferredCultureResolver,
                                        UserAccessSecurity,
                                        FilterPropertyTypeByRowAcces);
        }

        public IUserAccessSecurity UserAccessSecurity { get; set; }
        public IFilterPropertyType FilterPropertyTypeByRowAcces { get; set; }
        public IPropertyTypes Subject { get; }
    }

    public class FilterPropertyTypeFacts : FactBase
    {
        [Fact]
        public void RowAccessSecurityShouldReturnOnlyValidProperty()
        {
            var f = new FilterPropertyTypeFixture();

            var validProperty1 = new ValidProperty {PropertyType = new PropertyType("1", Fixture.UniqueName()), CountryId = "c1", PropertyName = "a", PropertyTypeId = "1"}.In(Db);
            validProperty1.PropertyTypeId = validProperty1.PropertyType.Code;

            var validProperty2 = new ValidProperty {PropertyType = new PropertyType("2", Fixture.UniqueName()), CountryId = "c1", PropertyName = "b", PropertyTypeId = "2"}.In(Db);
            validProperty2.PropertyTypeId = validProperty2.PropertyType.Code;

            f.UserAccessSecurity.HasRowAccessSecurity(string.Empty).ReturnsForAnyArgs(true);
            f.UserAccessSecurity.CurrentUserRowAccessDetails(string.Empty, 0)
             .ReturnsForAnyArgs(new[]
                                    {
                                        new RowAccessDetail {PropertyType = new PropertyType("1", "A")}
                                    });

            var d = new List<ValidProperty> {validProperty1, validProperty2}.AsQueryable();

            var results = f.Subject.FilterPropertyTypesByRowAccess(d);

            Assert.Equal(1, results.Count());
        }

        [Fact]
        public void ShouldNotFilterIfCurrentUserHasAnyRowAccessPropertyTypeNull()
        {
            var f = new FilterPropertyTypeFixture();

            var validProperty1 = new ValidProperty {PropertyType = new PropertyType("1", Fixture.UniqueName()), CountryId = "c1", PropertyName = "a"}.In(Db);
            var validProperty2 = new ValidProperty {PropertyType = new PropertyType("2", Fixture.UniqueName()), CountryId = "c1", PropertyName = "b"}.In(Db);

            f.UserAccessSecurity.HasRowAccessSecurity(string.Empty).ReturnsForAnyArgs(true);
            f.UserAccessSecurity.CurrentUserRowAccessDetails(string.Empty, 0)
             .ReturnsForAnyArgs(new[]
             {
                 new RowAccessDetail {PropertyType = new PropertyType("1", "A")},
                 new RowAccessDetail {PropertyType = null}
             });

            var d = new List<ValidProperty> {validProperty1, validProperty2}.AsQueryable();
            var results = f.Subject.FilterPropertyTypesByRowAccess(d);

            Assert.Equal(2, results.Count());
        }
    }

    public class FilterPropertyTypeFixture : IFixture<IFilterPropertyType>
    {
        public FilterPropertyTypeFixture()
        {
            UserAccessSecurity = Substitute.For<IUserAccessSecurity>();
            Subject = new FilterPropertyType(UserAccessSecurity);
        }

        public IUserAccessSecurity UserAccessSecurity { get; set; }
        public IFilterPropertyType Subject { get; set; }
    }
}