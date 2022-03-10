using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseDetailsWithSecurityFacts
    {
        public class LoadCaseDetailsWithSecurityCheckMethod : FactBase
        {
            public LoadCaseDetailsWithSecurityCheckMethod()
            {
                _f = new CaseDetailsWithSecurityFixture(Db);
            }

            readonly CaseDetailsWithSecurityFixture _f;

            [Fact]
            public async Task SuppressCasesNotPermitted()
            {
                var n1 = new CaseNotificationBuilder(Db).Build();
                var n2 = new CaseNotificationBuilder(Db).Build();
                _f.CaseDetailsLoader
                  .LoadCasesForNotifications(Arg.Any<IEnumerable<CaseNotificationResponse>>())
                  .Returns(new Dictionary<int, CaseDetails>
                  {
                      {
                          n1.Id, new CaseDetails
                          {
                              CaseId = 888,
                              CaseRef = "Yes",
                              HasPermission = true
                          }
                      },
                      {
                          n2.Id, new CaseDetails
                          {
                              CaseId = 999,
                              CaseRef = "No",
                              HasPermission = false
                          }
                      }
                  });

                var query = new[] {n1, n2}.AsQueryable();

                var r = await _f.Subject.LoadCaseDetailsWithSecurityCheck(query);
                var n = r.ToArray();

                _f.NotificationResponse.Received(1).For(query);

                Assert.Contains(n, _ => _.CaseRef == "Yes");
                Assert.Contains(n, _ => _.CaseId == 888);
                Assert.DoesNotContain(n, _ => _.CaseRef == "No");
                Assert.DoesNotContain(n, _ => _.CaseId == 999);
                Assert.Single(n);
            }
        }
    }

    public class CaseDetailsWithSecurityFixture : IFixture<CaseDetailsWithSecurity>
    {
        public CaseDetailsWithSecurityFixture(InMemoryDbContext db)
        {
            NotificationResponse = Substitute.For<INotificationResponse>();
            NotificationResponse.For(Arg.Any<IEnumerable<CaseNotification>>())
                                .Returns(x =>
                                {
                                    return ((IEnumerable<CaseNotification>) x[0])
                                        .Select(_ => new CaseNotificationResponse(_, _.Body, _.Body));
                                });

            CaseDetailsLoader = Substitute.For<ICaseDetailsLoader>();

            CaseDetailsLoader.LoadCasesForNotifications(Arg.Any<IEnumerable<CaseNotificationResponse>>())
                             .Returns(x =>
                             {
                                 var p = (IEnumerable<CaseNotificationResponse>) x[0];
                                 if (p == null)
                                 {
                                     return new Dictionary<int, CaseDetails>();
                                 }

                                 var result = new Dictionary<int, CaseDetails>();

                                 foreach (var p1 in p)
                                 {
                                     if (!p1.CaseId.HasValue) continue;
                                     result[p1.NotificationId] = new CaseDetails
                                     {
                                         CaseId = p1.CaseId.GetValueOrDefault(),
                                         HasPermission = true
                                     };
                                 }

                                 return result;
                             });

            Subject = new CaseDetailsWithSecurity(CaseDetailsLoader, NotificationResponse);
        }

        public INotificationResponse NotificationResponse { get; set; }

        public ICaseDetailsLoader CaseDetailsLoader { get; set; }
        public CaseDetailsWithSecurity Subject { get; set; }
    }
}

