using Inprotech.Web.Cases;
using InprotechKaizen.Model.Components.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class PoliceBatchControllerFacts : FactBase
    {
        [Fact]
        public void PoliceBatchCallsPolicingEngineAppropriately()
        {
            var request = new PoliceBatchController.PoliceBatchModel()
            {
                BatchNo = Fixture.Integer()
            };
            var fixture = new PoliceActionControllerFixture();

            fixture.Subject.PoliceBatch(request);

            fixture.PolicingEngine.Received(1).Police(request.BatchNo);
        }

        internal class PoliceActionControllerFixture : IFixture<PoliceBatchController>
        {
            public IPolicingEngine PolicingEngine;

            public PoliceActionControllerFixture()
            {
                PolicingEngine = Substitute.For<IPolicingEngine>();
                Subject = new PoliceBatchController(PolicingEngine);
            }

            public PoliceBatchController Subject { get; }
        }
    }
}
