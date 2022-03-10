using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Details;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewTextControllerFacts
    {
        readonly ICaseTextSection _caseTextSection = Substitute.For<ICaseTextSection>();
        readonly string _textType = Fixture.String();
        readonly int _caseId = Fixture.Integer();
        readonly CommonQueryParameters _qp = new CommonQueryParameters();

        CaseViewTextController CreateSubject(params CaseTextData[] caseTextData)
        {
            _caseTextSection.Retrieve(_caseId).Returns(caseTextData);

            return new CaseViewTextController(_caseTextSection);
        }

        static CaseTextData CreateCaseText(string type, string language = null)
        {
            return new CaseTextData
            {
                Type = type,
                Language = language,
                Notes = Fixture.String()
            };
        }

        [Fact]
        public async Task ShouldReturnDataFromCaseTextSection()
        {
            var data = new CaseTextData
            {
                Type = Fixture.String(),
                Language = Fixture.String(),
                Notes = Fixture.String()
            };

            var subject = CreateSubject(data);

            var result = await subject.GetCaseTexts(_caseId, _qp);

            Assert.Equal(data.Language, result.Items<CaseTextData>().Single().Language);
            Assert.Equal(data.Type, result.Items<CaseTextData>().Single().Type);
            Assert.Equal(data.Notes, result.Items<CaseTextData>().Single().Notes);
        }

        [Fact]
        public async Task ShouldSkipTakeBasedOnQueryParameters()
        {
            var data = new[]
            {
                CreateCaseText(_textType, "1"),
                CreateCaseText(_textType, "2"),
                CreateCaseText(_textType, "3"),
                CreateCaseText(_textType, "4"),
                CreateCaseText(_textType, "5")
            };

            _qp.Skip = 2;
            _qp.Take = 1;

            var subject = CreateSubject(data);
            var result = await subject.GetCaseTexts(_caseId, _qp);

            Assert.Equal("3", result.Items<CaseTextData>().Single().Language);
        }

        [Fact]
        public async Task ShouldSortBasedOnQueryParameters()
        {
            var t1 = CreateCaseText(_textType, "1");
            var t2 = CreateCaseText(_textType, "2");

            t1.Notes = "A";
            t2.Notes = "B";

            _qp.SortBy = "Notes";
            _qp.SortDir = "desc";

            var subject = CreateSubject(t1, t2);
            var result = await subject.GetCaseTexts(_caseId, _qp);

            Assert.Equal("B", result.Items<CaseTextData>().First().Notes);
            Assert.Equal("A", result.Items<CaseTextData>().Last().Notes);
        }
    }
}