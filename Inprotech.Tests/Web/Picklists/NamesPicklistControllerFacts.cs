using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Name;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using Name = Inprotech.Web.Picklists.Name;

namespace Inprotech.Tests.Web.Picklists
{
    public class NamesPicklistControllerFacts : FactBase
    {
        public class EdeDataSourceNamesMethod : FactBase
        {
            [Fact]
            public void NameAliasDetailsWithMatchSearchCriteria()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var agent = Fixture.String();
                var name1 = new NameBuilder(Db).Build().In(Db);
                var name2 = new NameBuilder(Db).Build().In(Db);
                var aliasType = new NameAliasType
                {
                    Code = KnownAliasTypes.EdeIdentifier
                }.In(Db);

                new NameAlias
                {
                    Alias = agent,
                    AliasType = aliasType,
                    Name = name1
                }.In(Db);

                new NameAlias
                {
                    Alias = agent,
                    AliasType = aliasType,
                    Name = name2
                }.In(Db);

                f.NameAccessSecurity.CanView(name1).ReturnsForAnyArgs(true);

                var result = f.Subject.EdeDataSourceNames("_E", null, name2.LastName);
                var name = (Name) result.Data.Single();
                Assert.Single(result.Data);
                Assert.Equal(name.Key, name2.Id);
                Assert.Equal(name.Code, name2.NameCode);
            }

            [Fact]
            public void ReturnsRowCountWithNameAliasDetails()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var agent = Fixture.String();
                var name1 = new NameBuilder(Db).Build().In(Db);
                var aliasType1 = new NameAliasType
                {
                    Code = KnownAliasTypes.EdeIdentifier
                }.In(Db);

                var aliasType2 = new NameAliasType
                {
                    Code = KnownAliasTypes.FileAgentId
                }.In(Db);

                new NameAlias
                {
                    Alias = agent,
                    AliasType = aliasType1,
                    Name = name1
                }.In(Db);

                new NameAlias
                {
                    Alias = agent,
                    AliasType = aliasType2,
                    Name = name1
                }.In(Db);

                f.NameAccessSecurity.CanView(name1).ReturnsForAnyArgs(true);

                var result = f.Subject.EdeDataSourceNames("_E");
                var name = (Name) result.Data.Single();

                Assert.Equal(name.Key, name1.Id);
                Assert.Equal(name.Code, name1.NameCode);
            }
        }

        public class NamesMethod : FactBase
        {
            [Fact]
            public void ShouldNotReturnCeasedNamesByDefault()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
                var searchString = Fixture.String();
                var filterNameType = Fixture.String();
                var entityTypes = new EntityTypes {IsStaff = Fixture.Boolean()};

                const bool showCeased = false;

                var r = new[]
                {
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = Fixture.Today()
                    },
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = null
                    }
                };

                f.ListName
                 .Get(out _, searchString, filterNameType, entityTypes, showCeased, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take)
                 .Returns(r);

                var pr = f.Subject.Names(qParams, searchString, filterNameType, entityTypes);

                Assert.Null(pr.Data.Cast<Name>().First().Ceased);
                Assert.Null(pr.Data.Cast<Name>().Last().Ceased);
            }

            [Fact]
            public void ShouldPassCorrectQueryParameters()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var qParams = new CommonQueryParameters
                {
                    SortBy = Fixture.String(),
                    SortDir = Fixture.String(),
                    Skip = Fixture.Integer(),
                    Take = Fixture.Integer()
                };

                var searchString = Fixture.String();
                var filterNameType = Fixture.String();
                const bool showCeased = true;
                var entityTypes = new EntityTypes {IsStaff = Fixture.Boolean()};

                f.Subject.Names(qParams, searchString, filterNameType, entityTypes, showCeased);
                f.ListName.Received(1)
                 .Get(out _, searchString, filterNameType, entityTypes, showCeased, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take);
            }

            [Fact]
            public void ShouldReturnCeasedNamesWithDisplayCodeName()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
                var searchString = Fixture.String();
                var filterNameType = Fixture.String();
                var entityTypes = new EntityTypes {IsStaff = Fixture.Boolean()};

                const bool showCeased = false;

                var r = new[]
                {
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = Fixture.Today(),
                        ShowNameCode = 1
                    },
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = null,
                        ShowNameCode = 2
                    },
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = null
                    }
                };

                f.ListName
                 .Get(out _, searchString, filterNameType, entityTypes, showCeased, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take)
                 .Returns(r);

                var results = f.Subject.Names(qParams, searchString, filterNameType, entityTypes).Data.Cast<Name>().ToArray();

                Assert.Equal(1, results.First().PositionToShowCode);
                Assert.Equal(2, results.Skip(1).First().PositionToShowCode);
                Assert.Null(results.Last().PositionToShowCode);
            }

            [Fact]
            public void ShouldReturnCeasedNamesWhenIndicated()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
                var searchString = Fixture.String();
                var filterNameType = Fixture.String();
                var entityTypes = new EntityTypes {IsStaff = Fixture.Boolean()};

                const bool showCeased = true;

                var r = new[]
                {
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = Fixture.Today()
                    },
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = null
                    }
                };

                f.ListName
                 .Get(out _, searchString, filterNameType, entityTypes, showCeased, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take)
                 .Returns(r);

                var pr = f.Subject.Names(qParams, searchString, filterNameType, entityTypes, showCeased);

                Assert.Equal(Fixture.Today(), pr.Data.Cast<Name>().First().Ceased);
                Assert.Null(pr.Data.Cast<Name>().Last().Ceased);
                Assert.False(pr.Data.Cast<Name>().Last().IsGrayedRow);
            }

            [Fact]
            public void ShouldReturnRowCountWithCaseDetails()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var nli = new NameListItem
                {
                    Id = Fixture.Integer(),
                    NameCode = Fixture.String(),
                    DisplayName = Fixture.String(),
                    Remarks = Fixture.String(),
                    CountryCode = "AU",
                    CountryName = Fixture.String()
                };

                f.ListName.Get(out var rc, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<EntityTypes>(), Arg.Any<bool?>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<int?>())
                 .ReturnsForAnyArgs(_ =>
                 {
                     _[0] = rc;
                     return new[] {nli};
                 });

                var result = f.Subject.Names();
                var name = (Name) result.Data.Single();

                Assert.Equal(rc, result.Pagination.Total);
                Assert.Equal(name.Key, nli.Id);
                Assert.Equal(name.Code, nli.NameCode);
                Assert.Equal(name.DisplayName, nli.DisplayName);
                Assert.Equal(name.Remarks, nli.Remarks);
                Assert.Equal(nli.CountryCode, name.CountryCode);
                Assert.Equal(nli.CountryName, name.CountryName);
            }

            [Theory]
            [InlineData(1, true)]
            [InlineData(2, false)]
            public void ShouldReturnSupplierNamesWhenIndicatedTo(int associatedNameIdParam, bool shouldShowAssociatedNames)
            {
                var f = new NamesPicklistControllerFixture(Db);
                var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
                var searchString = Fixture.String();
                var filterNameType = Fixture.String();
                var entityTypes = new EntityTypes {IsSupplier = Fixture.Boolean()};
                var showCeased = Fixture.Boolean();
                const int associatedNameId = 1;

                var r = new[]
                {
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = Fixture.Today()
                    },
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = null
                    }
                };

                f.ListName.Get(out _, searchString, filterNameType, entityTypes, showCeased, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take, associatedNameId).Returns(r);

                var pr = f.Subject.Names(qParams, searchString, filterNameType, entityTypes, showCeased, associatedNameIdParam);

                Assert.Equal(pr.Data.Any(), shouldShowAssociatedNames);
            }
        }

        public class GetNameDetailsMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNamesDetails()
            {
                var f = new NamesPicklistControllerFixture(Db);
                f.SecurityContext.User.Returns(new User("internal", false));

                var name = new NameBuilder(Db).Build().In(Db);
                name.MainEmail().TelecomNumber = Fixture.String();
                name.MainPhone().TelecomNumber = Fixture.String();
                name.ClientDetail = new ClientDetailBuilder().BuildForName(name).In(Db);

                var result = f.Subject.GetNameDetails(name.Id);

                Assert.Equal(result.DisplayName, name.Formatted());
                Assert.Equal(result.MainEmail, name.MainEmail().TelecomNumber);
                Assert.Equal(result.MainPhone, name.MainPhone().TelecomNumber);
                Assert.False(result.DebtorRestrictionFlag);
            }

            [Fact]
            public void ShouldNotReturnSomeDetailsWhenExternalUserLogin()
            {
                var f = new NamesPicklistControllerFixture(Db);
                f.SecurityContext.User.Returns(new User("external", true));

                var name = new NameBuilder(Db).As(KnownNameTypeAllowedFlags.StaffNames).Build().In(Db);
                name.MainEmail().TelecomNumber = Fixture.String();
                name.MainPhone().TelecomNumber = Fixture.String();
                name.StreetAddressId = new AddressBuilder().Build().In(Db).Id;
                name.DateCeased = Fixture.PastDate();
                name.NameFamily = new NameFamily {Id = Fixture.Short(), FamilyTitle = Fixture.String()}.In(Db);
                name.ClientDetail = new ClientDetailBuilder().BuildForName(name).In(Db);

                var result = f.Subject.GetNameDetails(name.Id);

                Assert.Null(result.StreetAddress);
                Assert.Null(result.StartDate);
                Assert.Null(result.DateCeased);
                Assert.Null(result.StaffClassification);
                Assert.Null(result.ProfitCenter);
                Assert.Null(result.Group);
            }

            [Fact]
            public void ShouldReturnIndividualDetails()
            {
                var f = new NamesPicklistControllerFixture(Db);
                f.SecurityContext.User.Returns(new User("internal", false));

                var country = new CountryBuilder {Id = "YY"}.Build().In(Db);
                var name = new NameBuilder(Db) {UsedAs = NameUsedAs.Individual, Nationality = country, Remarks = Fixture.String(), TaxNumber = Fixture.String()}.WithFamily().Build().In(Db);

                new Employee {Id = name.Id}.In(Db);
                name.ClientDetail = new ClientDetailBuilder().BuildForName(name).In(Db);
                name.Organisation = new OrganisationBuilder {Incorporated = Fixture.String(), RegistrationNo = Fixture.String(), NameNo = name.Id}.BuildForName(name).In(Db);

                var result = f.Subject.GetNameDetails(name.Id);

                Assert.True(result.IsIndividual);
                Assert.False(result.IsStaff);
                Assert.False(result.IsOrganisation);
                Assert.Equal(result.Nationality, name.Nationality.Id);
                Assert.Equal(result.TaxNo, name.TaxNumber);
                Assert.Equal(result.Group, name.NameFamily.FamilyTitle);
                Assert.Equal(result.Remarks, name.Remarks);
            }

            [Fact]
            public void ShouldReturnLeadDetails()
            {
                var f = new NamesPicklistControllerFixture(Db);
                f.SecurityContext.User.Returns(new User("internal", false));

                var country = new CountryBuilder {Id = "YY"}.Build().In(Db);
                var name = new NameBuilder(Db) {UsedAs = NameUsedAs.Individual, Nationality = country, Remarks = Fixture.String(), TaxNumber = Fixture.String()}.WithFamily().Build().In(Db);
                var tc = new TableCodeBuilder().Build().In(Db);
                var tc1 = new TableCodeBuilder().Build().In(Db);
                var relName = new NameBuilder(Db).Build().In(Db);
                new TopicSecurity {TopicKey = Fixture.Integer(), IsAvailable = true}.In(Db);
                var leadDetails = new LeadDetails(name) {LeadSource = tc.Id, Comments = Fixture.String(), EstimatedRevLocal = Fixture.Decimal()}.In(Db);
                new LeadStatusHistory(name) {LeadStatus = tc1.Id, Name = name, LOGDATETIMESTAMP = Fixture.Date()}.In(Db);
                var an = new AssociatedNameBuilder(Db) {Name = name, RelatedName = relName, Sequence = 0, Relationship = KnownNameRelations.ResponsibilityOf}.Build().In(Db);
                name.ClientDetail = new ClientDetailBuilder().BuildForName(name).In(Db);
                name.Organisation = new OrganisationBuilder {Incorporated = Fixture.String(), RegistrationNo = Fixture.String(), NameNo = name.Id}.BuildForName(name).In(Db);

                var result = f.Subject.GetLeadDetails(name.Id);

                Assert.Equal(result.LeadOwner, an.RelatedName.Formatted());
                Assert.Equal(result.LeadSource, tc.Name);
                Assert.Equal(result.Comments, leadDetails.Comments);
                Assert.Equal(result.EstRevenue, leadDetails.EstimatedRevLocal);
                Assert.Equal(result.LeadStatus, tc1.Name);
            }

            [Fact]
            public void ShouldReturnNullWithNoTaskAccess()
            {
                var f = new NamesPicklistControllerFixture(Db);
                f.SecurityContext.User.Returns(new User("internal", false));

                var country = new CountryBuilder {Id = "YY"}.Build().In(Db);
                var name = new NameBuilder(Db) {UsedAs = NameUsedAs.Individual, Nationality = country, Remarks = Fixture.String(), TaxNumber = Fixture.String()}.WithFamily().Build().In(Db);
                var result = f.Subject.GetLeadDetails(name.Id);
                Assert.Equal(result, null);
            }

            [Fact]
            public void ShouldReturnOrganisationDetails()
            {
                var f = new NamesPicklistControllerFixture(Db);
                f.SecurityContext.User.Returns(new User("internal", false));

                var name = new NameBuilder(Db) {UsedAs = NameUsedAs.Organisation}.Build().In(Db);

                new Employee {Id = name.Id}.In(Db);

                name.MainEmail().TelecomNumber = Fixture.String();
                name.MainPhone().TelecomNumber = Fixture.String();
                name.MainContact = new NameBuilder(Db).Build();
                name.ClientDetail = new ClientDetailBuilder().BuildForName(name).In(Db);
                name.Organisation = new OrganisationBuilder {Incorporated = Fixture.String(), RegistrationNo = Fixture.String(), NameNo = name.Id}.BuildForName(name).In(Db);

                var result = f.Subject.GetNameDetails(name.Id);

                Assert.True(result.IsOrganisation);
                Assert.False(result.IsStaff);
                Assert.False(result.IsIndividual);
                Assert.Equal(result.CompanyNo, name.Organisation.RegistrationNo);
                Assert.Equal(result.Incorporated, name.Organisation.Incorporated);
                Assert.Equal(result.ParentEntity, name.Organisation.Parent?.Formatted());
            }

            [Fact]
            public void ShouldReturnFilesInDetails()
            {
                var f = new NamesPicklistControllerFixture(Db);
                f.SecurityContext.User.Returns(new User("internal", false));

                var name = new NameBuilder(Db).Build().In(Db);

                var ct1 = new CountryBuilder {Name = Fixture.String("xyz")}.Build().In(Db);
                var ct2 = new CountryBuilder{Name = Fixture.String("abc")}.Build().In(Db);
                new FilesIn {NameId = name.Id, Jurisdiction = ct1}.In(Db);
                new FilesIn {NameId = name.Id, Jurisdiction = ct2}.In(Db);
                
                var result = f.Subject.GetNameDetails(name.Id);

                Assert.Equal(result.FilesIn, $"{ct2.Name}, {ct1.Name}");
            }
        }

        public class NamesWithTimesheetViewAccessMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallGetSpecificNamesToFetchNames()
            {
                var f = new NamesPicklistControllerFixture(Db);
                var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
                var searchString = Fixture.String();
                var entityTypes = new EntityTypes {IsStaff = true};
                var staffIds = new[] {1, 2, 3};
                f.ViewAccessResolver.Resolve().ReturnsForAnyArgs(staffIds);
                f.VersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(false);

                var r = new[]
                {
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = Fixture.Today(),
                        ShowNameCode = 1
                    },
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = null,
                        ShowNameCode = 2
                    },
                    new NameListItem
                    {
                        DisplayName = Fixture.String(),
                        Id = Fixture.Integer(),
                        NameCode = Fixture.String(),
                        Remarks = Fixture.String(),
                        DateCeased = null
                    }
                };

                f.ListName
                 .GetSpecificNames(out _, Arg.Any<string>(), Arg.Any<EntityTypes>(), Arg.Any<List<int>>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), false)
                 .ReturnsForAnyArgs(r);

                var results = (await f.Subject.NamesWithTimesheetViewAccess(qParams, searchString)).Data.Cast<Name>().ToArray();
                f.ViewAccessResolver.Received(1).Resolve().IgnoreAwaitForNSubstituteAssertion();
                f.VersionChecker.Received(1).CheckMinimumVersion(Arg.Is(14));
                f.ListName.Received(1).GetSpecificNames(out _, Arg.Is(searchString), Arg.Do<EntityTypes>(e => { Assert.Equal(e, entityTypes); }), Arg.Do<List<int>>(s => { Assert.Equal(s, staffIds); }), Arg.Is(qParams.SortBy), Arg.Is(qParams.SortDir), Arg.Is(qParams.Skip), Arg.Is(qParams.Take), Arg.Is(false));

                Assert.Equal(1, results.First().PositionToShowCode);
                Assert.Equal(2, results.Skip(1).First().PositionToShowCode);
                Assert.Null(results.Last().PositionToShowCode);
            }
        }

        public class NamesPicklistControllerFixture : IFixture<NamesPicklistController>
        {
            public NamesPicklistControllerFixture(InMemoryDbContext db)
            {
                ListName = Substitute.For<IListName>();
                NameAccessSecurity = Substitute.For<INameAccessSecurity>();
                SecurityContext = Substitute.For<ISecurityContext>();
                Now = Substitute.For<Func<DateTime>>();
                VersionChecker = Substitute.For<IInprotechVersionChecker>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                ViewAccessResolver = Substitute.For<IViewAccessAllowedStaffResolver>();

                Subject = new NamesPicklistController(ListName, db, NameAccessSecurity, SecurityContext, Now, VersionChecker, PreferredCultureResolver, ViewAccessResolver);
            }

            public Func<DateTime> Now { get; set; }
            public IListName ListName { get; set; }
            public INameAccessSecurity NameAccessSecurity { get; }
            public ISecurityContext SecurityContext { get; }
            public IInprotechVersionChecker VersionChecker { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public IViewAccessAllowedStaffResolver ViewAccessResolver { get; }
            public NamesPicklistController Subject { get; }
        }
    }
}