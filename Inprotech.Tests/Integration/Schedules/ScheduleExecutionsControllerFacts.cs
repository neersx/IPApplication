using System.Linq;
using System.Net;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ScheduleExecutionsControllerFacts
    {
        readonly IScheduleExecutions _executions = Substitute.For<IScheduleExecutions>();

        [Theory]
        [InlineData(ScheduleExecutionStatus.Started)]
        [InlineData(ScheduleExecutionStatus.Complete)]
        [InlineData(ScheduleExecutionStatus.Failed)]
        public void ReturnFirst30RequestedExecutionList(ScheduleExecutionStatus statusRequested)
        {
            var scheduleId = Fixture.Integer();

            var subject = new ScheduleExecutionsController(_executions);

            subject.Get(scheduleId, statusRequested);

            _executions.Received(1).Get(scheduleId, statusRequested);
        }

        [Theory]
        [InlineData(ScheduleType.OnDemand)]
        [InlineData(ScheduleType.Scheduled)]
        public void ReturnsRawExecutionIndexForPrivatePair(ScheduleType allowedType)
        {
            var scheduleId = Fixture.Integer();
            var executionId = Fixture.Long();

            _executions.Get(scheduleId)
                       .Returns(new[]
                       {
                           new ScheduleExecutionsModel
                           {
                               Id = executionId,
                               Source = DataSourceType.UsptoPrivatePair.ToString(),
                               Type = allowedType.ToString(),
                               IndexList = new byte[0]
                           }
                       }.AsQueryable());

            var subject = new ScheduleExecutionsController(_executions);

            var r = subject.RawExecutionIndex(scheduleId, executionId);

            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("application/zip", r.Content.Headers.ContentType.MediaType);
            Assert.Equal("attachment", r.Content.Headers.ContentDisposition.DispositionType);
            Assert.Equal("index-list.zip", r.Content.Headers.ContentDisposition.FileName);
        }

        [Theory]
        [InlineData(DataSourceType.IpOneData)]
        [InlineData(DataSourceType.Epo)]
        [InlineData(DataSourceType.UsptoTsdr)]
        public void ReturnBadRequestForInvalidIndexRetrieval(DataSourceType unsupportedType)
        {
            var scheduleId = Fixture.Integer();
            var executionId = Fixture.Long();

            _executions.Get(scheduleId)
                       .Returns(new[]
                       {
                           new ScheduleExecutionsModel
                           {
                               Id = executionId,
                               Source = unsupportedType.ToString(),
                               Type = ScheduleType.OnDemand.ToString()
                           }
                       }.AsQueryable());

            var subject = new ScheduleExecutionsController(_executions);

            var r = subject.RawExecutionIndex(scheduleId, executionId);

            Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        }
    }
}