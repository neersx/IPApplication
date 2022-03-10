using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseTextSectionFacts : FactBase
    {
        bool _siteControlReturnVal = true;
        readonly FilteredUserTextType _tt1 = new FilteredUserTextTypeBuilder {TextTypeId = "A", TextTypeDescription = "A"}.Build();
        readonly FilteredUserTextType _tt2 = new FilteredUserTextTypeBuilder {TextTypeId = "B", TextTypeDescription = "B"}.Build();
        Case _case;
        CaseTextSectionFixture _f;

        CaseTextSection CreateSubject()
        {
            _f = new CaseTextSectionFixture(Db).WithKeepSearchHistorySiteControl(_siteControlReturnVal);
            _case = _f.Case;
            return _f.Subject;
        }

        CaseText CreateCaseText(FilteredUserTextType tt, short sequence = 0, string language = null)
        {
            return _f.CreateCaseText(tt, sequence, language);
        }

        public class ClassesAndText : FactBase
        {
            [Fact]
            public async Task ShouldReturnCaseText()
            {
                var english = "English";
                var f = new CaseTextSectionFixture(Db);

                var textDesc = new FilteredUserTextTypeBuilder {TextTypeId = KnownTextTypes.GoodsServices}.Build();
                f.CreateCaseText(textDesc);
                f.CreateCaseText(textDesc, 1, english);

                var result = (await f.Subject.GetClassAndText(f.Case.Id)).ToArray();

                Assert.Equal(2, result.Length);
            }

            [Fact]
            public async Task ShouldReturnOnlyTheLatestClassesAndText()
            {
                var english = "English";
                var f = new CaseTextSectionFixture(Db);

                var textDesc = new FilteredUserTextTypeBuilder {TextTypeId = KnownTextTypes.GoodsServices}.Build();
                var older = f.CreateCaseText(textDesc, 0, english);
                var newer = f.CreateCaseText(textDesc, 1, english);

                older.ModifiedDate = Fixture.PastDate();
                newer.ModifiedDate = Fixture.Today();

                var result = (await f.Subject.GetClassAndText(f.Case.Id)).ToArray();

                Assert.Single(result);
            }

            [Fact]
            public async Task ShouldReturnTextForSelectedClasses()
            {
                var english = "English";
                var f = new CaseTextSectionFixture(Db);

                var textDesc = new FilteredUserTextTypeBuilder {TextTypeId = KnownTextTypes.GoodsServices}.Build();
                var class01 = f.CreateCaseText(textDesc, 0, english, "01");
                var class02 = f.CreateCaseText(textDesc, 0, english, "02");

                class01.ModifiedDate = Fixture.Today();
                class02.ModifiedDate = Fixture.Today();

                var result = (await f.Subject.GetClassAndText(f.Case.Id, "01")).ToArray();

                Assert.Single(result);
                Assert.Equal("01", result.Single().TextClass);
            }
        }

        class CaseTextSectionFixture : IFixture<CaseTextSection>
        {
            public CaseTextSectionFixture(InMemoryDbContext db)
            {
                Db = db;
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User());
                SiteControl = Substitute.For<ISiteControlReader>();
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferredCultureResolver.Resolve().Returns(Fixture.String());

                WithKeepSearchHistorySiteControl(true);
                Case = new CaseBuilder().Build().In(Db);

                Subject = new CaseTextSection(Db, securityContext, preferredCultureResolver, SiteControl);
            }

            InMemoryDbContext Db { get; }
            ISiteControlReader SiteControl { get; }

            public Case Case { get; }

            public CaseTextSection Subject { get; }

            public CaseTextSectionFixture WithKeepSearchHistorySiteControl(bool value)
            {
                SiteControl.Read<bool>(SiteControls.KEEPSPECIHISTORY).Returns(value);
                return this;
            }

            public CaseText CreateCaseText(FilteredUserTextType tt, short sequence = 0, string language = null, string caseClass = null)
            {
                if (!Db.Set<FilteredUserTextType>().Contains(tt)) tt.In(Db);

                var ct = new CaseTextBuilder
                {
                    CaseId = Case.Id,
                    TextTypeId = tt.TextType,
                    TextNumber = sequence,
                    Text = Fixture.String(),
                    Class = caseClass
                }.Build().In(Db);

                ct.Language = CreateTableCode(language);
                return ct;
            }

            int? CreateTableCode(string language = null)
            {
                if (!string.IsNullOrWhiteSpace(language))
                {
                    var existing = Db.Set<TableCode>().FirstOrDefault(t => t.Name == language)
                                   ?? new TableCodeBuilder
                                   {
                                       Description = language
                                   }.Build().In(Db);

                    return existing.Id;
                }

                return null;
            }
        }

        [Fact]
        public async Task ShouldGetGoodsServicesHistoryWithoutClass()
        {
            _siteControlReturnVal = true;
            var subject = CreateSubject();

            var textDesc = new FilteredUserTextTypeBuilder {TextTypeId = KnownTextTypes.GoodsServices}.Build();
            CreateCaseText(textDesc, 0, "English");
            CreateCaseText(textDesc, 1, "English");

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.NotEmpty(result);

            var history = await subject.GetHistoryData(_case.Id, result[0].TypeKey, result[0].TextClass, result[0].LanguageKey);

            Assert.NotNull(history);
            Assert.NotEmpty(history.History);
        }

        [Fact]
        public async Task ShouldGetGoodsServicesHistoryWithoutHistory()
        {
            _siteControlReturnVal = false;
            var subject = CreateSubject();

            var textDesc = new FilteredUserTextTypeBuilder {TextTypeId = KnownTextTypes.GoodsServices}.Build();
            CreateCaseText(textDesc, 0, "English");
            CreateCaseText(textDesc, 1, "English");

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.NotEmpty(result);

            var history = await subject.GetHistoryData(_case.Id, result[0].TypeKey, result[0].TextClass, result[0].LanguageKey);

            Assert.NotNull(history);
        }

        [Fact]
        public async Task ShouldIncludeGoodsServicesWithoutClass()
        {
            var subject = CreateSubject();

            CreateCaseText(new FilteredUserTextTypeBuilder {TextTypeId = KnownTextTypes.GoodsServices}.Build());

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.NotEmpty(result);
        }

        [Fact]
        public async Task ShouldNotIncludeCaseTextWithClasses()
        {
            var subject = CreateSubject();
            var ct1 = CreateCaseText(_tt1);
            var ct2 = CreateCaseText(_tt1, 1, "English");

            ct1.Class = ct2.Class = Fixture.String();

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.Empty(result);
        }

        [Fact]
        public async Task ShouldPickTextBasedOnLengthOfText()
        {
            var subject = CreateSubject();
            var ct1 = CreateCaseText(_tt1);
            var ct2 = CreateCaseText(_tt2);

            ct1.Text = Fixture.RandomString(1000);
            ct2.Text = Fixture.RandomString(20);

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.Equal(ct1.LongText, result.First().Notes);
            Assert.Equal(ct2.ShortText, result.Last().Notes);
        }

        [Fact]
        public async Task ShouldReturnCaseTextFromCaseOrderByTypeAndLanguage()
        {
            var subject = CreateSubject();
            var ct1 = CreateCaseText(_tt1);
            var ct2 = CreateCaseText(_tt2);
            var ct3 = CreateCaseText(_tt1, 1, "English");

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.Equal(3, result.Length);

            Assert.Equal(ct1.Text, result.ElementAt(0).Notes);
            Assert.Equal(_tt1.TextDescription, result.ElementAt(0).Type);
            Assert.Null(result.ElementAt(0).Language);

            Assert.Equal(ct3.Text, result.ElementAt(1).Notes);
            Assert.Equal(_tt1.TextDescription, result.ElementAt(1).Type);
            Assert.Equal("English", result.ElementAt(1).Language);

            Assert.Equal(ct2.Text, result.ElementAt(2).Notes);
            Assert.Equal(_tt2.TextDescription, result.ElementAt(2).Type);
            Assert.Null(result.ElementAt(2).Language);
        }

        [Fact]
        public async Task ShouldReturnForAuthorisedTextTypesOnly()
        {
            var subject = CreateSubject();
            // this is unauthorised because it does not have an accompanying FilteredUserTextType
            new CaseTextBuilder
            {
                CaseId = _case.Id,
                TextTypeId = Fixture.String(),
                TextNumber = Fixture.Short()
            }.Build().In(Db);

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.Empty(result);
        }

        [Fact]
        public async Task ShouldReturnOnlyTheLatest()
        {
            var subject = CreateSubject();
            var older = CreateCaseText(_tt1);
            var newer = CreateCaseText(_tt1);

            older.ModifiedDate = Fixture.PastDate();
            newer.ModifiedDate = Fixture.Today();

            var result = (await subject.Retrieve(_case.Id)).ToArray();

            Assert.Single(result);
            Assert.Equal(newer.Text, result.Single().Notes);
        }
    }
}