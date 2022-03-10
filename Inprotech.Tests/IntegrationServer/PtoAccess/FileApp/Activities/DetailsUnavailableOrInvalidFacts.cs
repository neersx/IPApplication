using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DetailsUnavailableOrInvalidFacts
    {
        public class HandleMethod : FactBase
        {
            [Theory]
            [InlineData(IpTypes.PatentPostPct)]
            [InlineData(IpTypes.TrademarkDirect)]
            [InlineData(IpTypes.DirectPatent)]
            public async Task ShouldRemoveAllFileCasesNotInFile(string ipType)
            {
                var sessionGuid = Guid.Empty;

                var caseIds = new[]
                {
                    Fixture.Integer(),
                    Fixture.Integer()
                };

                var parentCaseId = Fixture.Integer();

                var fixture = new DetailsUnavailableOrInvalidFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings());

                new FileCaseEntity
                {
                    CaseId = caseIds.First(),
                    IpType = ipType,
                    ParentCaseId = parentCaseId
                }.In(Db);

                new FileCaseEntity
                {
                    CaseId = caseIds.Last(),
                    IpType = ipType,
                    ParentCaseId = parentCaseId
                }.In(Db);

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.First(),
                               IpType = ipType,
                               ParentCaseId = parentCaseId
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.Last(),
                               IpType = ipType,
                               ParentCaseId = parentCaseId
                           }
                       }.AsQueryable());

                fixture.BufferedStringReader.Read(Arg.Any<string>())
                       .Returns(JsonConvert.SerializeObject(new[]
                       {
                           new FileCase
                           {
                               Id = Fixture.String()
                           }
                       }));

                await fixture.Subject.Handle(sessionGuid, caseIds, Fixture.String());

                Assert.Empty(Db.Set<FileCaseEntity>());
            }

            [Theory]
            [InlineData(IpTypes.PatentPostPct)]
            [InlineData(IpTypes.TrademarkDirect)]
            [InlineData(IpTypes.DirectPatent)]
            public async Task ShouldRemoveOnlyChildFileCaseNotInFile(string ipType)
            {
                var sessionGuid = Guid.Empty;

                var caseIds = new[]
                {
                    Fixture.Integer(),
                    Fixture.Integer()
                };

                var parentCaseId = Fixture.Integer();

                var fixture = new DetailsUnavailableOrInvalidFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings());

                new FileCaseEntity
                {
                    CaseId = caseIds.First(),
                    IpType = ipType,
                    ParentCaseId = parentCaseId,
                    CountryCode = "AU"
                }.In(Db);

                new FileCaseEntity
                {
                    CaseId = caseIds.Last(),
                    IpType = ipType,
                    ParentCaseId = parentCaseId,
                    CountryCode = "US"
                }.In(Db);

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.First(),
                               IpType = ipType,
                               ParentCaseId = parentCaseId,
                               CountryCode = "AU"
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.Last(),
                               IpType = ipType,
                               ParentCaseId = parentCaseId,
                               CountryCode = "US"
                           }
                       }.AsQueryable());

                fixture.BufferedStringReader.Read(Arg.Any<string>())
                       .Returns(JsonConvert.SerializeObject(new[]
                       {
                           new FileCase
                           {
                               Id = parentCaseId.ToString(),
                               Countries = new List<Country>(new[]
                               {
                                   new Country
                                   {
                                       Code = "AU"
                                   }
                               })
                           }
                       }));

                await fixture.Subject.Handle(sessionGuid, caseIds, Fixture.String());

                Assert.NotEmpty(Db.Set<FileCaseEntity>().Where(_ => _.CaseId == caseIds.First()));
                Assert.Empty(Db.Set<FileCaseEntity>().Where(_ => _.CaseId == caseIds.Last()));
            }

            [Fact]
            public async Task RemovesOldNotifications()
            {
                var case1 = new Case
                {
                    Source = DataSourceType.File,
                    CorrelationId = Fixture.Integer()
                }.In(Db);

                var case2 = new Case
                {
                    Source = DataSourceType.File,
                    CorrelationId = Fixture.Integer()
                }.In(Db);

                new CaseNotification
                {
                    Case = case1,
                    CaseId = case1.Id
                }.In(Db);

                var db = Db;

                var sessionGuid = Guid.Empty;

                var fixture = new DetailsUnavailableOrInvalidFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings());

                await fixture.Subject.Handle(sessionGuid,
                                             new[]
                                             {
                                                 case1.CorrelationId.GetValueOrDefault(),
                                                 case2.CorrelationId.GetValueOrDefault()
                                             }, Fixture.String());

                Assert.Empty(db.Set<CaseNotification>());
            }

            [Fact]
            public async Task ShouldRemoveAllIntegrationEventsForPctCasesNotInFile()
            {
                var sessionGuid = Guid.Empty;

                var caseIds = new[]
                {
                    Fixture.Integer(),
                    Fixture.Integer()
                };

                var pctId = Fixture.Integer();

                var fixture = new DetailsUnavailableOrInvalidFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    FileIntegrationEvent = Fixture.Integer()
                });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.First(),
                               ParentCaseId = pctId
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.Last(),
                               ParentCaseId = pctId
                           }
                       }.AsQueryable());

                fixture.BufferedStringReader.Read(Arg.Any<string>())
                       .Returns(JsonConvert.SerializeObject(new[]
                       {
                           new FileCase
                           {
                               Id = Fixture.String()
                           }
                       }));

                await fixture.Subject.Handle(sessionGuid, caseIds, Fixture.String());

                fixture.FileIntegrationEvent.Received(1).Clear(caseIds.First(), Arg.Any<FileSettings>()).IgnoreAwaitForNSubstituteAssertion();

                fixture.FileIntegrationEvent.Received(1).Clear(caseIds.Last(), Arg.Any<FileSettings>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldRemoveOnlyIntegrationEventsForChildCasesNotInFile()
            {
                var sessionGuid = Guid.Empty;

                var caseIds = new[]
                {
                    Fixture.Integer(),
                    Fixture.Integer()
                };

                var pctId = Fixture.Integer();

                var fixture = new DetailsUnavailableOrInvalidFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    FileIntegrationEvent = Fixture.Integer()
                });

                fixture.FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                       .Returns(new[]
                       {
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.First(),
                               ParentCaseId = pctId,
                               CountryCode = "AU"
                           },
                           new FileInstructAllowedCase
                           {
                               CaseId = caseIds.Last(),
                               ParentCaseId = pctId,
                               CountryCode = "US"
                           }
                       }.AsQueryable());

                fixture.BufferedStringReader.Read(Arg.Any<string>())
                       .Returns(JsonConvert.SerializeObject(new[]
                       {
                           new FileCase
                           {
                               Id = pctId.ToString(),
                               Countries = new List<Country>(new[]
                               {
                                   new Country
                                   {
                                       Code = "AU"
                                   }
                               })
                           }
                       }));

                await fixture.Subject.Handle(sessionGuid, caseIds, Fixture.String());

                fixture.FileIntegrationEvent.DidNotReceive().Clear(caseIds.First(), Arg.Any<FileSettings>()).IgnoreAwaitForNSubstituteAssertion();

                fixture.FileIntegrationEvent.Received(1).Clear(caseIds.Last(), Arg.Any<FileSettings>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldUpdateCaseProcessedInBulk()
            {
                var sessionGuid = Guid.Empty;

                var caseIds = new int[0];

                var fixture = new DetailsUnavailableOrInvalidFixture(Db);

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings());

                await fixture.Subject.Handle(sessionGuid, caseIds, Fixture.String());

                fixture.ScheduleRuntimeEvents.UpdateCasesProcessed(sessionGuid, caseIds);
            }
        }
    }

    public class DetailsUnavailableOrInvalidFixture : IFixture<DetailsUnavailableOrInvalid>
    {
        public DetailsUnavailableOrInvalidFixture(InMemoryDbContext db)
        {
            BufferedStringReader = Substitute.For<IBufferedStringReader>();

            FileInstructAllowedCases = Substitute.For<IFileInstructAllowedCases>();
            FileInstructAllowedCases.Retrieve(Arg.Any<FileSettings>())
                                    .Returns(Enumerable.Empty<FileInstructAllowedCase>().AsQueryable());

            FileIntegrationEvent = Substitute.For<IFileIntegrationEvent>();

            FileSettingsResolver = Substitute.For<IFileSettingsResolver>();

            ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();

            Subject = new DetailsUnavailableOrInvalid(db, db, ScheduleRuntimeEvents,
                                                      FileSettingsResolver, FileInstructAllowedCases, FileIntegrationEvent, BufferedStringReader);
        }

        public IBufferedStringReader BufferedStringReader { get; set; }

        public IFileInstructAllowedCases FileInstructAllowedCases { get; set; }

        public IFileIntegrationEvent FileIntegrationEvent { get; set; }

        public IFileSettingsResolver FileSettingsResolver { get; set; }

        public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }

        public DetailsUnavailableOrInvalid Subject { get; }
    }
}