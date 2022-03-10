using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseNotificationsForExecutionsFacts
    {
        public class FetchMethod : FactBase
        {
            public FetchMethod()
            {
                _f = new CaseNotificationsForExecutionFixture(Db);
            }

            readonly CaseNotificationsForExecutionFixture _f;

            readonly ExecutionNotificationsOptions _options = new ExecutionNotificationsOptions
            {
                PageSize = 10,
                ScheduleExecutionId = 1
            };
            
            [Fact]
            public async Task ConsidersScheduleExecutionFilter()
            {
                _f.CasesIndexesSearchReturns(999);

                var n1 = new CaseNotificationBuilder(Db).Build();
                var n2 = new CaseNotificationBuilder(Db).Build();
                var n3 = new CaseNotificationBuilder(Db).Build();
                var executionId = Fixture.Integer();
                var execution2Id = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n2.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = execution2Id,
                    CaseId = n3.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(2, r.Results.Count());
                Assert.Equal(n1.Id, r.Results.First().NotificationId);
                Assert.Equal(n2.Id, r.Results.Last().NotificationId);
            }
            
            [Fact]
            public async Task ShouldThrowNullIfFilterOptionsNull()
            {
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await _f.Subject.Fetch(null); });
            }
            
            [Fact]
            public async Task ShouldThrowNullIfFilterScheduleExecutionIsNull()
            {
                var options = new ExecutionNotificationsOptions();
                options.ScheduleExecutionId = null;

                await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await _f.Subject.Fetch(options);
                });
            }

            [Fact]
            public async Task ConsidersOtherFilterOptionsWhenSearchingByText()
            {
                _f.CasesIndexesSearchReturns(999);

                var n1 = new CaseNotificationBuilder(Db).Build();
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                n1.Case.CorrelationId = 999;
                n1.IsReviewed = true;
                _options.ScheduleExecutionId = executionId;
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

                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;

                _f.CasesIndexesSearchReturns(888, 999, 1000); /* get cases from inprotech returns caseid 
                                                   * correlated with the same case notification */
                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task IndicateThereAreMoreNotificationsFollowingThisResultSet()
            {
                var n1 = new CaseNotificationBuilder(Db).Build();
                var n2 = new CaseNotificationBuilder(Db).Build();
                var n3 = new CaseNotificationBuilder(Db).Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n2.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n3.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;

                _options.PageSize = 2;

                var r = await _f.Subject.Fetch(_options);

                Assert.True(r.HasMore);
            }

            [Fact]
            public async Task IndicateThereAreNoMoreNotifications()
            {
                var n1 = new CaseNotificationBuilder(Db).Build();
                var n2 = new CaseNotificationBuilder(Db).Build();
                var n3 = new CaseNotificationBuilder(Db).Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n2.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n3.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;

                _options.PageSize = 3;

                var r = await _f.Subject.Fetch(_options);

                Assert.False(r.HasMore);
            }

            [Fact]
            public async Task ReturnsCasesMatchingSearchTextFromInprotech()
            {
                var n1 = new CaseNotificationBuilder(Db).Build();
                n1.Case.CorrelationId = 12345;
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;
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
                var n1 = new CaseNotificationBuilder(Db)
                {
                    ApplicationNumber = "12345"
                }.Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;
                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsCasesWithPublicationNumberMatchingSearchTextFromPto()
            {
                var n1 = new CaseNotificationBuilder(Db)
                {
                    PublicationNumber = "12345"
                }.Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;
                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsCasesWithRegistrationNumberMatchingSearchTextFromPto()
            {
                var n1 = new CaseNotificationBuilder(Db)
                {
                    RegistrationNumber = "12345"
                }.Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;
                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsCasesWithTitleMatchingSearchTextFromPto()
            {
                var n1 = new CaseNotificationBuilder(Db)
                {
                    Body = "12345"
                }.Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;
                _options.SearchText = "234";

                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsItemsUptoRequestedPageSize()
            {
                var n1 = new CaseNotificationBuilder(Db).Build();
                var n2 = new CaseNotificationBuilder(Db).Build();
                var n3 = new CaseNotificationBuilder(Db).Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n2.CaseId,
                }.In(Db);
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n3.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;
                _options.PageSize = 2;

                var r = await _f.Subject.Fetch(_options);

                Assert.Equal(2, r.Results.Count());
            }

            [Fact]
            public async Task ReturnsLatestNotifications()
            {
                var n1= new CaseNotificationBuilder(Db)
                {
                    UpdatedOn = Fixture.Today()
                }.Build();
                
                var executionId = Fixture.Integer();
                new ScheduleExecutionArtifact()
                {
                    ScheduleExecutionId = executionId,
                    CaseId = n1.CaseId,
                }.In(Db);
                _options.ScheduleExecutionId = executionId;
                var r = await _f.Subject.Fetch(_options);

                Assert.NotNull(r.Results.SingleOrDefault());
            }

            [Fact]
            public async Task ReturnsNotificationsMeetingFilterCriteria()
            {
                await _f.Subject.Fetch(_options);

                _f.CaseNotifications.Received(1).ThatSatisfies(_options);
            }

            public class CaseNotificationsForExecutionFixture : IFixture<CaseNotificationsForExecution>
            {
                public CaseNotificationsForExecutionFixture(InMemoryDbContext db)
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
                    Subject = new CaseNotificationsForExecution(CaseNotifications, CaseIndexesSearch, db, CaseDetailsWithSecurity);
                }

                public ICaseDetailsWithSecurity CaseDetailsWithSecurity { get; set; }

                public ICaseNotifications CaseNotifications { get; set; }

                public INotificationResponse NotificationResponse { get; set; }

                public ICaseIndexesSearch CaseIndexesSearch { get; set; }

                public CaseNotificationsForExecution Subject { get; set; }

                public void CasesIndexesSearchReturns(params int[] results)
                {
                    var r = results ?? Enumerable.Empty<int>();

                    CaseIndexesSearch.Search(Arg.Any<string>(), Arg.Any<CaseIndexSource[]>()).Returns(r);
                }
            }
        }
    }
}