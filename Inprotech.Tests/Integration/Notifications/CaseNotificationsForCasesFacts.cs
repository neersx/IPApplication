using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseNotificationsForCasesFacts
    {
        public class FetchMethod : FactBase
        {
            public FetchMethod()
            {
                _f = new CaseNotificationsForCasesFixture(Db);
            }

            readonly CaseNotificationsForCasesFixture _f;

            readonly SelectedCasesNotificationOptions _options = new SelectedCasesNotificationOptions
            {
                PageSize = 10
            };

            dynamic CreateCorrelatedPair()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var caseNotification = new CaseNotificationBuilder(Db).Build();
                caseNotification.Case.CorrelationId = @case.Id;

                return new
                {
                    InprotechCase = @case,
                    Notification = caseNotification
                };
            }

            static string From(params dynamic[] correlatedPairs)
            {
                return string.Join(",", correlatedPairs.Select(_ => _.InprotechCase.Id.ToString()));
            }

            [Fact]
            public async Task IndicateMoreMatchingCasesAvailable()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();
                var c3 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2, c3);
                _options.PageSize = 2;

                var r = await _f.Subject.Fetch(_options);

                Assert.True(r.HasMore);
            }

            [Fact]
            public async Task ResolvesCasesFromCaseListOrTempStorageParameter()
            {
                _options.Caselist = "123,456,789";

                await _f.Subject.Fetch(_options);

                _f.CaseIdsResolver.Received(1).Resolve(_options);
            }

            [Fact]
            public async Task ReturnsEligibleCasesInRequestedOrder()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();
                var c3 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2, c3);

                _f.RequestedCasesReturns(new Dictionary<CaseNotification, Case>
                {
                    {c1.Notification, c1.InprotechCase},
                    {c3.Notification, c3.InprotechCase}
                });

                var r = await _f.Subject.Fetch(_options);
                var n = r.Result.ToArray();

                Assert.Equal(c1.InprotechCase.Id, n[0].CaseId);
                Assert.Equal(c3.InprotechCase.Id, n[1].CaseId);
            }

            [Fact]
            public async Task ReturnsEligibleCasesOnly()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2);

                _f.RequestedCasesReturns(new Dictionary<CaseNotification, Case>
                {
                    {c2.Notification, c2.InprotechCase}
                });

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(c2.InprotechCase.Id, r.Result.Single().CaseId);
            }

            [Fact]
            public async Task ReturnsErrorItems()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                _options.IncludeErrors = true;
                _options.Caselist = From(c1, c2);

                c1.Notification.Type = CaseNotificateType.Error;

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(2, r.Result.Count());
            }

            [Fact]
            public async Task ReturnsItemsUptoRequestedPageSize()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();
                var c3 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2, c3);
                _options.PageSize = 2;

                var r = await _f.Subject.Fetch(_options);
                var n = r.Result.ToArray();

                Assert.Equal(2, n.Length);
                Assert.DoesNotContain(n, _ => _.CaseId == c3.InprotechCase.Id);
            }

            [Fact]
            public async Task ReturnsNotificationsFromCorrelatedPtoCase()
            {
                _options.Caselist = From(CreateCorrelatedPair());

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Result.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsNotificationsMatchingSearchText()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                _options.SearchText = "hello";
                _options.Caselist = From(c1, c2);

                _f.CasesIndexesSearchReturns(c1.InprotechCase.Id); /* search results return matches from inprotech */

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(c1.InprotechCase.Id, r.Result.Single().CaseId);
            }

            [Fact]
            public async Task ReturnsNotificationsWherePtoCaseApplicationNumberContainsSearchText()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                c1.Notification.Case.ApplicationNumber = "1111345679999";

                _options.SearchText = "456";
                _options.Caselist = From(c1, c2);

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(c1.InprotechCase.Id, r.Result.Single().CaseId);
            }

            [Fact]
            public async Task ReturnsNotificationsWherePtoCasePublicationNumberContainsSearchText()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                c1.Notification.Case.PublicationNumber = "1111345679999";

                _options.SearchText = "456";
                _options.Caselist = From(c1, c2);

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(c1.InprotechCase.Id, r.Result.Single().CaseId);
            }

            [Fact]
            public async Task ReturnsNotificationsWherePtoCaseRegistrationNumberContainsSearchText()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                c1.Notification.Case.RegistrationNumber = "1111345679999";

                _options.SearchText = "456";
                _options.Caselist = From(c1, c2);

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(c1.InprotechCase.Id, r.Result.Single().CaseId);
            }

            [Fact]
            public async Task ReturnsNotificationsWherePtoCaseTitleContainsSearchText()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                c1.Notification.Body = "big brown fox says hello to ya'all";

                _options.SearchText = "hello";
                _options.Caselist = From(c1, c2);

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(c1.InprotechCase.Id, r.Result.Single().CaseId);
            }

            [Fact]
            public async Task ReturnsReviewedItems()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();
                var c3 = CreateCorrelatedPair();

                _options.IncludeReviewed = true;
                _options.Caselist = From(c1, c2, c3);

                c1.Notification.IsReviewed = true;

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(3, r.Result.Count());
            }

            [Fact]
            public async Task ReturnsSubsequentPagesInResultSet()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();
                var c3 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2, c3);
                _options.PageSize = 2;
                _options.Since = c1.InprotechCase.Id;

                var r = await _f.Subject.Fetch(_options);
                var n = r.Result.ToArray();

                Assert.Equal(2, n.Length);
                Assert.DoesNotContain(n, _ => _.CaseId == c1.InprotechCase.Id);
            }

            [Fact]
            public async Task ReturnsUnreviewedItems()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2);

                c1.Notification.IsReviewed = true;

                var r = await _f.Subject.Fetch(_options);
                var n = r.Result.ToArray();

                Assert.Equal(c2.InprotechCase.Id, n[0].CaseId);
                Assert.Single(n);
            }

            [Fact]
            public async Task SuppressesErrorNotifications()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2);

                c1.Notification.Type = CaseNotificateType.Error;

                var r = await _f.Subject.Fetch(_options);
                var n = r.Result.ToArray();

                Assert.Equal(c2.InprotechCase.Id, n[0].CaseId);
                Assert.Single(n);
            }

            [Fact]
            public async Task SuppressesRejectedItems()
            {
                var c1 = CreateCorrelatedPair();
                var c2 = CreateCorrelatedPair();

                _options.Caselist = From(c1, c2);

                c1.Notification.Type = CaseNotificateType.Rejected;

                var r = await _f.Subject.Fetch(_options);
                var n = r.Result.ToArray();

                Assert.Equal(c2.InprotechCase.Id, n[0].CaseId);
                Assert.Single(n);
            }
        }

        public class CaseNotificationsForCasesFixture : IFixture<CaseNotificationsForCases>
        {
            public CaseNotificationsForCasesFixture(InMemoryDbContext db)
            {
                CaseIdsResolver = Substitute.For<ICaseIdsResolver>();
                CaseIdsResolver.Resolve(Arg.Any<SelectedCasesNotificationOptions>())
                               .Returns(x =>
                               {
                                   var o = (SelectedCasesNotificationOptions) x[0];
                                   return (o.Caselist ?? string.Empty).Split(new[] {","}, StringSplitOptions.RemoveEmptyEntries)
                                                            .ToArray();
                               });

                RequestedCases = Substitute.For<IRequestedCases>();
                RequestedCases.LoadNotifications(Arg.Any<string[]>())
                              .Returns(x =>
                              {
                                  var notifications = db.Set<CaseNotification>();
                                  var cases = db.Set<Case>();

                                  if (!notifications.Any() || !cases.Any() || x[0] == null)
                                  {
                                      return new Dictionary<CaseNotification, Case>();
                                  }

                                  return ((string[]) x[0])
                                      .ToDictionary(
                                                    k => notifications.Single(_ => _.Case.CorrelationId == int.Parse(k)),
                                                    v => cases.Single(_ => _.Id == int.Parse(v))
                                                   );
                              });

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

                CaseIndexesSearch = Substitute.For<ICaseIndexesSearch>();

                Subject = new CaseNotificationsForCases(CaseIdsResolver, RequestedCases, CaseNotifications, NotificationResponse, CaseIndexesSearch);
            }

            public ICaseIdsResolver CaseIdsResolver { get; set; }

            public IRequestedCases RequestedCases { get; set; }

            public ICaseNotifications CaseNotifications { get; set; }

            public INotificationResponse NotificationResponse { get; set; }

            public ICaseIndexesSearch CaseIndexesSearch { get; set; }

            public CaseNotificationsForCases Subject { get; set; }

            public void CasesIndexesSearchReturns(params int[] results)
            {
                var r = results ?? Enumerable.Empty<int>();

                CaseIndexesSearch.Search(Arg.Any<string>(), Arg.Any<CaseIndexSource[]>()).Returns(r);
            }

            public void CaseIdsReturns(params string[] ids)
            {
                CaseIdsResolver.Resolve(Arg.Any<SelectedCasesNotificationOptions>())
                               .Returns(ids ?? Enumerable.Empty<string>());
            }

            public void RequestedCasesReturns(Dictionary<CaseNotification, Case> result)
            {
                RequestedCases.LoadNotifications(null)
                              .ReturnsForAnyArgs(result);
            }
        }
    }
}