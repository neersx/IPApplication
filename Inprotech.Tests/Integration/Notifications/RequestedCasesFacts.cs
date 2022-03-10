using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;
using InprotechCase = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Integration.Notifications
{
    public class RequestedCasesFacts
    {
        public class LoadNotificationsMethods : FactBase
        {
            [Fact]
            public async Task DoNotReturnWhenNotificationNotAvailable()
            {
                var ptoCase = new Case().In(Db);

                var f = new RequestedCasesFixture(Db)
                        .WithCase(out var @case, AccessPermissionLevel.Select)
                        .ReturnsSystemCodes("A")
                        .ReturnsMatchingCases(
                                              new Dictionary<int, int>
                                              {
                                                  {ptoCase.Id, @case.Id}
                                              })
                        .Configure();

                var r = await f.Subject.LoadNotifications(new[] {ptoCase.Id.ToString(), @case.Id.ToString()});

                Assert.Empty(r);
            }

            [Fact]
            public async Task FilterOnProvidedDataSource()
            {
                var f = new RequestedCasesFixture(Db).ReturnsSystemCodes("A", "B", "C")
                                                     .ReturnsMatchingCases()
                                                     .Configure();

                await f.Subject.LoadNotifications(new[] {"1", "2"}, new[] {DataSourceType.IpOneData});

                f.ExternalSystems.Received(0).DataSources();
                f.MatchingCases.Resolve("Innography", Arg.Any<int[]>());
            }

            [Fact]
            public async Task ResolvesDataSourcesInUse()
            {
                var f = new RequestedCasesFixture(Db)
                        .ReturnsSystemCodes("A", "B", "C")
                        .ReturnsMatchingCases()
                        .Configure();

                await f.Subject.LoadNotifications(new[] {"1", "2"});

                f.ExternalSystems.Received(1).DataSources();

                f.MatchingCases.Resolve("A,B,C", Arg.Any<int[]>());
            }

            [Fact]
            public async Task ReturnInRequestedOrder()
            {
                var f = new RequestedCasesFixture(Db)
                        .WithCase(out var case1, AccessPermissionLevel.Select)
                        .WithCase(out var case2, AccessPermissionLevel.Select)
                        .WithNotification(out var notification1)
                        .WithNotification(out var notification2)
                        .WithNotification(out var notification3)
                        .ReturnsSystemCodes("A")
                        .ReturnsMatchingCases(
                                              new Dictionary<int, int>
                                              {
                                                  {notification1.Case.Id, case1.Id},
                                                  {notification3.Case.Id, case2.Id},
                                                  {notification2.Case.Id, case1.Id}
                                              })
                        .Configure();

                var r = await f.Subject.LoadNotifications(new[] {case2.Id.ToString(), case1.Id.ToString()});

                Assert.Equal(r.ElementAt(0).Key.Id, notification3.Id);
                Assert.Equal(r.ElementAt(1).Key.Id, notification1.Id);
                Assert.Equal(r.ElementAt(2).Key.Id, notification2.Id);
            }

            [Fact]
            public async Task ReturnsAccessibleCasesOnly()
            {
                var f = new RequestedCasesFixture(Db)
                        .WithCase(out var hasAccess, AccessPermissionLevel.Select)
                        .WithCase(out _)
                        .ReturnsSystemCodes("A")
                        .ReturnsMatchingCases()
                        .Configure();

                await f.Subject.LoadNotifications(new[] {"1", "2"});

                f.MatchingCases.Received(1).Resolve(Arg.Any<string>(), hasAccess.Id);
            }
        }

        public class RequestedCasesFixture : IFixture<RequestedCases>
        {
            readonly Dictionary<InprotechCase, AccessPermissionLevel> _caseAccessibility;
            readonly InMemoryDbContext _db;

            public RequestedCasesFixture(InMemoryDbContext db)
            {
                _db = db;
                _caseAccessibility = new Dictionary<InprotechCase, AccessPermissionLevel>();

                ExternalSystems = Substitute.For<IExternalSystems>();

                CaseAuthorization = Substitute.For<ICaseAuthorization>();

                EthicalWall = Substitute.For<IEthicalWall>();

                MatchingCases = Substitute.For<IMatchingCases>();

                Subject = new RequestedCases(db, db, ExternalSystems,
                                             CaseAuthorization, EthicalWall, MatchingCases);
            }

            public IExternalSystems ExternalSystems { get; set; }

            public ICaseAuthorization CaseAuthorization { get; set; }

            public IEthicalWall EthicalWall { get; set; }

            public IMatchingCases MatchingCases { get; set; }

            public RequestedCases Subject { get; }

            public RequestedCasesFixture ReturnsSystemCodes(params string[] systemCodes)
            {
                ExternalSystems.DataSources().Returns(systemCodes);
                return this;
            }

            public RequestedCasesFixture WithCase(out InprotechCase @case, AccessPermissionLevel? level = null)
            {
                @case = new CaseBuilder().Build().In(_db);

                if (level.HasValue)
                {
                    _caseAccessibility[@case] = level.Value;
                }

                return this;
            }

            public RequestedCasesFixture WithNotification(out CaseNotification notification)
            {
                notification = new CaseNotification
                {
                    Case = new Case().In(_db)
                }.In(_db);
                return this;
            }

            public RequestedCasesFixture Configure()
            {
                EthicalWall.AllowedCases(Arg.Any<int[]>())
                           .Returns(x => ((int[]) x[0]).AsEnumerable());

                CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>())
                                 .Returns(
                                          _caseAccessibility.ToDictionary(
                                                                          k => k.Key.Id,
                                                                          v => v.Value
                                                                         )
                                         );
                return this;
            }

            public RequestedCasesFixture ReturnsMatchingCases(Dictionary<int, int> matchingCases = null)
            {
                MatchingCases.Resolve(Arg.Any<string>(), Arg.Any<int[]>()).Returns(
                                                                                   matchingCases ?? new Dictionary<int, int>());
                return this;
            }
        }
    }
}