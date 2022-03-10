using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Lists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class CaseStatusesControllerFacts
    {
        public CaseStatusesControllerFacts()
        {
            _caseStatuses = Substitute.For<ICaseStatuses>();
            _controller = new CaseStatusesController(_caseStatuses);
        }

        readonly ICaseStatuses _caseStatuses;
        readonly CaseStatusesController _controller;

        [Fact]
        public void ShouldForwardCorrectParametersToCaseSupportData()
        {
            _controller.Get("a", true, true, true);
            _caseStatuses.Received(1).Get("a", false, true, true, true);
        }
    }
}