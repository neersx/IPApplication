
using System;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class CaseTextResolverFacts : FactBase
    {
        public ICaseComparer CaseComparer { get; set; }
        public IHtmlAsPlainText HtmlAsPlainText { get; set; }

        public CaseTextResolver CreateSubject(IDbContext db)
        {
            HtmlAsPlainText = Substitute.For<IHtmlAsPlainText>();

            HtmlAsPlainText.Retrieve(Arg.Any<string>()).Returns(args => args[0]);

            return new CaseTextResolver(db, HtmlAsPlainText);
        }

        [Theory]
        [InlineData(1)]
        [InlineData(null)]
        public async Task ShouldReturnLatestTextIfCaseIdClassKeyLanguageMatch(int? languageKey)
        {
            var fixture = CreateSubject(Db);
            var caseId = Fixture.Integer();
            var classKey = Fixture.String();
            var classText = Fixture.String();
            new CaseTextBuilder {CaseId = caseId, TextTypeId = KnownTextTypes.GoodsServices, Class = classKey, Language = languageKey, Text = Fixture.String(), TextNumber = 0}.Build().In(Db);
            new CaseTextBuilder {CaseId = caseId, TextTypeId = KnownTextTypes.GoodsServices, Class = classKey, Language = languageKey, Text = classText, TextNumber = 1}.Build().In(Db);

            var result = await fixture.GetCaseText(caseId, KnownTextTypes.GoodsServices, classKey, languageKey);

            Assert.Equal(result, classText);
        }

        [Fact]
        public async Task ShouldReturnNullIfClassKeyLanguageMatch()
        {
            var fixture = CreateSubject(Db);
            var caseId = Fixture.Integer();
            var classKey = Fixture.String();
            var classText = Fixture.String();
            new CaseTextBuilder {CaseId = caseId, TextTypeId = KnownTextTypes.GoodsServices, Class = classKey, Language = null, Text = classText}.Build().In(Db);

            var result = await fixture.GetCaseText(caseId, KnownTextTypes.GoodsServices, Fixture.String());

            Assert.Null(result);
        }

        [Fact]
        public async Task ShouldReturnExceptionIfClassKeyIsNull()
        {
            var f = CreateSubject(Db);
            var exception = await Assert.ThrowsAsync<ArgumentNullException>(
                                                                            async () => await f.GetCaseText(Fixture.Integer(), string.Empty, Fixture.String()));

            Assert.IsType<ArgumentNullException>(exception);
            Assert.Contains("textType", exception.Message);
        }
    }
}