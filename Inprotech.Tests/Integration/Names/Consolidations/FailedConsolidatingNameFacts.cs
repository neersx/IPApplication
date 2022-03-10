using Dependable.Dispatcher;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Names.Consolidations;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Names.Consolidations
{
    public class FailedConsolidatingNameFacts
    {
        [Fact]
        public void ShouldPersistConsolidationErrorInJobState()
        {
            var jobExecutionId = Fixture.Long();
            var nameBeingConsolidated = Fixture.Integer();
            var exceptionContext = new ExceptionContext();

            var currentStatus = new NameConsolidationStatus();

            var persistJobState = Substitute.For<IPersistJobState>();
            persistJobState.Load<NameConsolidationStatus>(jobExecutionId)
                            .Returns(currentStatus);

            var subject = new FailedConsolidatingName(persistJobState);

            subject.NameNotConsolidated(exceptionContext, jobExecutionId, nameBeingConsolidated);

            Assert.Equal(JsonConvert.SerializeObject(exceptionContext, new JsonSerializerSettings
            {
                ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
                Formatting = Formatting.Indented
            }), currentStatus.Errors[nameBeingConsolidated]);

            persistJobState.Received(1)
                            .Save(jobExecutionId, currentStatus);
        }
    }
}