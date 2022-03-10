using Inprotech.Web.Lists;
using Inprotech.Web.Search.CaseSupportData;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class RenewalStatusesControllerFacts
    {
        public RenewalStatusesControllerFacts()
        {
            _renewalStatuses = Substitute.For<IRenewalStatuses>();
            _controller = new RenewalStatusesController(_renewalStatuses);
        }

        readonly IRenewalStatuses _renewalStatuses;
        readonly RenewalStatusesController _controller;

        [Fact]
        public void ShouldForwardCorrectParametersToCaseSupportData()
        {
            _controller.Get("a", true, true, true);
            _renewalStatuses.Received(1).Get("a", true, true, true);
        }
    }
}