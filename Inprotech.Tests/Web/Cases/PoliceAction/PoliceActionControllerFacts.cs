using Inprotech.Infrastructure;
using Inprotech.Web.Cases;
using InprotechKaizen.Model.Components.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.PoliceAction
{
    public class PoliceActionControllerFacts : FactBase
    {
        [Fact]
        public void CallsSiteControlIfIsPoliceImmediatelyNull()
        {
            var fixture = new PoliceActionControllerFixture();
            var subject = fixture.Subject;
            var request = new PoliceActionController.PoliceActionModel()
            {
                IsPoliceImmediately = null
            };

            subject.PoliceAnAction(request);

            fixture.SiteControlReader.Received(1).Read<bool>(SiteControls.PoliceImmediately);
        }
        
        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public void DoesNotCallSiteControlIfIsPoliceImmediatelyHasValue(bool value)
        {
            var fixture = new PoliceActionControllerFixture();
            var subject = fixture.Subject;
            var request = new PoliceActionController.PoliceActionModel()
            {
                IsPoliceImmediately = value
            };

            subject.PoliceAnAction(request);

            fixture.SiteControlReader.Received(0).Read<bool>(SiteControls.PoliceImmediately);
        }

        [Fact]
        public void CallsQueueActionRequestWithAppropriateValues()
        {
            var fixture = new PoliceActionControllerFixture();
            var subject = fixture.Subject;
            var request = new PoliceActionController.PoliceActionModel()
            {
                CaseId = Fixture.Integer(),
                ActionId = Fixture.String(),
                Cycle = 2
            };

            subject.PoliceAnAction(request);

            fixture.PolicingEngine.Received(1).QueueOpenActionRequest(request.CaseId, request.ActionId,2, false);
        }

        [Fact]
        public void CallsPoliceIfImmediateIsTrue()
        {
            var fixture = new PoliceActionControllerFixture();
            var subject = fixture.Subject;
            var batchNo = Fixture.Integer();
            var request = new PoliceActionController.PoliceActionModel()
            {
                IsPoliceImmediately = true
            };
            fixture.PolicingEngine.QueueOpenActionRequest(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<bool>()).Returns(new QueuedPolicingResult(batchNo));
            subject.PoliceAnAction(request);

            fixture.PolicingEngine.Received(1).Police(batchNo);
        }

        [Fact] 
        public void DoesNotCallsPoliceIfImmediateIsFalse()
        {
            var fixture = new PoliceActionControllerFixture();
            var subject = fixture.Subject;
            var batchNo = Fixture.Integer();
            var request = new PoliceActionController.PoliceActionModel()
            {
                IsPoliceImmediately = false
            };
            fixture.PolicingEngine.QueueOpenActionRequest(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int?>()).Returns(new QueuedPolicingResult(batchNo));
            subject.PoliceAnAction(request);

            fixture.PolicingEngine.Received(0).Police(batchNo);
        }

        internal class PoliceActionControllerFixture : IFixture<PoliceActionController>
        {
            public IPolicingEngine PolicingEngine;
            public ISiteControlReader SiteControlReader;

            public PoliceActionControllerFixture()
            {
                PolicingEngine = Substitute.For<IPolicingEngine>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new PoliceActionController(PolicingEngine, SiteControlReader);
            }

            public PoliceActionController Subject { get; }
        }
    }
}
