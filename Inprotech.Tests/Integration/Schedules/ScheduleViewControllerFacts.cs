using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ScheduleViewControllerFacts : FactBase
    {
        public ScheduleViewControllerFacts()
        {
            new Case
            {
                Id = 1,
                ApplicationNumber = "a",
                PublicationNumber = "p",
                RegistrationNumber = "r"
            }.In(Db);

            new Document
            {
                Id = 1,
                ApplicationNumber = "d",
                PublicationNumber = "p",
                RegistrationNumber = "r"
            }.In(Db);

            _schedule = new Schedule
            {
                Name = "schedule",
                Parent = new Schedule()
            }.In(Db);

            _disabledSchedule = new Schedule
            {
                Name = "disabledSchedule",
                Parent = new Schedule(),
                State = ScheduleState.Disabled
            }.In(Db);

            _continuousSchedule = new Schedule
            {
                Name = "continuousSchedule",
                Parent = new Schedule(),
                Type = ScheduleType.Continuous,
                State = ScheduleState.Active
            }.In(Db);

            _schedule.Failures.Add(
                                   new ScheduleFailure(
                                                       _schedule,
                                                       Fixture.Today(),
                                                       new JObject { { "log", "log" } }.ToString()));
        }

        readonly Schedule _schedule;
        readonly Schedule _disabledSchedule;
        readonly Schedule _continuousSchedule;
        readonly ScheduleExecutionsModel[] _scheduleExecution = new ScheduleExecutionsModel[0];
        readonly RecoveryScheduleStatus _status = RecoveryScheduleStatus.Running;

        Case BuildCase(string applicationNumber = null)
        {
            return new Case
            {
                ApplicationNumber = applicationNumber ?? Fixture.String()
            }.In(Db);
        }

        Document BuildDocument(string applicationNumber = null)
        {
            return new Document
            {
                ApplicationNumber = applicationNumber ?? Fixture.String()
            }.In(Db);
        }

        [Fact]
        public async Task ConsidersDocumentsWhichHaveNotYetBeenLinkedToTheCaseForRecovery()
        {
            var document1 = BuildDocument();
            var document2 = BuildDocument();

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_schedule).Returns(new { });
            f.RecoverableItems.FindBySchedule(_schedule.Id)
             .Returns(
                      new[]
                      {
                          new RecoveryInfo
                          {
                              CorrelationId = "12345",
                              DocumentIds = new[]
                              {
                                  document1.Id
                              },
                              OrphanedDocumentIds = new[]
                              {
                                  document1.Id
                              }
                          },
                          new RecoveryInfo
                          {
                              CorrelationId = "45678",
                              DocumentIds = new[]
                              {
                                  document2.Id
                              },
                              OrphanedDocumentIds = new[]
                              {
                                  document2.Id
                              }
                          }
                      });

            var result = await f.Subject.Get(_schedule.Id);

            Assert.Equal(2, result.RecoverableCasesCount);
            Assert.Equal("12345", result.RecoverableCases[0].CorrelationIds);
            Assert.Equal("45678", result.RecoverableCases[1].CorrelationIds);
        }

        [Fact]
        public async Task RecoveryCasesIsReturnedCorrelated()
        {
            var case1 = BuildCase();
            var case2 = BuildCase();
            var case3 = BuildCase();
            var case4 = BuildCase();
            var case5 = BuildCase();

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_schedule).Returns(new { });
            f.RecoverableItems.FindBySchedule(_schedule.Id)
             .Returns(
                      new[]
                      {
                          new RecoveryInfo
                          {
                              CorrelationId = "12345",
                              CaseIds = new[]
                              {
                                  case1.Id, case2.Id, case3.Id
                              }
                          },
                          new RecoveryInfo
                          {
                              CorrelationId = "45678",
                              CaseIds = new[]
                              {
                                  case4.Id, case5.Id
                              }
                          }
                      });

            var result = await f.Subject.Get(_schedule.Id);

            Assert.Equal(5, result.RecoverableCasesCount);
            Assert.Equal("12345", result.RecoverableCases[0].CorrelationIds);
            Assert.Equal("12345", result.RecoverableCases[1].CorrelationIds);
            Assert.Equal("12345", result.RecoverableCases[2].CorrelationIds);
            Assert.Equal("45678", result.RecoverableCases[3].CorrelationIds);
            Assert.Equal("45678", result.RecoverableCases[4].CorrelationIds);
        }

        [Fact]
        public async Task RecoveryDocumentsIsReturned()
        {
            var case1 = BuildCase();
            var document1 = BuildDocument();
            var document2 = BuildDocument();
            var document3 = BuildDocument();
            var document4 = BuildDocument();
            var documents = new[]
            {
                document1, document2, document3, document4
            };

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_schedule).Returns(new { });
            f.RecoverableItems.FindBySchedule(_schedule.Id)
             .Returns(
                      new[]
                      {
                          new RecoveryInfo
                          {
                              CorrelationId = "12345",
                              CaseIds = new[]
                              {
                                  case1.Id
                              },
                              DocumentIds = new[]
                              {
                                  document1.Id, document2.Id
                              }
                          },
                          new RecoveryInfo
                          {
                              CorrelationId = "45678",
                              DocumentIds = new[]
                              {
                                  document3.Id, document4.Id
                              }
                          }
                      });

            var result = await f.Subject.Get(_schedule.Id);

            Assert.Equal(1, result.RecoverableCasesCount);
            Assert.Equal("12345", result.RecoverableCases[0].CorrelationIds);

            Assert.Equal(4, result.RecoverableDocumentsCount);
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[0].DocumentId));
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[1].DocumentId));
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[2].DocumentId));
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[3].DocumentId));
        }

        [Fact]
        public async Task AggregatedRecoverableItemsAreReturned()
        {
            var case1 = BuildCase();
            var document1 = BuildDocument();
            var document2 = BuildDocument();
            var document3 = BuildDocument();
            var document4 = BuildDocument();
            var documents = new[]
            {
                document1, document2, document3, document4
            };

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_continuousSchedule).Returns(new { });
            f.RecoverableItems.FindByDataType(_continuousSchedule.DataSourceType)
             .Returns(
                      new[]
                      {
                          new RecoveryInfo
                          {
                              CorrelationId = "12345",
                              CaseIds = new[]
                              {
                                  case1.Id
                              },
                              DocumentIds = new[]
                              {
                                  document1.Id, document2.Id
                              }
                          },
                          new RecoveryInfo
                          {
                              CorrelationId = "45678",
                              DocumentIds = new[]
                              {
                                  document3.Id, document4.Id
                              }
                          }
                      });

            var result = await f.Subject.Get(_continuousSchedule.Id);

            Assert.Equal(1, result.RecoverableCasesCount);
            Assert.Equal("12345", result.RecoverableCases[0].CorrelationIds);

            Assert.Equal(4, result.RecoverableDocumentsCount);
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[0].DocumentId));
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[1].DocumentId));
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[2].DocumentId));
            Assert.Single(documents.Where(_ => _.Id == result.RecoverableDocuments[3].DocumentId));
        }

        [Fact]
        public async Task RecoveryItemsAreNotCalculatedIfScheduleDisabled()
        {
            var case1 = BuildCase();
            var document1 = BuildDocument();
            var document2 = BuildDocument();
            var document3 = BuildDocument();
            var document4 = BuildDocument();
            var documents = new[]
            {
                document1, document2, document3, document4
            };

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_disabledSchedule).Returns(new { });

            var result = await f.Subject.Get(_disabledSchedule.Id);

            Assert.Equal(0, result.RecoverableCasesCount);
            Assert.Equal(0, result.RecoverableDocumentsCount);
            Assert.Empty(result.RecoverableCases);
            Assert.Empty(result.RecoverableDocuments);
        }

        [Fact]
        public async Task ReturnsOnlyDistinctRecoverableCases()
        {
            var applicationNumberForCase1 = Fixture.String();
            var applicationNumberForCase2 = Fixture.String();

            var case1 = BuildCase(applicationNumberForCase1);
            var case2 = BuildCase(applicationNumberForCase2);
            var document1 = BuildDocument(applicationNumberForCase1);
            var document2 = BuildDocument(applicationNumberForCase2);

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_schedule).Returns(new { });
            f.RecoverableItems.FindBySchedule(_schedule.Id)
             .Returns(
                      new[]
                      {
                          new RecoveryInfo
                          {
                              CorrelationId = "12345",
                              CaseIds = new[]
                              {
                                  case1.Id
                              },
                              DocumentIds = new[]
                              {
                                  document1.Id
                              },
                              OrphanedDocumentIds = new[]
                              {
                                  document1.Id
                              }
                          },
                          new RecoveryInfo
                          {
                              CorrelationId = "45678",
                              CaseIds = new[]
                              {
                                  case2.Id
                              },
                              DocumentIds = new[]
                              {
                                  document2.Id
                              },
                              OrphanedDocumentIds = new[]
                              {
                                  document2.Id
                              }
                          }
                      });

            var result = await f.Subject.Get(_schedule.Id);

            Assert.Equal(2, result.RecoverableCasesCount);
            Assert.Equal("12345", result.RecoverableCases[0].CorrelationIds);
            Assert.Equal("45678", result.RecoverableCases[1].CorrelationIds);
        }

        [Fact]
        public async Task ReturnsTheSchedule()
        {
            var recoveryInfo = new RecoveryInfo
            {
                CaseIds = new[] { 1 }
            };

            var obj = new { };

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_schedule).Returns(obj);
            f.RecoverableItems.FindBySchedule(_schedule.Id).Returns(new[] { recoveryInfo });
            f.ScheduleExecutions.Get(_schedule.Id).Returns(_scheduleExecution.AsQueryable());
            f.RecoveryScheduleStatusReader.Read(_schedule.Id).Returns(_status);

            var result = await f.Subject.Get(_schedule.Id);

            f.ScheduleMessageFactory.Received(1).TryGetValue(_schedule.DataSourceType, out _);
            Assert.Equal(obj, result.Schedule);
            Assert.Equal(recoveryInfo.CaseIds.Count(), result.RecoverableCasesCount);
            Assert.Equal(_status.ToString(), result.RecoveryScheduleStatus);
            Assert.NotNull(result.RecoverableCases);
            Assert.False(result.missingBackgroundProcessLoginId);
        }

        [Fact]
        public async Task ReturnsTheBackgroundLoginProcessId()
        {
            var f = new ScheduleViewControllerFixture(Db);
            f.SiteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId).Returns(string.Empty);

            var result = await f.Subject.Get(_schedule.Id);

            Assert.True(result.missingBackgroundProcessLoginId);
        }

        [Fact]
        public async Task ReturnsTheScheduleWithCorrectRecoverableInfo()
        {
            var recoveryInfo = new RecoveryInfo
            {
                CaseIds = new[] { 1 },
                CaseWithoutArtifactId = new[]
                {
                    new FailedItem
                    {
                        ApplicationNumber = "a",PublicationNumber = "p",
                        RegistrationNumber = "r", Artifact = null, ArtifactId = null,
                        ArtifactType = ArtifactType.Case, CorrelationId = "1000", DataSourceType = DataSourceType.UsptoPrivatePair
                    },
                    new FailedItem
                    {
                        ApplicationNumber = "a2", Artifact = null, ArtifactId = null,
                        ArtifactType = ArtifactType.Case, CorrelationId = "1000", DataSourceType = DataSourceType.UsptoPrivatePair
                    }
                }
            };

            var obj = new { };

            var f = new ScheduleViewControllerFixture(Db);
            f.DataSourceSchedule.View(_schedule).Returns(obj);
            f.RecoverableItems.FindBySchedule(_schedule.Id).Returns(new[] { recoveryInfo });
            f.ScheduleExecutions.Get(_schedule.Id).Returns(_scheduleExecution.AsQueryable());
            f.RecoveryScheduleStatusReader.Read(_schedule.Id).Returns(_status);

            var result = await f.Subject.Get(_schedule.Id);

            f.ScheduleMessageFactory.Received(1).TryGetValue(_schedule.DataSourceType, out _);
            Assert.Equal(obj, result.Schedule);
            Assert.Equal(1, result.RecoverableCasesCount);
            Assert.Equal(_status.ToString(), result.RecoveryScheduleStatus);
            Assert.NotNull(result.RecoverableCases);
        }
    }

    public class ScheduleViewControllerFixture : IFixture<ScheduleViewController>
    {
        public ScheduleViewControllerFixture(InMemoryDbContext db)
        {
            Repository = db;
            DataSourceSchedule = Substitute.For<IDataSourceSchedule>();
            ScheduleExecutions = Substitute.For<IScheduleExecutions>();
            RecoverableItems = Substitute.For<IRecoverableItems>();
            RecoveryScheduleStatusReader = Substitute.For<IRecoveryScheduleStatusReader>();
            ScheduleMessageFactory = Substitute.For<IIndex<DataSourceType, IScheduleMessages>>();
            ScheduleMessageFactory.TryGetValue(Arg.Any<DataSourceType>(), out _)
                                  .Returns(x =>
                                  {
                                      x[1] = null;
                                      return false;
                                  });

            SiteControlReader = Substitute.For<ISiteControlReader>();
            SiteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId).Returns(Fixture.String());

            Subject = new ScheduleViewController(Repository, DataSourceSchedule, ScheduleExecutions, RecoverableItems,
                                                 RecoveryScheduleStatusReader, ScheduleMessageFactory, SiteControlReader);
        }

        public IRecoveryScheduleStatusReader RecoveryScheduleStatusReader { get; set; }

        public IScheduleExecutions ScheduleExecutions { get; set; }

        public IRepository Repository { get; set; }

        public IDataSourceSchedule DataSourceSchedule { get; set; }

        public IRecoverableItems RecoverableItems { get; set; }

        public IIndex<DataSourceType, IScheduleMessages> ScheduleMessageFactory { get; }

        public ISiteControlReader SiteControlReader { get; }

        public ScheduleViewController Subject { get; }
    }
}