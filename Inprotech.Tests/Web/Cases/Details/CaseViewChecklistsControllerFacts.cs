using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewChecklistsControllerFacts
    {
        class CaseViewChecklistsControllerFixture : IFixture<CaseViewChecklistController>
        {
            public CaseViewChecklistsControllerFixture(InMemoryDbContext db)
            {
                CaseChecklistDetails = Substitute.For<ICaseChecklistDetails>();
                CommonQueryService = Substitute.For<ICommonQueryService>();
                Subject = new CaseViewChecklistController(CaseChecklistDetails, CommonQueryService);
            }

            public CaseViewChecklistController Subject { get; set; }
            public ICaseChecklistDetails CaseChecklistDetails { get; set; }
            ICommonQueryService CommonQueryService { get; set; }
        }

        public class GetChecklistTypesMethod : FactBase
        {
            readonly int _caseId = Fixture.Integer();
            int criteriaNum = -1;

            [Fact]
            public async Task ReturnsCorrectChecklistTypes()
            {
                var selectedCheckListNumber = 101;
                var expectedChecklist = new[]
                {
                    new CaseChecklistTypes {ChecklistType = selectedCheckListNumber, ChecklistTypeDescription = Fixture.String(), ChecklistCriteriaKey = criteriaNum},
                    new CaseChecklistTypes {ChecklistType = selectedCheckListNumber + 1, ChecklistTypeDescription = Fixture.String(), ChecklistCriteriaKey = criteriaNum - 1},
                };

                var expectedResult = new ChecklistTypeAndSelectedOne
                {
                    SelectedChecklistType = selectedCheckListNumber,
                    ChecklistTypes = expectedChecklist,
                    SelectedChecklistCriteriaKey = criteriaNum
                };
                var f = new CaseViewChecklistsControllerFacts.CaseViewChecklistsControllerFixture(Db);
                f.CaseChecklistDetails.GetChecklistTypes(_caseId).Returns(expectedResult);
                var result = await f.Subject.GetChecklistTypes(_caseId);

                Assert.Equal(expectedResult, result);
                Assert.Equal(expectedChecklist, result.ChecklistTypes);
                Assert.Equal(selectedCheckListNumber, result.SelectedChecklistType);
                Assert.Equal(criteriaNum, result.SelectedChecklistCriteriaKey);
            }

            [Fact]
            public async Task ReturnsCorrectQuestionsList()
            {
                const int checklistCriteriaKey = -1;
                var parameters = new CommonQueryParameters {Skip = 0, Take = 10};

                var expectedQuestions = new[]
                {
                    new CaseChecklistQuestions {QuestionNo = 1, Question = Fixture.String(), SequenceNo = 1},
                    new CaseChecklistQuestions {QuestionNo = 2, Question = Fixture.String(), SequenceNo = 2},
                };
                var fixture = new CaseViewChecklistsControllerFacts.CaseViewChecklistsControllerFixture(Db);
                fixture.CaseChecklistDetails.GetChecklistData(_caseId, checklistCriteriaKey)
                       .Returns(expectedQuestions);

                var result = await fixture.Subject.GetChecklistData(_caseId, checklistCriteriaKey, parameters);

                Assert.Equal(2, result.Pagination.Total);
            }
        }
    }
}