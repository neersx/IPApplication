using Inprotech.IntegrationServer.Api;
using Inprotech.IntegrationServer.Scheduling;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Api
{
    public class ScheduleExecutionControllerFacts : FactBase
    {
        public ScheduleExecutionControllerFacts()
        {
            _scheduleRunner = Substitute.For<IScheduleRunner>();
            _scheduleExecutionController = new ScheduleExecutionController(_scheduleRunner, Db);
        }

        readonly ScheduleExecutionController _scheduleExecutionController;
        readonly IScheduleRunner _scheduleRunner;

        [Fact]
        public void CallsScheduleRunnerWithParams()
        {
            var user = new User("TestUser", false) {Name = new Name(10) {LastName = "Mac", FirstName = "Adam"}}.In(Db);
            _scheduleExecutionController.Stop(10, user.Id);

            _scheduleRunner.Received(1).StopScheduleExecutions(10, user.Id, user.Name.Formatted());
        }
    }
}