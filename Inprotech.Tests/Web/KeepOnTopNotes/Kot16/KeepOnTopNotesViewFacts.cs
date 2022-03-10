using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.KeepOnTopNotes;
using Inprotech.Web.KeepOnTopNotes.Kot16;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.KeepOnTopNotes.Kot16
{
    public class KeepOnTopNotesViewFacts
    {
        static dynamic SetupCaseKotNotes(InMemoryDbContext db, bool isRolesSetup = false, bool isKotTextTypeWithNoProgram = false)
        {
            var tt1 = new TextTypeBuilder().Build().In(db);
            var tt2 = new TextTypeBuilder().Build().In(db);

            var kot1 = new KeepOnTopTextType {TextTypeId = tt1.Id, TextType = tt1, CaseProgram = !isKotTextTypeWithNoProgram, TaskPlannerProgram = true, NameProgram = false, TimeProgram = false, IsRegistered = true, IsPending = true, IsDead = false, Type = KnownKotTypes.Case, BackgroundColor = "#00FF00"}.In(db);
            var kot2 = new KeepOnTopTextType {TextTypeId = tt2.Id, TextType = tt2, CaseProgram = !isKotTextTypeWithNoProgram, TaskPlannerProgram = false, IsPending = true, IsDead = false, Type = KnownKotTypes.Case}.In(db);

            if (isRolesSetup)
            {
                var role1 = db.Set<Role>().FirstOrDefault(_ => _.Id == 1);
                var kotRole = new KeepOnTopRole {Role = role1, KotTextType = kot1}.In(db);
                kot1.KotRoles = new List<KeepOnTopRole>
                {
                    kotRole
                };
                var role2 = new Role().In(db);
                var kotRole2 = new KeepOnTopRole {Role = role2, KotTextType = kot2}.In(db);
                kot2.KotRoles = new List<KeepOnTopRole>
                {
                    kotRole2
                };
            }

            var caseType1 = new CaseTypeBuilder {Id = "A"}.Build().In(db);
            var caseType2 = new CaseTypeBuilder {Id = "B"}.Build().In(db);
            var kotCt1 = new KeepOnTopCaseType {CaseTypeId = caseType1.Code, CaseType = caseType1, KotTextTypeId = kot1.Id}.In(db);
            var kotCt2 = new KeepOnTopCaseType {CaseTypeId = caseType2.Code, CaseType = caseType2, KotTextTypeId = kot1.Id}.In(db);

            kot1.KotCaseTypes = new List<KeepOnTopCaseType>
            {
                kotCt1,
                kotCt2
            };

            var @case = new CaseBuilder
            {
                Country = new CountryBuilder {Id = "ZZZ"}.Build().In(db),
                CaseType = caseType1,
                PropertyType = new PropertyTypeBuilder {Id = "P"}.Build().In(db),
                Status = new Status {LiveFlag = 1}.In(db),
                SubType = new SubType {Code = "A"}
            }.Build().In(db);

            var caseText1 = new CaseText(@case.Id, tt1.Id, 0, "01")
            {
                Language = null,
                Text = Fixture.String("first"),
                TextType = tt1
            }.In(db);

            var caseText2 = new CaseText(@case.Id, tt2.Id, 0, "02")
            {
                Language = null,
                Text = Fixture.String("Second"),
                TextType = tt1
            }.In(db);
            @case.CaseStatus = null;
            return new {@case, kot1, kot2, caseText1, caseText2};
        }

        static dynamic SetupCaseNamesKotData(InMemoryDbContext db, bool isCrmOnly = false, bool setupCorrespondenceData = false)
        {
            var tt1 = new TextType(Fixture.String()).In(db);
            var tt2 = setupCorrespondenceData ? new TextType {Id = "CB", TextDescription = Fixture.String()}.In(db) : new TextType(Fixture.String()).In(db);

            var @case = new CaseBuilder
            {
                Country = new CountryBuilder {Id = "ZZZ"}.Build().In(db),
                CaseType = new CaseType {ActualCaseTypeId = "A", Code = "A"}.In(db),
                PropertyType = new PropertyTypeBuilder {Id = "P"}.Build().In(db)
            }.Build().In(db);

            var nameType = new NameTypeBuilder().Build().In(db);
            var nameType2 = new NameTypeBuilder().Build().In(db);
            var caseName = new CaseNameBuilder(db) {NameType = nameType}.BuildWithCase(@case).In(db);
            var caseName2 = new CaseNameBuilder(db) {NameType = nameType2}.BuildWithCase(@case).In(db);
            var nameText = new NameText {Id = caseName.Name.Id, TextType = tt1.Id, Text = Fixture.String()}.In(db);
            var nameText2 = new NameText {Id = caseName2.Name.Id, TextType = tt2.Id, Text = Fixture.String()}.In(db);
            var kot1 = new KeepOnTopTextType {TextTypeId = tt1.Id, TextType = tt1, CaseProgram = true, NameProgram = false, TimeProgram = false, Type = KnownKotTypes.Name, BackgroundColor = "#00FF00"}.In(db);
            var kot2 = new KeepOnTopTextType {TextTypeId = tt2.Id, TextType = tt2, CaseProgram = true, TaskPlannerProgram = false, Type = KnownKotTypes.Name}.In(db);
            var kotNt1 = new KeepOnTopNameType {NameTypeId = nameType.NameTypeCode, NameType = nameType, KotTextTypeId = kot1.Id}.In(db);
            var kotNt2 = new KeepOnTopNameType {NameTypeId = nameType2.NameTypeCode, NameType = nameType2, KotTextTypeId = kot2.Id}.In(db);

            kot1.KotNameTypes = new List<KeepOnTopNameType>
            {
                kotNt1
            };

            kot2.KotNameTypes = new List<KeepOnTopNameType>
            {
                kotNt2
            };

            if (isCrmOnly)
            {
                @case.Type.CrmOnly = true;
                // inMemory string to be picked up by GetScreenControlNameTypes
                new[]
                {
                    nameType.NameTypeCode
                }.In(db);
            }

            return new {@case, nameType, nameType2, nameText, nameText2};
        }

        static dynamic SetupNameKotNotes(InMemoryDbContext db, bool setupCorrespondenceData = false, bool isRolesSetup = false, bool isKotTextTypeWithNoProgram = false)
        {
            var tt1 = new TextType(Fixture.String()).In(db);
            var tt2 = setupCorrespondenceData ? new TextType {Id = "CB", TextDescription = Fixture.String()}.In(db) : new TextType(Fixture.String()).In(db);

            var name = new NameBuilder(db).Build().In(db);
            var cd = new ClientDetail {Id = name.Id, Correspondence = Fixture.String("correspondence")}.In(db);
            name.ClientDetail = cd;

            var @case = new CaseBuilder
            {
                Country = new CountryBuilder {Id = "ZZZ"}.Build().In(db),
                CaseType = new CaseType {ActualCaseTypeId = "A", Code = "A"}.In(db),
                PropertyType = new PropertyTypeBuilder {Id = "P"}.Build().In(db)
            }.Build().In(db);

            var nameType = new NameTypeBuilder().Build().In(db);
            var nameType2 = new NameTypeBuilder().Build().In(db);

            var caseName = new CaseNameBuilder(db) {NameType = nameType, Name = name}.BuildWithCase(@case).In(db);
            var caseName2 = new CaseNameBuilder(db) {NameType = nameType2, Name = name}.BuildWithCase(@case).In(db);

            var nameText = new NameText {Id = name.Id, TextType = tt1.Id, Text = Fixture.String()}.In(db);
            var nameText2 = setupCorrespondenceData ? null : new NameText {Id = name.Id, TextType = tt2.Id, Text = Fixture.String()}.In(db);

            var kot1 = new KeepOnTopTextType {TextTypeId = tt1.Id, TextType = tt1, CaseProgram = false, NameProgram = true, TimeProgram = false, Type = KnownKotTypes.Name, BackgroundColor = "#00FF00"}.In(db);
            var kot2 = new KeepOnTopTextType {TextTypeId = tt2.Id, TextType = tt2, CaseProgram = false, NameProgram = !isKotTextTypeWithNoProgram, TaskPlannerProgram = false, Type = KnownKotTypes.Name}.In(db);
            var kotNt1 = new KeepOnTopNameType {NameTypeId = nameType.NameTypeCode, NameType = nameType, KotTextTypeId = kot1.Id}.In(db);
            var kotNt2 = new KeepOnTopNameType {NameTypeId = nameType2.NameTypeCode, NameType = nameType2, KotTextTypeId = kot2.Id}.In(db);

            kot1.KotNameTypes = new List<KeepOnTopNameType>
            {
                kotNt1
            };

            kot2.KotNameTypes = new List<KeepOnTopNameType>
            {
                kotNt2
            };

            if (isRolesSetup)
            {
                var role1 = db.Set<Role>().FirstOrDefault(_ => _.Id == 1);
                var kotRole = new KeepOnTopRole {Role = role1, KotTextType = kot1}.In(db);
                kot1.KotRoles = new List<KeepOnTopRole>
                {
                    kotRole
                };
            }

            return new {@case, nameType, nameType2, nameText, nameText2, caseName, caseName2, name};
        }

        public class GetKotNotesForCase : FactBase
        {
            [Fact]
            public async Task ReturnEmptyResultSetForCaseWhenNoData()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db).WithUserAndRole(Db);
                var results = await f.Subject.GetKotNotesForCase(1, KnownKotModules.Case);
                Assert.Empty(results);
            }

            [Fact]
            public async Task ReturnsAllKotNotesCase()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db).WithUserAndRole(Db);
                var data = SetupCaseKotNotes(Db);
                var kot1 = (KeepOnTopTextType) data.kot1;
                var kotCase = (Case) data.@case;
                var results = await f.Subject.GetKotNotesForCase(kotCase.Id, KnownKotModules.Case);
                var r = results.ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal(kot1.BackgroundColor, r[0].BackgroundColor);
                Assert.Equal(kotCase.Irn, r[0].CaseRef);
                Assert.True(r[0].Note.Contains("first"));
                Assert.Null(r[1].BackgroundColor);
                Assert.True(r[1].Note.Contains("Second"));
            }

            [Fact]
            public async Task ReturnsAllKotNotesCaseForTaskPlanner()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db).WithUserAndRole(Db);
                var data = SetupCaseKotNotes(Db, false, false);
                var kot1 = (KeepOnTopTextType) data.kot1;
                var kotCase = (Case) data.@case;
                var results = await f.Subject.GetKotNotesForCase(kotCase.Id, "TaskPlanner");
                var r = results.ToArray();
                Assert.Equal(1, r.Length);
                Assert.Equal(kot1.BackgroundColor, r[0].BackgroundColor);
                Assert.Equal(kotCase.Irn, r[0].CaseRef);
            }

            [Fact]
            public async Task ReturnsNoKotNotesWhenProgramIsNotSet()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db).WithUserAndRole(Db);
                var data = SetupCaseKotNotes(Db, false, true);
                var kotCase = (Case) data.@case;
                var results = await f.Subject.GetKotNotesForCase(kotCase.Id, KnownKotModules.Case);
                var r = results.ToArray();
                Assert.Equal(0, r.Length);
            }

            [Fact]
            public async Task ShouldReturnAllNotesIfNoRoleExistsForInternalUser()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db)
                    .WithUserAndRole(Db);
                var data = SetupCaseKotNotes(Db);
                var kotCase = (Case) data.@case;
                var results = await f.Subject.GetKotNotesForCase(kotCase.Id, KnownKotModules.Case);

                Assert.Equal(2, results.ToArray().Length);
            }

            [Fact]
            public async Task ShouldReturnNoNotesIfNoRoleExistsForExternalUser()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db)
                    .WithUserAndRole(Db, true);
                var data = SetupCaseKotNotes(Db);
                var kotCase = (Case) data.@case;
                var results = await f.Subject.GetKotNotesForCase(kotCase.Id, KnownKotModules.Case);

                Assert.Empty(results);
            }

            [Fact]
            public async Task ShouldReturnNotesForCrmOnlyNames()
            {
                var data = SetupCaseNamesKotData(Db, true);
                var f = new KeepOnTopNotes16ViewFixture(Db)
                        .WithUserAndRole(Db)
                        .WithCaseNames(data.nameType)
                        .WithCaseNames(data.nameType2);
                var r = (IEnumerable<KotNotesItem>) await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(1, a.Length);
                Assert.False(a[0].Expanded);
                Assert.Equal(data.nameText.Text, a[0].Note);
                Assert.Equal(data.nameType.Name, a[0].NameTypes);
            }

            [Fact]
            public async Task ShouldReturnNotesForMatchedRoles()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db)
                    .WithUserAndRole(Db);
                var data = SetupCaseKotNotes(Db, true);
                var kot1 = (KeepOnTopTextType) data.kot1;
                var kotCase = (Case) data.@case;
                var results = await f.Subject.GetKotNotesForCase(kotCase.Id, KnownKotModules.Case);
                var r = results.ToArray();
                Assert.Equal(1, r.Length);
                Assert.Equal(kot1.BackgroundColor, r[0].BackgroundColor);
                Assert.Equal(kotCase.Irn, r[0].CaseRef);
            }

            [Fact]
            public async Task ShouldReturnNotesForNameCorrespondenceData()
            {
                var data = SetupCaseNamesKotData(Db, false, true);
                var f = new KeepOnTopNotes16ViewFixture(Db)
                        .WithUserAndRole(Db)
                        .WithCaseNames(data.nameType)
                        .WithCaseNames(data.nameType2);

                var r = (IEnumerable<KotNotesItem>) await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(2, a.Length);
                Assert.Equal(data.nameText2.Text, a[1].Note);
                Assert.Equal(data.nameType2.Name, a[1].NameTypes);
            }

            [Fact]
            public async Task ShouldReturnNotesForNamesOnly()
            {
                var data = SetupCaseNamesKotData(Db);
                var f = new KeepOnTopNotes16ViewFixture(Db)
                        .WithUserAndRole(Db)
                        .WithCaseNames(data.nameType)
                        .WithCaseNames(data.nameType2);

                var r = (IEnumerable<KotNotesItem>) await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(2, a.Length);
                Assert.False(a[0].Expanded);
                Assert.Equal(data.nameText.Text, a[0].Note);
                Assert.Equal(data.nameType.Name, a[0].NameTypes);
                Assert.Equal("#00FF00", a[0].BackgroundColor);
                Assert.Equal(false, a[1].Expanded);
                Assert.Equal(data.nameText2.Text, a[1].Note);
                Assert.Equal(data.nameType2.Name, a[1].NameTypes);
            }
        }

        public class GetKotNotesForName : FactBase
        {
            [Fact]
            public async Task ReturnEmptyResultSetForNameWhenNoData()
            {
                var f = new KeepOnTopNotes16ViewFixture(Db).WithUserAndRole(Db);
                var results = await f.Subject.GetKotNotesForName(Fixture.Integer(), KnownKotModules.Name);
                Assert.Empty(results);
            }

            [Fact]
            public async Task ShouldReturnNoNotesIfNoRoleExistsForExternalUser()
            {
                var data = SetupNameKotNotes(Db);
                var f = new KeepOnTopNotes16ViewFixture(Db)
                    .WithUserAndRole(Db, true);

                var results = await f.Subject.GetKotNotesForName(data.name.Id, KnownKotModules.Name);

                Assert.Empty(results);
            }

            [Fact]
            public async Task ShouldReturnNotesForNameCorrespondenceData()
            {
                var data = SetupNameKotNotes(Db, true);
                var f = new KeepOnTopNotes16ViewFixture(Db)
                    .WithUserAndRole(Db);

                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var r = (IEnumerable<KotNotesItem>) await f.Subject.GetKotNotesForName(data.name.Id, KnownKotModules.Name);
                var a = r.ToArray();
                Assert.Equal(2, a.Length);
                Assert.False(a[0].Expanded);
                Assert.Equal(data.nameText.Text, a[0].Note);
                Assert.Equal(data.nameType.Name, a[0].NameTypes);
                Assert.Equal(formatted[data.name.Id].Name, a[0].Name);
                Assert.True(a[1].Note.Contains("correspondence"));
                Assert.Equal(data.nameType2.Name, a[1].NameTypes);
            }

            [Fact]
            public async Task ShouldReturnNotesForNamesOnly()
            {
                var data = SetupNameKotNotes(Db);
                var f = new KeepOnTopNotes16ViewFixture(Db)
                    .WithUserAndRole(Db);

                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    }
                };

                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var r = (IEnumerable<KotNotesItem>) await f.Subject.GetKotNotesForName(data.name.Id, KnownKotModules.Name);
                var a = r.ToArray();
                Assert.Equal(2, a.Length);
                Assert.False(a[0].Expanded);
                Assert.Equal(data.nameText.Text, a[0].Note);
                Assert.Equal(data.nameType.Name, a[0].NameTypes);
                Assert.Equal("#00FF00", a[0].BackgroundColor);
                Assert.Equal(formatted[data.name.Id].Name, a[0].Name);
            }

            [Fact]
            public async Task ShouldReturnNotesForNamesWithProgramsOnly()
            {
                var data = SetupNameKotNotes(Db, false, true);
                var f = new KeepOnTopNotes16ViewFixture(Db)
                    .WithUserAndRole(Db);

                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    }
                };

                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var r = (IEnumerable<KotNotesItem>) await f.Subject.GetKotNotesForName(data.name.Id, KnownKotModules.Name);
                var a = r.ToArray();
                Assert.Equal(1, a.Length);
                Assert.False(a[0].Expanded);
                Assert.Equal(formatted[data.name.Id].Name, a[0].Name);
            }
        }
    }

    public class KeepOnTopNotes16ViewFixture : IFixture<KeepOnTopNotesView>
    {
        readonly string _culture = Fixture.String();

        public KeepOnTopNotes16ViewFixture(InMemoryDbContext db)
        {
            Db = db;
            SecurityContext = Substitute.For<ISecurityContext>();
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            preferredCultureResolver.Resolve().Returns(_culture);
            SiteControlReader = Substitute.For<ISiteControlReader>();
            DisplayFormattedName = Substitute.For<IDisplayFormattedName>();

            var user = UserBuilder.AsInternalUser(db).Build();

            var role1 = new Role(1) {RoleName = Fixture.String()}.In(db);
            new Role(2) {RoleName = Fixture.String()}.In(db);

            user.Roles.Add(role1);
            SecurityContext.User.Returns(user);

            Subject = new KeepOnTopNotesView(db, preferredCultureResolver, SiteControlReader, SecurityContext, DisplayFormattedName);
        }

        InMemoryDbContext Db { get; }
        ISiteControlReader SiteControlReader { get; }
        ISecurityContext SecurityContext { get; }
        public IDisplayFormattedName DisplayFormattedName { get; }
        public KeepOnTopNotesView Subject { get; }

        public KeepOnTopNotes16ViewFixture WithUserAndRole(InMemoryDbContext db, bool isExternal = false, bool mapRole2 = false)
        {
            var user = isExternal ? UserBuilder.AsExternalUser(db, null, null).Build() : UserBuilder.AsInternalUser(db).Build();
            var role1 = new Role(1) {RoleName = Fixture.String()}.In(db);
            var role2 = new Role(2) {RoleName = Fixture.String()}.In(db);
            user.Roles.Add(mapRole2 ? role2 : role1);
            SecurityContext.User.Returns(user);

            return this;
        }

        public KeepOnTopNotes16ViewFixture WithCaseNames(NameType nameType)
        {
            new FilteredUserNameTypes
            {
                Description = nameType.Name,
                NameType = nameType.NameTypeCode,
                BulkEntryFlag = false
            }.In(Db);

            return this;
        }
    }
}