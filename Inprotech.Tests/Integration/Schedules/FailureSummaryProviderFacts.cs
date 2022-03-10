using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class FailureSummaryProviderFacts
    {
        public class RecoveryItemsByDataSourceMethod
        {
            [Theory]
            [InlineData(ArtifactInclusion.Exclude, 0)]
            [InlineData(ArtifactInclusion.Include, 2)]
            public void ShouldNotIncludeArtefactsWhenInstructed(ArtifactInclusion artefactInclusion, int expectedCount)
            {
                var failedItems = new[]
                {
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr,
                        Artifact = new byte[0]
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A2",
                        ArtifactId = 2,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr,
                        Artifact = new byte[0]
                    }
                };

                var failedSchedules = new[]
                {
                    new FailedSchedule
                    {
                        ScheduleId = 1,
                        Name = "Schedule1",
                        DataSource = DataSourceType.UsptoTsdr,
                        FailedCasesCount = 10,
                        RecoveryStatus = RecoveryScheduleStatus.Idle
                    }
                };

                var f = new FailureSummaryProviderFixture()
                        .WithScheduleRecoverableData(failedItems)
                        .WithScheduleDetails(failedSchedules);

                var result = f.Subject.RecoverableItemsByDataSource(new[] { DataSourceType.UsptoTsdr }, artefactInclusion);

                Assert.Equal(expectedCount, result.SelectMany(_ => _.Cases).Count(_ => _.Artifact != null));
            }

            [Fact]
            public void CallsRecoverableScheduleReaderWithGivenDataSource()
            {
                var f = new FailureSummaryProviderFixture()
                        .WithScheduleRecoverableData(new[] { new FailedItem { ScheduleId = 1 } })
                        .WithScheduleDetails(new[] { new FailedSchedule { ScheduleId = 1 } });

                var r = f.Subject
                         .RecoverableItemsByDataSource(
                                                       new[]
                                                       {
                                                           DataSourceType.Epo, DataSourceType.UsptoPrivatePair
                                                       }, ArtifactInclusion.Exclude).ToArray();

                Assert.NotEmpty(r);
                Assert.Equal(2, r.Count());
                Assert.Equal(1, r.Count(_ => _.DataSource == DataSourceType.Epo.ToString()));
                Assert.Equal(1, r.Count(_ => _.DataSource == DataSourceType.UsptoPrivatePair.ToString()));

                f.ScheduleRecoverableReader.Received(1).GetAllFor(Arg.Any<DataSourceType[]>(), Arg.Any<ArtifactInclusion>());
                f.ScheduleRecoverableReader.Received(1).GetFailedScheduleDetails(Arg.Any<FailedItem[]>());
            }

            [Fact]
            public void ReturnsDetailsDataSourceWithAggregatedFailedDocuments()
            {
                var failedItems = new[]
                {
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 3,
                        ApplicationNumber = "D1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Document,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    }
                };

                var failedSchedules = new[]
                {
                    new FailedSchedule
                    {
                        ScheduleId = 1,
                        Name = "Schedule1",
                        DataSource = DataSourceType.UsptoTsdr,
                        AggregateFailures = true,
                        FailedCasesCount = 10,
                        RecoveryStatus = RecoveryScheduleStatus.Pending
                    }
                };

                var f = new FailureSummaryProviderFixture()
                        .WithScheduleRecoverableData(failedItems)
                        .WithScheduleDetails(failedSchedules);

                var result = f.Subject.RecoverableItemsByDataSource(new[] { DataSourceType.UsptoTsdr }, ArtifactInclusion.Exclude);

                Assert.NotNull(result);
                var dataSourceTsdr = result.First();

                Assert.Single(dataSourceTsdr.Schedules);
                Assert.Equal(1, dataSourceTsdr.Documents.Count());
                Assert.Equal(1, dataSourceTsdr.FailedDocumentCount);
            }

            [Fact]
            public void ReturnsDetailsDataSourceWithCorrelationIds()
            {
                var failedItems = new[]
                {
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr
                    }
                };

                var failedSchedules = new[]
                {
                    new FailedSchedule
                    {
                        ScheduleId = 1,
                        Name = "Schedule1",
                        DataSource = DataSourceType.UsptoTsdr,
                        FailedCasesCount = 10,
                        RecoveryStatus = RecoveryScheduleStatus.Pending
                    }
                };

                var f = new FailureSummaryProviderFixture()
                        .WithScheduleRecoverableData(failedItems)
                        .WithScheduleDetails(failedSchedules);

                var result = f.Subject.RecoverableItemsByDataSource(new[] { DataSourceType.UsptoTsdr }, ArtifactInclusion.Exclude);

                Assert.NotNull(result);

                var dataSourceTsdr = result.First();

                Assert.Contains("1234", dataSourceTsdr.Cases.First().CorrelationIds);
                Assert.Contains("4444", dataSourceTsdr.Cases.First().CorrelationIds);
            }

            [Fact]
            public void ReturnsDetailsForDataSource()
            {
                var failedItems = new[]
                {
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A2",
                        ArtifactId = 3,
                        ArtifactType = ArtifactType.Document,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A3",
                        ArtifactId = 3,
                        ArtifactType = ArtifactType.Document,
                        CorrelationId = "5555",
                        DataSourceType = DataSourceType.UsptoTsdr
                    }
                };
                var failedSchedules = new[]
                {
                    new FailedSchedule
                    {
                        ScheduleId = 1,
                        Name = "Schedule1",
                        DataSource = DataSourceType.UsptoTsdr,
                        FailedCasesCount = 10,
                        RecoveryStatus = RecoveryScheduleStatus.Pending
                    }
                };

                var f = new FailureSummaryProviderFixture()
                        .WithScheduleRecoverableData(failedItems)
                        .WithScheduleDetails(failedSchedules);

                var result = f.Subject.RecoverableItemsByDataSource(new[] { DataSourceType.UsptoTsdr }, ArtifactInclusion.Exclude);

                Assert.NotNull(result);

                var dataSourceTsdr = result.First();

                Assert.Equal(DataSourceType.UsptoTsdr.ToString(), dataSourceTsdr.DataSource);
                Assert.Single(dataSourceTsdr.Schedules);
                Assert.Equal(1, dataSourceTsdr.Schedules.First().ScheduleId);
                Assert.Equal(10, dataSourceTsdr.Schedules.First().FailedCasesCount);
                Assert.Equal("Schedule1", dataSourceTsdr.Schedules.First().Name);
                Assert.Single(dataSourceTsdr.Cases);
                Assert.Equal(1, dataSourceTsdr.FailedCount);
                Assert.False(dataSourceTsdr.RecoverPossible);
                Assert.Equal(1, dataSourceTsdr.Documents.Count());
                Assert.Equal(1, dataSourceTsdr.FailedDocumentCount);
            }

            [Fact]
            public void ReturnsRecoverPossibleIfIdleSchedules()
            {
                var failedItems = new[]
                {
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A2",
                        ArtifactId = 2,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr
                    }
                };

                var failedSchedules = new[]
                {
                    new FailedSchedule
                    {
                        ScheduleId = 1,
                        Name = "Schedule1",
                        DataSource = DataSourceType.UsptoTsdr,
                        FailedCasesCount = 10,
                        RecoveryStatus = RecoveryScheduleStatus.Idle
                    }
                };

                var f = new FailureSummaryProviderFixture()
                        .WithScheduleRecoverableData(failedItems)
                        .WithScheduleDetails(failedSchedules);

                var result = f.Subject.RecoverableItemsByDataSource(new[] { DataSourceType.UsptoTsdr }, ArtifactInclusion.Exclude);

                Assert.NotNull(result);

                var dataSourceTsdr = result.First();

                Assert.True(dataSourceTsdr.RecoverPossible);
            }
        }

        public class AllFailedItemsMethod
        {
            [Fact]
            public void FailedItemsAreDistinctByTypeAndCorrelation()
            {
                var failedItems = new[]
                {
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A2",
                        ArtifactId = 3,
                        ArtifactType = ArtifactType.Document,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A2",
                        ArtifactId = 3,
                        ArtifactType = ArtifactType.Document,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr
                    }
                };

                var f = new FailureSummaryProviderFixture()
                    .WithScheduleRecoverableData(failedItems);

                var dataSourceTypes = new[] { DataSourceType.UsptoTsdr, DataSourceType.Epo, DataSourceType.UsptoPrivatePair };

                var r = f.Subject.AllFailedItems(dataSourceTypes, ArtifactInclusion.Exclude);

                Assert.Equal(2, r.Count());

                f.ScheduleRecoverableReader.Received(1).GetAllFor(dataSourceTypes, Arg.Any<ArtifactInclusion>());
            }

            [Fact]
            public void ReturnsAllFailedItems()
            {
                var failedItems = new[]
                {
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A1",
                        ArtifactId = 1,
                        ArtifactType = ArtifactType.Case,
                        CorrelationId = "1234",
                        DataSourceType = DataSourceType.UsptoTsdr
                    },
                    new FailedItem
                    {
                        ScheduleId = 1,
                        ApplicationNumber = "A2",
                        ArtifactId = 2,
                        ArtifactType = ArtifactType.Document,
                        CorrelationId = "4444",
                        DataSourceType = DataSourceType.UsptoTsdr
                    }
                };

                var f = new FailureSummaryProviderFixture()
                    .WithScheduleRecoverableData(failedItems);

                var dataSourceTypes = new[] { DataSourceType.UsptoTsdr, DataSourceType.Epo, DataSourceType.UsptoPrivatePair };

                var r = f.Subject.AllFailedItems(dataSourceTypes, ArtifactInclusion.Exclude);

                Assert.Equal(2, r.Count());

                f.ScheduleRecoverableReader.Received(1).GetAllFor(dataSourceTypes, Arg.Any<ArtifactInclusion>());
            }
        }

        public class FailureSummaryProviderFixture : IFixture<FailureSummaryProvider>
        {
            public FailureSummaryProviderFixture()
            {
                ScheduleRecoverableReader = Substitute.For<IScheduleRecoverableReader>();
                MessageFactory = Substitute.For<IIndex<DataSourceType, IScheduleMessages>>();
                MessageFactory.TryGetValue(Arg.Any<DataSourceType>(), out _)
                              .Returns(x =>
                              {
                                  x[1] = null;
                                  return false;
                              });

                Subject = new FailureSummaryProvider(ScheduleRecoverableReader, MessageFactory);
            }

            public IScheduleRecoverableReader ScheduleRecoverableReader { get; }

            IIndex<DataSourceType, IScheduleMessages> MessageFactory { get; }
            public FailureSummaryProvider Subject { get; }

            public FailureSummaryProviderFixture WithScheduleRecoverableData(IEnumerable<FailedItem> failedItems)
            {
                ScheduleRecoverableReader.GetAllFor(Arg.Any<DataSourceType[]>(), Arg.Any<ArtifactInclusion>())
                                         .Returns(
                                                  x =>
                                                  {
                                                      var exclude = (ArtifactInclusion)x[1] == ArtifactInclusion.Exclude;
                                                      if (exclude)
                                                      {
                                                          var y = failedItems.ToList();
                                                          y.ForEach(_ => _.Artifact = null);
                                                          return y;
                                                      }

                                                      return failedItems;
                                                  });

                ScheduleRecoverableReader.GetAll(Arg.Any<ArtifactInclusion>())
                                         .Returns(
                                                  x => failedItems.AsQueryable());

                return this;
            }

            public FailureSummaryProviderFixture WithScheduleDetails(IEnumerable<FailedSchedule> failedSchedules)
            {
                ScheduleRecoverableReader.GetFailedScheduleDetails(Arg.Any<FailedItem[]>()).Returns(failedSchedules);
                return this;
            }
        }
    }
}