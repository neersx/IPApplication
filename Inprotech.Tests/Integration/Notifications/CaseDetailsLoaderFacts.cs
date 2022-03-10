using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseDetailsLoaderFacts
    {
        public class LoadCasesForNotificationsFacts : FactBase
        {
            [Fact]
            public async Task ShouldNotReturnCasesPreventedByEthicalWall()
            {
                var f = new CaseDetailsLoaderFixture(Db);

                var case1 = new CaseBuilder().Build().In(Db);

                var case2 = new CaseBuilder().Build().In(Db);

                f.EthicalWall.AllowedCases(Arg.Any<int[]>())
                 .Returns(new[] {case2.Id});

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<int[]>())
                 .Returns(x => ((int[]) x[0]).ToDictionary(k => k, v => AccessPermissionLevel.Select));

                var result = await f.Subject.LoadCasesForNotifications(new[]
                {
                    new CaseNotificationResponse
                    {
                        NotificationId = 1,
                        CaseId = case1.Id
                    },
                    new CaseNotificationResponse
                    {
                        NotificationId = 2,
                        CaseId = case2.Id
                    }
                });

                Assert.False(result[1].HasPermission);
                Assert.True(result[2].HasPermission);

                Assert.Equal(case1.Id, result[1].CaseId);
                Assert.Equal(case2.Id, result[2].CaseId);
            }

            [Fact]
            public async Task ShouldReturnsCasesWithPermissions()
            {
                var f = new CaseDetailsLoaderFixture(Db);

                var case1 = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().Build().In(Db);

                f.EthicalWall.AllowedCases(Arg.Any<int[]>())
                 .Returns(x => x[0]); /* all cases */

                f.CaseAuthorization.GetInternalUserAccessPermissions(null).ReturnsForAnyArgs(
                                                                                             new Dictionary<int, AccessPermissionLevel>
                                                                                             {
                                                                                                 {
                                                                                                     case1.Id,
                                                                                                     AccessPermissionLevel.Select
                                                                                                 }
                                                                                             });

                var result = await f.Subject.LoadCasesForNotifications(new[]
                {
                    new CaseNotificationResponse
                    {
                        NotificationId = 1,
                        CaseId = case1.Id
                    },
                    new CaseNotificationResponse
                    {
                        NotificationId = 2,
                        CaseId = case2.Id
                    }
                });

                Assert.True(result[1].HasPermission);
                Assert.False(result[2].HasPermission);

                Assert.Equal(case1.Id, result[1].CaseId);
                Assert.Equal(case2.Id, result[2].CaseId);
            }

            [Fact]
            public async Task ShouldReturnsEmptyDictionaryWhenNoMatches()
            {
                var f = new CaseDetailsLoaderFixture(Db);
                var result = await f.Subject.LoadCasesForNotifications(new[] {new CaseNotificationResponse()});
                Assert.Empty(result);
            }
        }

        public class CaseDetailsLoaderFixture : IFixture<CaseDetailsLoader>
        {
            public CaseDetailsLoaderFixture(InMemoryDbContext db)
            {
                EthicalWall = Substitute.For<IEthicalWall>();

                CaseAuthorization = Substitute.For<ICaseAuthorization>();

                Subject = new CaseDetailsLoader(db, EthicalWall, CaseAuthorization);
            }

            public IEthicalWall EthicalWall { get; set; }

            public ICaseAuthorization CaseAuthorization { get; set; }

            public CaseDetailsLoader Subject { get; }
        }
    }
}