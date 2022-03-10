using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingQueueAdministrationControllerFacts
    {
        public class AdministrativeFunctions
        {
            readonly string queueStatus = "all";

            readonly PolicingQueueAdministrationControllerFixture _fixture = new PolicingQueueAdministrationControllerFixture();

            [Fact]
            public void CallsUpdatePolicingRequestToChangeNextRunTime()
            {
                var nextRunTime = Fixture.FutureDate();
                var records = new[] {1, 2};

                _fixture.Subject.EditNextRunTime(nextRunTime.ToString(), records);
                _fixture.UpdatePolicingRequest.Received(1).EditNextRunTime(nextRunTime, records);
            }

            [Fact]
            public void CallsUpdatePolicingRequestToDeleteRecords()
            {
                var records = new[] {1, 2};

                _fixture.Subject.DeletePolicingRequests(records);
                _fixture.UpdatePolicingRequest.Received(1).Delete(records);
            }

            [Fact]
            public void CallsUpdatePolicingRequestToHoldRecords()
            {
                var records = new[] {1, 2};

                _fixture.Subject.HoldPolicingRequests(records);
                _fixture.UpdatePolicingRequest.Received(1).Hold(records);
            }

            [Fact]
            public void CallsUpdatePolicingRequestToReleaseRecords()
            {
                var records = new[] {1, 2};

                _fixture.Subject.ReleasePolicingRequests(records);
                _fixture.UpdatePolicingRequest.Received(1).Release(records);
            }

            [Fact]
            public void DeletesAllPolicingRequestsByQueryParameters()
            {
                _fixture.Subject.DeleteAllPolicingRequests(queueStatus, CommonQueryParameters.Default);
                _fixture.UpdatePolicingRequest.Received(1).Delete(Arg.Any<int[]>());
            }

            [Fact]
            public void HoldsAllPolicingRequestsByQueryParameters()
            {
                _fixture.Subject.HoldAllPolicingRequests(queueStatus, CommonQueryParameters.Default);
                _fixture.UpdatePolicingRequest.Received(1).Hold(Arg.Any<int[]>());
            }

            [Fact]
            public void ReleasesAllPolicingRequestsByQueryParameters()
            {
                _fixture.Subject.ReleaseAllPolicingRequests(queueStatus, CommonQueryParameters.Default);

                _fixture.UpdatePolicingRequest.Received(1).Release(Arg.Any<int[]>());
            }
        }

        public class ControllerFacts
        {
            [Fact]
            public void PolicingQueueAdministrationControllerSecuredByPolicingAdministrationTask()
            {
                var r = TaskSecurity.Secures<PolicingQueueAdministrationController>(ApplicationTask.PolicingAdministration);

                Assert.True(r);
            }
        }

        public class PolicingQueueAdministrationControllerFixture : IFixture<PolicingQueueAdministrationController>
        {
            public PolicingQueueAdministrationControllerFixture()
            {
                PolicingQueue = Substitute.For<IPolicingQueue>();
                UpdatePolicingRequest = Substitute.For<IUpdatePolicingRequest>();

                CommonQueryService = new CommonQueryService();

                Subject = new PolicingQueueAdministrationController(PolicingQueue, CommonQueryService,
                                                                    UpdatePolicingRequest);
            }

            public IPolicingQueue PolicingQueue { get; set; }

            public ICommonQueryService CommonQueryService { get; set; }

            public IUpdatePolicingRequest UpdatePolicingRequest { get; set; }

            public PolicingQueueAdministrationController Subject { get; set; }
        }
    }
}