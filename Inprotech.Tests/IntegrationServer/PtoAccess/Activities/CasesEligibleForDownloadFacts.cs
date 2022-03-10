using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Activities
{
    public class CasesEligibleForDownloadFacts
    {
        public class ResolveAsyncMethod
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                Id = Guid.NewGuid(),
                Name = "Schedule1",
                DataSourceType = DataSourceType.Epo
            };

            const int ExecuteAs = 1;
            const int SavedQueryId = 2;

            [Theory]
            [InlineData(DataSourceType.IpOneData)]
            public async Task DispatchesEligibleCasesForDownload(DataSourceType sourceType)
            {
                const int chunkSize = 10;

                var f = new CasesEligibleForDownloadFixture()
                        .WithChunkSize(chunkSize)
                        .WithEligibleCases(2, sourceType)
                        .WithDispatchedItemsAsync();

                _dataDownload.DataSourceType = sourceType;

                await f.Subject
                       .ResolveAsync(_dataDownload, SavedQueryId, ExecuteAs, f.FuncFixture.CreateDownloadActivityAsync);

                f.ChunckedDownloadRequests.Received(1)
                 .DispatchAsync(
                                Arg.Is<List<DataDownload>>(x => x.Count == 2),
                                chunkSize,
                                f.FuncFixture.CreateDownloadActivityAsync
                               )
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(DataSourceType.IpOneData)]
            public async Task OnlyEligibleCasesWithRequiredNumbersAreDispatched(DataSourceType source)
            {
                const int chunkSize = 10;

                var f = new CasesEligibleForDownloadFixture()
                        .WithChunkSize(chunkSize)
                        .WithDispatchedItemsAsync();

                _dataDownload.DataSourceType = source;

                await f.Subject
                       .ResolveAsync(_dataDownload, SavedQueryId, ExecuteAs, f.FuncFixture.CreateDownloadActivityAsync);

                f.ChunckedDownloadRequests.Received(1)
                 .DispatchAsync(
                                Arg.Any<List<DataDownload>>(),
                                chunkSize,
                                f.FuncFixture.CreateDownloadActivityAsync
                               )
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DownloadsChunksInSequence()
            {
                var f = new CasesEligibleForDownloadFixture()
                        .WithChunkSize(1) /* not used */
                        .WithEligibleCases(10)
                        .WithAsManyDispatchedItemsAsync();

                var r = await f.Subject
                               .ResolveAsync(_dataDownload, SavedQueryId, ExecuteAs, f.FuncFixture.CreateDownloadActivityAsync);

                Assert.Equal(10, r.Items.Count());
            }

            [Fact]
            public async Task FeedsInformationToScheduleInsights()
            {
                const int numberOfEligibleCases = 4;

                var f = new CasesEligibleForDownloadFixture()
                        .WithChunkSize(10)
                        .WithEligibleCases(numberOfEligibleCases);

                var listOfCasesCompressed = new byte[0];

                f.ArtefactsService.Compress(Arg.Any<string>(), Arg.Any<string>()).Returns(listOfCasesCompressed);

                await f.Subject
                       .ResolveAsync(_dataDownload, SavedQueryId, ExecuteAs, f.FuncFixture.CreateDownloadActivityAsync);

                f.ArtefactsService.Received(1).Compress("caselist.json", Arg.Is<string>(_ => JArray.Parse(_).Count == numberOfEligibleCases))
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ScheduleRuntimeEvents.Received(1).IncludeCases(_dataDownload.Id, numberOfEligibleCases, listOfCasesCompressed);
            }
        }

        public class CasesEligibleForDownloadFixture : IFixture<CasesEligibleForDownload>
        {
            readonly List<EligibleCase> _eligibleCases = new List<EligibleCase>();

            public CasesEligibleForDownloadFixture()
            {
                EligibleCases = Substitute.For<IEligibleCases>();

                CommonSettings = Substitute.For<ICommonSettings>();

                ArtefactsService = Substitute.For<IArtifactsService>();

                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

                ChunckedDownloadRequests = Substitute.For<IChunckedDownloadRequests>();

                FuncFixture = Substitute.For<IFuncFixture>();

                FuncFixture.CreateDownloadActivity(Arg.Any<DataDownload[]>())
                           .Returns(DefaultActivity.NoOperation());

                FuncFixture.CreateDownloadActivityAsync(Arg.Any<DataDownload[]>())
                           .Returns(DefaultActivity.NoOperation());

                Subject = new CasesEligibleForDownload(EligibleCases, CommonSettings, ArtefactsService, ScheduleRuntimeEvents,
                                                       ChunckedDownloadRequests);
            }

            public IEligibleCases EligibleCases { get; set; }

            public ICommonSettings CommonSettings { get; set; }

            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

            public IArtifactsService ArtefactsService { get; set; }

            public IChunckedDownloadRequests ChunckedDownloadRequests { get; set; }

            public IFuncFixture FuncFixture { get; set; }

            public CasesEligibleForDownload Subject { get; }

            public CasesEligibleForDownloadFixture WithChunkSize(int chunkSize)
            {
                CommonSettings.GetChunkSize(Arg.Any<DataSourceType>()).Returns(chunkSize);
                return this;
            }

            public CasesEligibleForDownloadFixture WithEligibleCases(int numCases,
                                                                     DataSourceType dataSourceType = DataSourceType.Epo)
            {
                _eligibleCases.Clear();

                for (var i = 0; i < numCases; i++)
                {
                    _eligibleCases.Add(new EligibleCase
                    {
                        ApplicationNumber = Fixture.String("App"),
                        RegistrationNumber = Fixture.String("Reg"),
                        PublicationNumber = Fixture.String("Pub"),
                        SystemCode = ExternalSystems.SystemCode(dataSourceType)
                    });
                }

                EligibleCases
                    .Resolve(Arg.Any<DataDownload>(), Arg.Any<int>(), Arg.Any<int>())
                    .Returns(_eligibleCases.AsQueryable());

                return this;
            }

            public CasesEligibleForDownloadFixture WithDispatchedItems(params Activity[] activities)
            {
                var r = activities ?? new Activity[0];

                ChunckedDownloadRequests
                    .Dispatch(
                              Arg.Any<List<DataDownload>>(),
                              Arg.Any<int>(),
                              FuncFixture.CreateDownloadActivity
                             )
                    .Returns(r);

                return this;
            }

            public CasesEligibleForDownloadFixture WithDispatchedItemsAsync(params Activity[] activities)
            {
                var r = activities ?? new Activity[0];

                ChunckedDownloadRequests
                    .DispatchAsync(
                                   Arg.Any<List<DataDownload>>(),
                                   Arg.Any<int>(),
                                   FuncFixture.CreateDownloadActivityAsync
                                  )
                    .Returns(r);

                return this;
            }

            public CasesEligibleForDownloadFixture WithAsManyDispatchedItems()
            {
                var d = _eligibleCases.Select(
                                              _ => DefaultActivity.NoOperation()
                                             );

                return WithDispatchedItems(d.ToArray());
            }

            public CasesEligibleForDownloadFixture WithAsManyDispatchedItemsAsync()
            {
                var d = _eligibleCases.Select(
                                              _ => DefaultActivity.NoOperation()
                                             );

                return WithDispatchedItemsAsync(d.ToArray());
            }
        }
    }
}