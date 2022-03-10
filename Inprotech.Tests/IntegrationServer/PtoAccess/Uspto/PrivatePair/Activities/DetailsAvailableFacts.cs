using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class DetailsAvailableFacts
    {
        [Collection("Dependable")]
        public class OnDetailsAvailableMethod : FactBase
        {
            readonly ApplicationDownload _application = new ApplicationDownload
            {
                CustomerNumber = "70859",
                Number = "PCT1234"
            };

            [Theory]
            [InlineData(DownloadActivityType.All)]
            [InlineData(DownloadActivityType.StatusChanges)]
            [InlineData(DownloadActivityType.Documents)]
            public async Task CreatesCaseIfNotExists(DownloadActivityType downloadActivityType)
            {
                var f = new DetailsAvailableFixture(Db);

                await f.Subject.ConvertNotifyAndSendDocsToDms(new Session
                {
                    DownloadActivity = downloadActivityType
                }, _application);

                var caseCreated = Db.Set<Case>().Single();

                Assert.Equal("PCT1234", caseCreated.ApplicationNumber);
                Assert.Equal(Fixture.Today(), caseCreated.UpdatedOn);
            }

            [Theory]
            [InlineData(DownloadActivityType.All)]
            [InlineData(DownloadActivityType.StatusChanges)]
            [InlineData(DownloadActivityType.Documents)]
            public async Task UpdatesCaseIfExists(DownloadActivityType downloadActivityType)
            {
                new Case
                {
                    ApplicationNumber = "PCT1234",
                    Source = DataSourceType.UsptoPrivatePair
                }.In(Db);

                var f = new DetailsAvailableFixture(Db);

                await f.Subject.ConvertNotifyAndSendDocsToDms(new Session
                {
                    DownloadActivity = downloadActivityType
                }, _application);

                var caseCreated = Db.Set<Case>().Single();

                Assert.Equal("PCT1234", caseCreated.ApplicationNumber);
            }

            [Theory]
            [InlineData(DownloadActivityType.All)]
            [InlineData(DownloadActivityType.StatusChanges)]
            [InlineData(DownloadActivityType.Documents)]
            public async Task CallsToUpdateCorrelationId(DownloadActivityType downloadActivityType)
            {
                var existing = new Case
                {
                    ApplicationNumber = "PCT1234",
                    Source = DataSourceType.UsptoPrivatePair
                }.In(Db);

                var f = new DetailsAvailableFixture(Db);
                await f.Subject.ConvertNotifyAndSendDocsToDms(new Session
                {
                    DownloadActivity = downloadActivityType
                }, _application);
                f.CorrelationIdUpdator.Received(1).UpdateIfRequired(existing);
            }

            public class FakeDmsActivity
            {
                public Task MoveToDms()
                {
                    return Task.FromResult(0);
                }
            }

            [Theory]
            [InlineData(DownloadActivityType.All)]
            [InlineData(DownloadActivityType.StatusChanges)]
            [InlineData(DownloadActivityType.Documents)]
            public async Task DoAllThatJazz(DownloadActivityType downloadActivityType)
            {
                var f = new DetailsAvailableFixture(Db);

                f.DmsWorkflowBuilder.BuildPrivatePair(_application)
                 .Returns(Activity.Run<FakeDmsActivity>(d => d.MoveToDms()));

                var r = (ActivityGroup)await f.Subject
                                              .ConvertNotifyAndSendDocsToDms(
                                                                             new Session
                                                                             {
                                                                                 DownloadActivity = downloadActivityType
                                                                             }, _application);

                Assert.Equal(5, r.Items.Count());

                var first = (SingleActivity)r.Items.ElementAt(0);
                var second = (SingleActivity)r.Items.ElementAt(1);
                var third = (SingleActivity)r.Items.ElementAt(2);
                var fourth = (SingleActivity)r.Items.ElementAt(3);
                var fifth = (SingleActivity)r.Items.ElementAt(4);

                Assert.Equal("IConvertApplicationDetailsToCpaXml.Convert", first.TypeAndMethod());
                Assert.Equal("DocumentEvents.UpdateFromPrivatePair", second.TypeAndMethod());
                Assert.Equal("NewCaseDetailsAvailableNotification.Send", third.TypeAndMethod());
                Assert.Equal("FakeDmsActivity.MoveToDms", fourth.TypeAndMethod());
                Assert.Equal("ICheckCaseValidity.IsValid", fifth.TypeAndMethod());
            }

            [Fact]
            public async Task IgnoreFurtherStepsCorrelationIdUpdatorThrowsError()
            {
                var f = new DetailsAvailableFixture(Db).WithMultipleMatchingInprotechCases();

                f.DmsWorkflowBuilder.BuildPrivatePair(_application)
                 .Returns(Activity.Run<FakeDmsActivity>(d => d.MoveToDms()));

                await Assert.ThrowsAsync<Exception>(
                                                    async () => await f.Subject.ConvertNotifyAndSendDocsToDms(
                                                                                                              new Session
                                                                                                              {
                                                                                                                  DownloadActivity = DownloadActivityType.Documents
                                                                                                              }, _application));
            }
        }

        public class DetailsAvailableFixture : IFixture<DetailsWorkflow>
        {
            public DetailsAvailableFixture(InMemoryDbContext db)
            {
                DmsWorkflowBuilder = Substitute.For<IBuildDmsIntegrationWorkflows>();

                CorrelationIdUpdator = Substitute.For<ICorrelationIdUpdator>();

                Subject = new DetailsWorkflow(db, CorrelationIdUpdator, Fixture.Today, DmsWorkflowBuilder);
            }

            public ICorrelationIdUpdator CorrelationIdUpdator { get; set; }

            public IBuildDmsIntegrationWorkflows DmsWorkflowBuilder { get; set; }

            public DetailsWorkflow Subject { get; }

            public DetailsAvailableFixture WithMultipleMatchingInprotechCases()
            {
                CorrelationIdUpdator.When(_ => _.UpdateIfRequired(Arg.Any<Case>()))
                                    .Do(_ => throw new Exception("Multiple cases"));
                return this;
            }
        }
    }
}