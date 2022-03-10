using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseNotificationsLastChangedFacts
    {
        public class FetchMethod : FactBase
        {
            public FetchMethod()
            {
                _f = new CaseNotificationsLastChangedFixture(Db);
            }

            readonly CaseNotificationsLastChangedFixture _f;

            readonly LastChangedNotificationsOptions _options = new LastChangedNotificationsOptions
            {
                PageSize = 10
            };

            [Fact]
            public async Task ConsidersOtherFilterOptionsWhenSearchingByText()
            {
                _f.CasesIndexesSearchReturns(999);

                var n1 = new CaseNotificationBuilder(Db).Build();
                n1.Case.CorrelationId = 999;
                n1.IsReviewed = true;

                _options.IncludeReviewed = false;
                _options.SearchText = Fixture.String();

                var r = await _f.Subject.Fetch(_options);

                Assert.Empty(r.Results);
            }

            [Fact]
            public async Task DoesNotReturnDuplicateNotifications()
            {
                var n1 = new CaseNotificationBuilder(Db)
                {
                    ApplicationNumber = "12345" /* Pto case matched by app number */
                }.Build();
                n1.Case.CorrelationId = 999;

                _f.CasesIndexesSearchReturns(888, 999, 1000); /* get cases from inprotech returns caseid 
                                                   * correlated with the same case notification */
                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task IndicateThereAreMoreNotificationsFollowingThisResultSet()
            {
                new CaseNotificationBuilder(Db).Build();
                new CaseNotificationBuilder(Db).Build();
                new CaseNotificationBuilder(Db).Build();

                _options.PageSize = 2;

                var r = await _f.Subject.Fetch(_options);

                Assert.True(r.HasMore);
            }

            [Fact]
            public async Task IndicateThereAreNoMoreNotifications()
            {
                new CaseNotificationBuilder(Db).Build();
                new CaseNotificationBuilder(Db).Build();
                new CaseNotificationBuilder(Db).Build();

                _options.PageSize = 3;

                var r = await _f.Subject.Fetch(_options);

                Assert.False(r.HasMore);
            }

            [Fact]
            public async Task ReturnsCasesMatchingSearchTextFromInprotech()
            {
                var n1 = new CaseNotificationBuilder(Db).Build();
                n1.Case.CorrelationId = 12345;

                _options.SearchText = Fixture.String();

                _f.CasesIndexesSearchReturns(12345, 5678, 780);

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());

                _f.CaseIndexesSearch.Received(1)
                  .Search(_options.SearchText, CaseIndexSource.Irn, CaseIndexSource.Title, CaseIndexSource.OfficialNumbers);
            }

            [Fact]
            public async Task ReturnsCasesWithApplicationNumberMatchingSearchTextFromPto()
            {
                new CaseNotificationBuilder(Db)
                {
                    ApplicationNumber = "12345"
                }.Build();

                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsCasesWithPublicationNumberMatchingSearchTextFromPto()
            {
                new CaseNotificationBuilder(Db)
                {
                    PublicationNumber = "12345"
                }.Build();

                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsCasesWithRegistrationNumberMatchingSearchTextFromPto()
            {
                new CaseNotificationBuilder(Db)
                {
                    RegistrationNumber = "12345"
                }.Build();

                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsCasesWithTitleMatchingSearchTextFromPto()
            {
                new CaseNotificationBuilder(Db)
                {
                    Body = "12345"
                }.Build();

                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsFresherNotificationsFirst()
            {
                var n1 = new CaseNotificationBuilder(Db)
                {
                    UpdatedOn = Fixture.Date("2010-01-01")
                }.Build();

                var n2 = new CaseNotificationBuilder(Db)
                {
                    UpdatedOn = Fixture.Date("2010-01-03")
                }.Build();

                _options.Since = Fixture.Date("2010-01-05");

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(n2.Id, r.Results.First().NotificationId);
                Assert.Equal(n1.Id, r.Results.Last().NotificationId);
            }

            [Fact]
            public async Task ReturnsItemsUptoRequestedPageSize()
            {
                new CaseNotificationBuilder(Db).Build();
                new CaseNotificationBuilder(Db).Build();
                new CaseNotificationBuilder(Db).Build();

                _options.PageSize = 2;

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(2, r.Results.Count());
            }

            [Fact]
            public async Task ReturnsLatestNotifications()
            {
                new CaseNotificationBuilder(Db)
                {
                    UpdatedOn = Fixture.Today()
                }.Build();

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsNotificationsFromGivenDate()
            {
                new CaseNotificationBuilder(Db)
                {
                    UpdatedOn = Fixture.Date("2010-01-01")
                }.Build();

                new CaseNotificationBuilder(Db)
                {
                    UpdatedOn = Fixture.Date("2010-01-03")
                }.Build();

                _options.Since = Fixture.Date("2010-01-02");

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsNotificationsMeetingFilterCriteria()
            {
                await _f.Subject.Fetch(_options);

                _f.CaseNotifications.Received(1).ThatSatisfies(_options);
            }

            public class CaseNotificationsLastChangedFixture : IFixture<CaseNotificationsLastChanged>
            {
                public CaseNotificationsLastChangedFixture(InMemoryDbContext db)
                {
                    CaseNotifications = Substitute.For<ICaseNotifications>();
                    CaseNotifications
                        .ThatSatisfies(Arg.Any<LastChangedNotificationsOptions>())
                        .ReturnsForAnyArgs(x =>
                                           {
                                               var sp = (SearchParameters) x[0];
                                               return db.Set<CaseNotification>()
                                                        .IncludesErrors(sp.IncludeErrors)
                                                        .IncludesReviewed(sp.IncludeReviewed)
                                                        .IncludesRejected(sp.IncludeRejected)
                                                        .FiltersBy(sp.DataSourceTypesOrDefault());
                                           }
                                          );

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

                    CaseIndexesSearch = Substitute.For<ICaseIndexesSearch>();
                    CaseDetailsWithSecurity = Substitute.For<ICaseDetailsWithSecurity>();
                    CaseDetailsWithSecurity.LoadCaseDetailsWithSecurityCheck(Arg.Any<IQueryable<CaseNotification>>()).Returns(x =>
                    {
                        var notifications = (IQueryable<CaseNotification>) x[0];
                        return notifications.Select(_ => new CaseNotificationResponse()
                        {
                            Date = _.UpdatedOn,
                            NotificationId = _.Id
                        });
                    });
                    Subject = new CaseNotificationsLastChanged(CaseNotifications, CaseIndexesSearch, Fixture.FutureDate, CaseDetailsWithSecurity);
                }

                public ICaseDetailsWithSecurity CaseDetailsWithSecurity { get; set; }
                public ICaseNotifications CaseNotifications { get; set; }

                public INotificationResponse NotificationResponse { get; set; }

                public ICaseDetailsLoader CaseDetailsLoader { get; set; }

                public ICaseIndexesSearch CaseIndexesSearch { get; set; }

                public CaseNotificationsLastChanged Subject { get; set; }

                public void CasesIndexesSearchReturns(params int[] results)
                {
                    var r = results ?? Enumerable.Empty<int>();

                    CaseIndexesSearch.Search(Arg.Any<string>(), Arg.Any<CaseIndexSource[]>()).Returns(r);
                }
            }
        }
    }
}