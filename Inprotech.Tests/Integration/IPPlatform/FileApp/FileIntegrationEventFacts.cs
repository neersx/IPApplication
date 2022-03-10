using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileIntegrationEventFacts
    {
        public class AddOrUpdateMethod : FactBase
        {
            [Fact]
            public async Task AddsFileIntegrationEvent()
            {
                var configuredEventId = Fixture.Integer();
                var settings = new FileSettings
                {
                    FileIntegrationEvent = configuredEventId
                };
                var @case = new CaseBuilder().Build().In(Db);

                var f = new FileIntegrationEventFixture(Db);

                await f.Subject.AddOrUpdate(@case.Id, settings);

                Assert.Equal(Fixture.Today(), @case.CaseEvents.First().EventDate);

                f.BatchPolicingRequest.Received(1).Enqueue(Arg.Is<IEnumerable<PoliceCaseEvent>>(_ => _.Any(q => q.CaseEvent.EventId == configuredEventId)));
            }

            [Fact]
            public async Task PolicesImmediately()
            {
                var configuredEventId = Fixture.Integer();
                var settings = new FileSettings
                {
                    FileIntegrationEvent = configuredEventId
                };

                var @case = new CaseBuilder().Build().In(Db);

                var f = new FileIntegrationEventFixture(Db);

                var policingBatchNumber = Fixture.Integer();

                f.BatchPolicingRequest.Enqueue(Arg.Any<IEnumerable<PoliceCaseEvent>>())
                 .Returns(policingBatchNumber);

                await f.Subject.AddOrUpdate(@case.Id, settings);

                f.PolicingEngine.Received(1).PoliceAsync(policingBatchNumber);
            }

            [Fact]
            public async Task ThrowsIfFileIntegrationEventNotSetAsync()
            {
                var fixture = new FileIntegrationEventFixture(Db);

                await Assert.ThrowsAsync<InvalidOperationException>(
                                                                    async () =>
                                                                    {
                                                                        var settings = new FileSettings
                                                                        {
                                                                            FileIntegrationEvent = null
                                                                        };

                                                                        await fixture.Subject.AddOrUpdate(Fixture.Integer(), settings);
                                                                    });
            }

            [Fact]
            public async Task ThrowsIfFileSettingsNotProvided()
            {
                var fixture = new FileIntegrationEventFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(
                                                                async () => await fixture.Subject.AddOrUpdate(Fixture.Integer(), null));
            }

            [Fact]
            public async Task UpdatesFileIntegrationEvent()
            {
                var configuredEventId = Fixture.Integer();
                var settings = new FileSettings
                {
                    FileIntegrationEvent = configuredEventId
                };
                var @case = new CaseBuilder().Build().In(Db);
                new CaseEventBuilder {Cycle = 1, EventNo = configuredEventId, EventDate = Fixture.PastDate()}.BuildForCase(@case).In(Db);

                var f = new FileIntegrationEventFixture(Db);

                await f.Subject.AddOrUpdate(@case.Id, settings);

                Assert.Equal(Fixture.Today(), @case.CaseEvents.First().EventDate);

                f.BatchPolicingRequest.Received(1).Enqueue(Arg.Is<IEnumerable<PoliceCaseEvent>>(_ => _.Any(q => q.CaseEvent.EventId == configuredEventId)));
            }
        }

        public class FileIntegrationEventFixture : IFixture<FileIntegrationEvent>
        {
            public FileIntegrationEventFixture(InMemoryDbContext db)
            {
                BatchPolicingRequest = Substitute.For<IBatchPolicingRequest>();

                PolicingEngine = Substitute.For<IPolicingEngine>();

                SiteConfiguration = Substitute.For<ISiteConfiguration>();

                TransactionRecordal = Substitute.For<ITransactionRecordal>();

                Subject = new FileIntegrationEvent(db, PolicingEngine, BatchPolicingRequest, TransactionRecordal, SiteConfiguration, Fixture.Today);
            }

            public IBatchPolicingRequest BatchPolicingRequest { get; set; }

            public IPolicingEngine PolicingEngine { get; set; }

            public ISiteConfiguration SiteConfiguration { get; set; }

            public ITransactionRecordal TransactionRecordal { get; set; }

            public FileIntegrationEvent Subject { get; }
        }
    }
}