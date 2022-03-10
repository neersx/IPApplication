using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Cases.Details;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewRenewalsControllerFacts
    {
        readonly ICaseRenewalDetails _caseRenewalDetails = Substitute.For<ICaseRenewalDetails>();
        readonly int _caseId = Fixture.Integer();
        readonly int _screenCriteriaId = Fixture.Integer();

        CaseViewRenewalsController CreateSubject(CaseRenewalData caseRenewalData)
        {
            _caseRenewalDetails.GetRenewalDetails(Arg.Any<int>(),Arg.Any<int>())
                               .Returns(caseRenewalData);

            return new CaseViewRenewalsController(_caseRenewalDetails);
        }

        [Fact]
        public async Task CallsToGetCaseRenewalsData()
        {
            var expectedResult = new CaseRenewalData {NextRenewalDate = Fixture.Monday, ExtendedRenewalYears = 100};

            var f = CreateSubject(expectedResult);

            var result = await f.GetRenewalDetails(_caseId, _screenCriteriaId);

            Assert.Equal(expectedResult, result);
            Assert.Equal(expectedResult.NextRenewalDate, result.NextRenewalDate);
            Assert.Equal(expectedResult.ExtendedRenewalYears, result.ExtendedRenewalYears);

            _caseRenewalDetails.Received(1)
                               .GetRenewalDetails(_caseId, _screenCriteriaId).IgnoreAwaitForNSubstituteAssertion();
        }
    }
}