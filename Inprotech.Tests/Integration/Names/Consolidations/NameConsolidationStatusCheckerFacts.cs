using Inprotech.Integration.Jobs;
using Inprotech.Integration.Names.Consolidations;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Names.Consolidations
{
    public class NameConsolidationStatusCheckerFacts
    {
        readonly IConfigureJob _configureJob = Substitute.For<IConfigureJob>();

        [Fact]
        public void ShouldReturnEmptyNameConsolidationStatus()
        {
            var statusToReturn = new JobStatus
            {
                State = JObject.FromObject(new NameConsolidationStatus())
            };

            _configureJob.GetJobStatus("NameConsolidationJob")
                         .Returns(statusToReturn);

            var r = new NameConsolidationStatusChecker(_configureJob).GetStatus();

            Assert.Empty(r.NamesConsolidated);
            Assert.False(r.IsCompleted);
        }

        [Fact]
        public void ShouldReturnNameConsolidationStatusIfAvailable()
        {
            var nameConsolidationStatus = new NameConsolidationStatus
            {
                IsCompleted = Fixture.Boolean(),
                NumberOfNamesToConsolidate = 2
            };

            nameConsolidationStatus.NamesConsolidated.Add(Fixture.Integer());
            nameConsolidationStatus.NamesConsolidated.Add(Fixture.Integer());

            var statusToReturn = new JobStatus
            {
                State = JObject.FromObject(nameConsolidationStatus)
            };

            _configureJob.GetJobStatus("NameConsolidationJob")
                         .Returns(statusToReturn);

            var r = new NameConsolidationStatusChecker(_configureJob).GetStatus();

            Assert.Equal(r.NamesConsolidated, nameConsolidationStatus.NamesConsolidated);
            Assert.Equal(r.IsCompleted, nameConsolidationStatus.IsCompleted);
        }
    }
}