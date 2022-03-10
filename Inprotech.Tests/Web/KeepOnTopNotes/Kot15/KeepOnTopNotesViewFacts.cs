using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.KeepOnTopNotes;
using Inprotech.Web.KeepOnTopNotes.Kot15;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.KeepOnTopNotes.Kot15
{
    public class KeepOnTopNotesViewFacts
    {
        static dynamic SetupCaseKotNotes(InMemoryDbContext db)
        {
            var kotCaseProgram = (int)Enum.Parse(typeof(KotProgram), KnownKotModules.Case);
            var textType = new TextType(Fixture.String()).In(db);

            var @case = new CaseBuilder
            {
                Country = new CountryBuilder { Id = "ZZZ" }.Build().In(db),
                CaseType = new CaseTypeBuilder { Id = "A", Program = kotCaseProgram }.Build().In(db),
                PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(db)
            }.Build().In(db);

            @case.Type.TextType = textType;
            new CaseText(@case.Id, textType.Id, 0, "01")
            {
                Language = null,
                Text = Fixture.String("first"),
                TextType = textType
            }.In(db);

            var caseText = new CaseText(@case.Id, textType.Id, 1, "01")
            {
                Language = null,
                Text = Fixture.String("second"),
                TextType = textType
            }.In(db);

            @case.Type.KotTextType = textType.Id;

            return new { @case, caseText };
        }

        static dynamic SetupCaseNamesKotData(InMemoryDbContext db, bool requiredCaseNotes = false, bool isCrmOnly = false, bool setupCorrespondenceData = false)
        {
            var kotCaseProgram = (int)Enum.Parse(typeof(KotProgram), KnownKotModules.Case);
            var textType = new TextType(Fixture.String()).In(db);
            var textType2 = setupCorrespondenceData ? new TextType() { Id = "CB", TextDescription = Fixture.String() }.In(db) : new TextType(Fixture.String()).In(db);

            var @case = new CaseBuilder
            {
                Country = new CountryBuilder { Id = "ZZZ" }.Build().In(db),
                CaseType = new CaseTypeBuilder { Id = "A", Program = kotCaseProgram }.Build().In(db),
                PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(db)
            }.Build().In(db);

            var caseText = new CaseText();
            if (requiredCaseNotes)
            {
                new CaseText(@case.Id, textType.Id, 0, "01")
                {
                    Language = null,
                    Text = Fixture.String("first"),
                    TextType = textType
                }.In(db);

                caseText = new CaseText(@case.Id, textType.Id, 1, "01")
                {
                    Language = null,
                    Text = Fixture.String("second"),
                    TextType = textType
                }.In(db);

                @case.Type.KotTextType = textType.Id;
            }

            var nameType = new NameTypeBuilder { KotTextType = textType.Id, Program = 1, BulkEntryFlag = false }.Build().In(db);
            var nameType2 = new NameTypeBuilder { KotTextType = textType2.Id, Program = 1, BulkEntryFlag = false }.Build().In(db);

            nameType.TextType = textType;
            nameType.TextType = textType2;
            @case.Type.TextType = textType;
            var caseName = new CaseNameBuilder(db) { NameType = nameType }.BuildWithCase(@case).In(db);
            var caseName2 = new CaseNameBuilder(db) { NameType = nameType2 }.BuildWithCase(@case).In(db);
            caseName.NameType.TextType = textType;
            caseName2.NameType.TextType = textType;
            var nameText = new NameText { Id = caseName.Name.Id, TextType = textType.Id, Text = Fixture.String() }.In(db);
            var nameText2 = new NameText { Id = caseName2.Name.Id, TextType = textType2.Id, Text = Fixture.String() }.In(db);

            if (isCrmOnly)
            {
                @case.Type.CrmOnly = true;
                new[]
                {
                    nameType.NameTypeCode
                }.In(db);
            }

            if (requiredCaseNotes)
            {
                return new { @case, nameType, nameType2, nameText, nameText2, caseText };
            }

            return new { @case, nameType, nameType2, nameText, nameText2 };
        }

        static dynamic SetupNameKotNotes(InMemoryDbContext db, bool setupCorrespondenceData = false)
        {
            var tt1 = new TextType(Fixture.String()).In(db);
            var tt2 = setupCorrespondenceData ? new TextType { Id = "CB", TextDescription = Fixture.String() }.In(db) : new TextType(Fixture.String()).In(db);

            var name = new NameBuilder(db).Build().In(db);
            var cd = new ClientDetail { Id = name.Id, Correspondence = Fixture.String("correspondence") }.In(db);
            name.ClientDetail = cd;

            var @case = new CaseBuilder
            {
                Country = new CountryBuilder { Id = "ZZZ" }.Build().In(db),
                CaseType = new CaseType { ActualCaseTypeId = "A", Code = "A" }.In(db),
                PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(db)
            }.Build().In(db);

            var nameType = new NameTypeBuilder { NameTypeCode = "D", KotTextType = tt1.Id, Program = 15 }.Build().In(db);
            var nameType2 = new NameTypeBuilder { NameTypeCode = "Z", KotTextType = tt2.Id, Program = 15 }.Build().In(db);
            var nameType3 = new NameTypeBuilder { NameTypeCode = "A", KotTextType = tt1.Id, Program = 15 }.Build().In(db);

            nameType.TextType = tt1;
            nameType2.TextType = tt2;
            nameType3.TextType = tt1;

            new CaseNameBuilder(db) { NameType = nameType, Name = name }.BuildWithCase(@case).In(db);
            new CaseNameBuilder(db) { NameType = nameType3, Name = name }.BuildWithCase(@case).In(db);
            new NameTypeClassificationBuilder(db) { Name = name, NameType = nameType2, IsAllowed = 1 }.Build().In(db);

            var nameText = new NameText { Id = name.Id, TextType = tt1.Id, Text = Fixture.String() }.In(db);
            var nameText2 = setupCorrespondenceData ? null : new NameText { Id = name.Id, TextType = tt2.Id, Text = Fixture.String() }.In(db);

            return new { @case, nameType, nameType2, nameText, nameText2, name, nameType3 };
        }

        public class GetKotForCase : FactBase
        {
            [Fact]
            public async Task ShouldReturnNullForExternalUser()
            {
                var f = new KeepOnTopNotes15ViewFixture(Db).WithUser(true);
                var kotCase = new CaseBuilder().Build().In(Db);
                var r = await f.Subject.GetKotNotesForCase(kotCase.Id, KnownKotModules.Case);
                Assert.Null(r);
            }

            [Fact]
            public async Task ShouldReturnNotesForCaseOnly()
            {
                var f = new KeepOnTopNotes15ViewFixture(Db).WithUser();
                var data = SetupCaseKotNotes(Db);

                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(a.Length, 1);
                Assert.Equal(a[0].CaseRef, data.@case.Irn);
                Assert.Equal(a[0].Expanded, false);
                Assert.Equal(a[0].Note, data.caseText.ShortText);
                Assert.Null(a[0].BackgroundColor);
                Assert.Equal(a[0].TextType, data.@case.Type.TextType.TextDescription);
            }

            [Fact]
            public async Task ShouldNoReturnNotesForCaseIfNotMatched()
            {
                var f = new KeepOnTopNotes15ViewFixture(Db).WithUser();
                var kotCase = new CaseBuilder().Build().In(Db);
                var r = await f.Subject.GetKotNotesForCase(kotCase.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(a.Length, 0);
            }

            [Fact]
            public async Task ShouldReturnNotesForNamesOnly()
            {
                var data = SetupCaseNamesKotData(Db);
                var f = new KeepOnTopNotes15ViewFixture(Db)
                        .WithUser()
                        .WithCaseNames(data.nameType.NameTypeCode)
                        .WithCaseNames(data.nameType2.NameTypeCode);

                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(a.Length, 2);
                Assert.Equal(a[0].Expanded, false);
                Assert.Equal(a[0].Note, data.nameText.Text);
                Assert.Equal(a[0].NameTypes, data.nameType.Name);
                Assert.Null(a[0].BackgroundColor);
                Assert.Equal(a[1].Expanded, false);
                Assert.Equal(a[1].Note, data.nameText2.Text);
                Assert.Equal(a[1].NameTypes, data.nameType2.Name);
                Assert.Null(a[1].BackgroundColor);
            }

            [Fact]
            public async Task ShouldReturnNotesForCaseAndNames()
            {
                var data = SetupCaseNamesKotData(Db, true);
                var f = new KeepOnTopNotes15ViewFixture(Db)
                        .WithUser()
                        .WithCaseNames(data.nameType.NameTypeCode)
                        .WithCaseNames(data.nameType2.NameTypeCode);

                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(a.Length, 3);
                Assert.Equal(a[0].CaseRef, data.@case.Irn);
                Assert.Equal(a[0].Expanded, false);
                Assert.Equal(a[0].Note, data.caseText.ShortText);
                Assert.Null(a[0].BackgroundColor);
                Assert.Equal(a[1].Expanded, false);
                Assert.Equal(a[1].Note, data.nameText.Text);
                Assert.Equal(a[1].NameTypes, data.nameType.Name);
                Assert.Null(a[1].BackgroundColor);
                Assert.Equal(a[1].Expanded, false);
                Assert.Equal(a[2].Note, data.nameText2.Text);
                Assert.Equal(a[2].NameTypes, data.nameType2.Name);
                Assert.Null(a[2].BackgroundColor);
            }

            [Fact]
            public async Task ShouldReturnNotesForCrmOnlyNames()
            {
                var data = SetupCaseNamesKotData(Db, false, true);
                var f = new KeepOnTopNotes15ViewFixture(Db)
                        .WithUser()
                        .WithCaseNames(data.nameType.NameTypeCode)
                        .WithCaseNames(data.nameType2.NameTypeCode);

                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(a.Length, 1);
                Assert.Equal(a[0].Expanded, false);
                Assert.Equal(a[0].Note, data.nameText.Text);
                Assert.Equal(a[0].NameTypes, data.nameType.Name);
                Assert.Null(a[0].BackgroundColor);
            }

            [Fact]
            public async Task ShouldReturnNotesForNameCorrespondenceData()
            {
                var data = SetupCaseNamesKotData(Db, false, false, true);
                var f = new KeepOnTopNotes15ViewFixture(Db)
                        .WithUser()
                        .WithCaseNames(data.nameType.NameTypeCode)
                        .WithCaseNames(data.nameType2.NameTypeCode);

                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForCase(data.@case.Id, KnownKotModules.Case);
                var a = r.ToArray();
                Assert.Equal(a.Length, 2);
                Assert.Equal(a[1].Note, data.nameText2.Text);
                Assert.Equal(a[1].NameTypes, data.nameType2.Name);
                Assert.Null(a[1].BackgroundColor);
            }
        }

        public class GetKotForName : FactBase
        {
            [Fact]
            public async Task ShouldReturnNullForExternalUser()
            {
                var f = new KeepOnTopNotes15ViewFixture(Db).WithUser(true);
                var r = await f.Subject.GetKotNotesForName(Fixture.Integer(), KnownKotModules.Name);
                Assert.Null(r);
            }

            [Fact]
            public async Task ReturnEmptyResultSetForNameWhenNoData()
            {
                var f = new KeepOnTopNotes15ViewFixture(Db).WithUser();
                var results = await f.Subject.GetKotNotesForName(Fixture.Integer(), KnownKotModules.Name);
                Assert.Empty(results);
            }

            [Fact]
            public async Task ShouldReturnNotesForNamesWithNameSpecificNameTypesForTimeProgram()
            {
                var data = SetupNameKotNotes(Db);
                var f = new KeepOnTopNotes15ViewFixture(Db)
                        .WithUser();

                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForName(data.name.Id, "Time");
                var a = r.ToArray();
                Assert.Equal(2, a.Length);
                Assert.False(a[0].Expanded);
                Assert.Equal(data.nameText.Text, a[0].Note);
                Assert.Equal(data.nameType.Name, a[0].NameTypes);
                Assert.Equal(data.nameText2.Text, a[1].Note);
                Assert.Equal(data.nameType2.Name, a[1].NameTypes);
            }

            [Fact]
            public async Task ShouldReturnNotesForNames()
            {
                var data = SetupNameKotNotes(Db);
                var f = new KeepOnTopNotes15ViewFixture(Db)
                    .WithUser();
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = $"Formatted, ABC"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForName(data.name.Id, "Case");
                var a = r.ToArray();
                Assert.Equal(2, a.Length);
                Assert.False(a[0].Expanded);
                Assert.Equal(data.nameText.Text, a[0].Note);
                Assert.Equal(formatted[data.name.Id].Name, a[0].Name);
                Assert.Equal($"{data.nameType.Name}, {data.nameType3.Name}", a[0].NameTypes);
                Assert.Equal(data.nameText2.Text, a[1].Note);
                Assert.Equal(data.nameType2.Name, a[1].NameTypes);
            }

            [Fact]
            public async Task ShouldReturnNotesForNamesWithCorrespondenceText()
            {
                var data = SetupNameKotNotes(Db, true);
                var f = new KeepOnTopNotes15ViewFixture(Db)
                    .WithUser();

                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = $"Formatted, ABC"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var r = (IEnumerable<KotNotesItem>)await f.Subject.GetKotNotesForName(data.name.Id, "Time");
                var a = r.ToArray();
                Assert.Equal(2, a.Length);
                Assert.Equal(formatted[data.name.Id].Name, a[0].Name);
                Assert.Equal(data.nameText.Text, a[0].Note);
                Assert.Equal(data.nameType.Name, a[0].NameTypes);
                Assert.Equal(data.nameType2.Name, a[1].NameTypes);
            }
        }

        class KeepOnTopNotes15ViewFixture : IFixture<KeepOnTopNotesView>
        {
            readonly string _culture = Fixture.String();

            public KeepOnTopNotes15ViewFixture(InMemoryDbContext db)
            {
                Db = db;
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferredCultureResolver.Resolve().Returns(_culture);
                SecurityContext = Substitute.For<ISecurityContext>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                Subject = new KeepOnTopNotesView(db, preferredCultureResolver, SiteControlReader, SecurityContext, DisplayFormattedName);
            }

            InMemoryDbContext Db { get; }
            ISiteControlReader SiteControlReader { get; }
            public KeepOnTopNotesView Subject { get; }
            ISecurityContext SecurityContext { get; }
            public IDisplayFormattedName DisplayFormattedName { get; set; }

            public KeepOnTopNotes15ViewFixture WithUser(bool isExternal = false)
            {
                SecurityContext.User.Returns(new User(Fixture.String(), isExternal));
                return this;
            }

            public KeepOnTopNotes15ViewFixture WithCaseNames(string nameTypeCode)
            {
                var nameType = new NameTypeBuilder
                {
                    NameTypeCode = nameTypeCode
                }.Build().In(Db);
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
}
