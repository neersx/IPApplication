using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Storage;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Analytics;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.TaskPlanner;
using Inprotech.Web.Dates;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.TaskPlanner;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.TaskPlanner;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner
{
    public class TaskPlannerControllerFacts : FactBase
    {
        string PrepareFilterCriteria()
        {
            const string filterCriteria = @" <Search>
                                                <Filtering>
                                                    <ipw_TaskPlanner>
                                                        <FilterCriteria>
                                                            <Include>
                                                                <IsReminders>1</IsReminders>
                                                                <IsDueDates>1</IsDueDates>
                                                                <IsAdHocDates>1</IsAdHocDates>
                                                            </Include>
                                                            <BelongsTo>
                                                                <NameKey  Operator='0' IsCurrentUser='1' />
                                                                <ActingAs  IsReminderRecipient='1' IsResponsibleStaff='1'>
                                                                    <NameTypeKey>SIG</NameTypeKey>
                                                                    <NameTypeKey>EMP</NameTypeKey>
                                                                </ActingAs>
                                                            </BelongsTo>
                                                            <Dates  UseDueDate='1' UseReminderDate='1'>
                                                                <PeriodRange  Operator='7'>
                                                                    <Type>W</Type>
                                                                    <From>-4</From>
                                                                    <To>2</To>
                                                                </PeriodRange>
                                                            </Dates>
                                                        </FilterCriteria>
                                                    </ipw_TaskPlanner>
                                                </Filtering>
                                                </Search>";
            return filterCriteria;
        }

        static dynamic SetupTaskPlannerTabData(InMemoryDbContext db)
        {
            var contextId = QueryContext.TaskPlanner;
            var presentationId = 35;

            var query1 = new Query { ContextId = (int)contextId, Id = Fixture.Integer(), PresentationId = presentationId, Name = Fixture.String() }.In(db);
            var query2 = new Query { ContextId = (int)contextId, Id = Fixture.Integer(), PresentationId = presentationId, Name = Fixture.String() }.In(db);
            var query3 = new Query { ContextId = (int)contextId, Id = Fixture.Integer(), PresentationId = presentationId, Name = Fixture.String() }.In(db);

            var taskPlannerTab1 = new TaskPlannerTab { QueryId = query1.Id, IdentityId = null, TabSequence = 1 }.In(db);
            var taskPlannerTab2 = new TaskPlannerTab { QueryId = query2.Id, IdentityId = null, TabSequence = 2 }.In(db);

            new TaskPlannerTabsByProfile { QueryId = query3.Id, TabSequence = 1 }.In(db);
            new TaskPlannerTabsByProfile { QueryId = query2.Id, TabSequence = 2 }.In(db);
            new TaskPlannerTabsByProfile { QueryId = query1.Id, TabSequence = 3 }.In(db);

            var user = new User("john", false).In(db);
            var taskPlannerTab3 = new TaskPlannerTab { QueryId = query3.Id, IdentityId = user.Id, TabSequence = 3 }.In(db);

            return new { user, taskPlannerTab1, taskPlannerTab2, taskPlannerTab3, query1, query2, query3 };
        }

        [Fact]
        public async Task ShouldCallGetFilterDataForColumnMethod()
        {
            var fixture = new TaskPlannerControllerFixture();
            var filter = new ColumnFilterParams<TaskPlannerRequestFilter> { QueryContext = QueryContext.TaskPlanner, QueryKey = Fixture.Integer() };
            var result = new List<CodeDescription>();
            fixture.SearchService.GetFilterDataForColumn(filter)
                   .Returns(result);
            var r = await fixture.Subject.GetFilterDataForColumn(filter);
            Assert.Equal(result, r);
            fixture.SearchService.Received(1).GetFilterDataForColumn(filter)
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ShouldCallGetSavedSearchQueryMethod()
        {
            var queryKey = Fixture.Integer();
            var queryContext = QueryContext.TaskPlanner;
            var f = new TaskPlannerControllerFixture(Db);
            var now = DateTime.Today;
            var presentationId = Fixture.Integer();
            var queryName = Fixture.String();
            var nameNo = Fixture.Integer();
            var nameCode = Fixture.String();
            f.Now().Returns(now);
            f.PreferredCultureResolver.Resolve().Returns("en-GB");
            f.SecurityContext.User.Returns(new User("internal", false) { Name = new InprotechKaizen.Model.Names.Name(nameNo) { NameCode = nameCode } });
            var queryFiler = Db.Set<QueryFilter>().Add(new QueryFilter { Id = queryKey, ProcedureName = "ipw_TaskPlanner", XmlFilterCriteria = PrepareFilterCriteria() }).In(Db);
            Db.Set<Query>().Add(new Query { Name = queryName, ContextId = (int)queryContext, IdentityId = null, Id = queryKey, FilterId = queryFiler.Id, PresentationId = presentationId }).In(Db);

            var request = new TaskPlannerViewDataRequest { QueryKey = queryKey, QueryContext = queryContext };
            var r = f.Subject.GetSavedSearchQuery(request);
            Assert.Equal(queryKey, r.Query.Key);
            Assert.Equal(presentationId, r.Query.PresentationId);
            Assert.Equal(queryName, r.Query.SearchName);
            Assert.Equal("7", r.Criteria.DateFilter.Operator);
            Assert.Equal(now.AddDays(-4 * 7), r.Criteria.DateFilter.From);
            Assert.Equal(now.AddDays(2 * 7), r.Criteria.DateFilter.To);
        }

        [Fact]
        public async Task ShouldCallGetSearchColumnsMethod()
        {
            var filter = new ColumnRequestParams
            {
                QueryContext = QueryContext.TaskPlanner,
                PresentationType = Fixture.String(),
                QueryKey = Fixture.Integer(),
                SelectedColumns = new[]
                {
                    new SelectedColumn(),
                    new SelectedColumn()
                }
            };

            var fixture = new TaskPlannerControllerFixture();

            var searchColumns = new[]
            {
                new SearchResult.Column(),
                new SearchResult.Column()
            };

            fixture.SearchService
                   .GetSearchColumns(filter.QueryContext, filter.QueryKey, filter.SelectedColumns, filter.PresentationType)
                   .Returns(searchColumns);

            var r = await fixture.Subject.SearchColumns(filter);

            Assert.Equal(searchColumns, r);

            fixture.SearchService
                   .Received(1)
                   .GetSearchColumns(filter.QueryContext, filter.QueryKey, filter.SelectedColumns, filter.PresentationType)
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldCallGetViewDataMethodWithFilterCriteria()
        {
            var queryContext = QueryContext.TaskPlanner;
            var f = new TaskPlannerControllerFixture(Db)
                .WithTasks(ApplicationTask.AnnotateDueDates);

            var now = DateTime.Today;
            var nameNo = Fixture.Integer();
            var nameCode = Fixture.String();
            f.Now().Returns(now);
            var user = new User("internal", false) { Name = new InprotechKaizen.Model.Names.Name(nameNo) { NameCode = nameCode } }.WithKnownId(45);
            f.SecurityContext.User.Returns(user);
            var fromDate = DateTime.Today;
            var toDate = DateTime.Today.AddDays(3);

            var request = new TaskPlannerViewDataRequest { QueryContext = queryContext };
            request.FilterCriteria = new TaskPlannerRequestFilter
            {
                SearchRequest = new TaskPlannerRequest
                {
                    Dates = new InprotechKaizen.Model.Components.Cases.Search.Dates
                    {
                        SinceLastWorkingDay = 0,
                        DateRange = new DateRange { From = fromDate, To = toDate, Operator = "7" },
                        UseDueDate = 1,
                        UseReminderDate = 0
                    },
                    BelongsTo = new BelongsTo
                    {
                        NameKey = new NameKeyElement { IsCurrentUser = 1, Operator = 0 },
                        ActingAs = new ActingAs { IsReminderRecipient = 1, IsResponsibleStaff = 1 }
                    },
                    Include = new Include { IsReminders = 1, IsDueDates = 0, IsAdHocDates = 0 }
                }
            };
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.ChangeDueDateResponsibility, ApplicationTaskAccessLevel.Execute).Returns(true);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.ProvideDueDateInstructions, ApplicationTaskAccessLevel.Execute).Returns(true);
            var r = await f.Subject.Get(request);
            Assert.Equal(8, r.TimePeriods.Count);
            Assert.Equal(1, r.Criteria.BelongsTo.Names.Count);
            Assert.Equal(user.Name.NameCode, r.Criteria.BelongsTo.Names[0].Code);
            Assert.Equal(1, r.Criteria.DateFilter.UseDueDate);
            Assert.Equal(0, r.Criteria.DateFilter.UseReminderDate);
            Assert.Equal(0, r.Criteria.DateFilter.SinceLastWorkingDay);
            Assert.Equal(fromDate, r.Criteria.DateFilter.From);
            Assert.Equal(toDate, r.Criteria.DateFilter.To);
            Assert.True(r.MaintainEventNotes);
            Assert.False(r.CanCreateAdhocDate);
            Assert.True(r.CanChangeDueDateResponsibility);
            Assert.True(r.ProvideDueDateInstructions);

            f.Bus.Received(1)
             .PublishAsync(Arg.Is<TransactionalAnalyticsMessage>(i => i.EventType == TransactionalEventTypes.TaskPlannerAccessed && i.Value == f.ContentHasher.ComputeHash(user.Id.ToString())))
             .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldCallGetViewDataMethodWithSavedSearch()
        {
            var queryContext = QueryContext.TaskPlanner;
            var f = new TaskPlannerControllerFixture(Db);
            var now = DateTime.Today;
            var nameNo = Fixture.Integer();
            var nameCode = Fixture.String();
            f.Now().Returns(now);
            f.SecurityContext.User.Returns(new User("internal", false) { Name = new InprotechKaizen.Model.Names.Name(nameNo) { NameCode = nameCode } });
            f.SiteControlReader.Read<bool>(SiteControls.ReminderCommentsEnabledInTaskPlanner).Returns(true);
            var request = new TaskPlannerViewDataRequest { QueryContext = queryContext };
            var r = await f.Subject.Get(request);
            Assert.Equal(8, r.TimePeriods.Count);
            Assert.False(r.isExternal);
            Assert.True(r.ShowReminderComments);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldReturnAttachmentPermissions(bool hasPermission)
        {
            var queryContext = QueryContext.TaskPlanner;
            var f = new TaskPlannerControllerFixture(Db);
            var now = DateTime.Today;
            var nameNo = Fixture.Integer();
            var nameCode = Fixture.String();
            f.Now().Returns(now);
            f.SecurityContext.User.Returns(new User("internal", false) { Name = new InprotechKaizen.Model.Names.Name(nameNo) { NameCode = nameCode } });
            if (hasPermission)
            {
                f.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(true);
                f.WithTasksFullPermissions(ApplicationTask.MaintainCaseAttachments);
            }

            var request = new TaskPlannerViewDataRequest { QueryContext = queryContext };
            var r = await f.Subject.Get(request);
            Assert.Equal(hasPermission, r.CanViewAttachments);
            Assert.Equal(hasPermission, r.CanAddCaseAttachments);
        }

        [Fact]
        public void ShouldCallReminderComments()
        {
            var fixture = new TaskPlannerControllerFixture();
            fixture.ReminderComments.Get("C^551^-164^1^3").Returns(new ReminderCommentsPayload
            {
                Comments = new List<ReminderComments>
                {
                    new()
                }
            });

            var result = fixture.Subject.ReminderComments("C^551^-164^1^3");
            Assert.Equal(result.Comments.Count(), 1);
        }

        [Fact]
        public void ShouldCallRemindersCount()
        {
            var fixture = new TaskPlannerControllerFixture();
            var count = Fixture.Integer();
            fixture.ReminderComments.Count("C^551^-164^1^3").Returns(count);

            var result = fixture.Subject.ReminderCommentsCount("C^551^-164^1^3");
            Assert.Equal(count, result);
        }

        [Fact]
        public async Task ShouldCallRunSavedSearchMethod()
        {
            var filter = new SavedSearchRequestParams<TaskPlannerRequestFilter> { QueryContext = QueryContext.TaskPlanner, QueryKey = -27 };
            var fixture = new TaskPlannerControllerFixture();

            var savedSearchResult = new SearchResult();

            fixture.SearchService.RunSavedSearch(filter)
                   .Returns(savedSearchResult);

            var r = await fixture.Subject.RunSavedSearch(filter);

            Assert.Equal(savedSearchResult, r);

            fixture.SearchService.Received(1).RunSavedSearch(filter)
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ShouldCallUpdate()
        {
            var fixture = new TaskPlannerControllerFixture();
            var updateResult = new
            {
                Result = "success"
            };
            fixture.ReminderComments
                   .Update(Arg.Any<ReminderCommentsSaveDetails>()).Returns(updateResult);

            var result = fixture.Subject.SaveReminderComments(Arg.Any<ReminderCommentsSaveDetails>());
            Assert.Equal(updateResult, result);
        }

        [Fact]
        public async Task ShouldReturnBadRequestException()
        {
            var queryContext = QueryContext.CaseSearch;
            var f = new TaskPlannerControllerFixture(Db);

            var request = new TaskPlannerViewDataRequest { QueryContext = queryContext };

            var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                            async () => await f.Subject.GetTaskPlannerTabs(request));

            Assert.IsType<HttpResponseException>(exception);
            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldReturnMatchedIdentityTaskPlannerTabs()
        {
            var data = SetupTaskPlannerTabData(Db);
            var queryContext = QueryContext.TaskPlanner;
            var f = new TaskPlannerControllerFixture(Db);
            f.SecurityContext.User.Returns((User)data.user);
            f.TaskPlannerTabResolver.ResolveUserConfiguration().Returns(Task.FromResult(new[] { new TabData(), new TabData(), new TabData() }));

            var request = new TaskPlannerViewDataRequest { QueryContext = queryContext };
            var r = await f.Subject.GetTaskPlannerTabs(request);
            Assert.Equal(3, ((Array)r).Length);
        }

        [Fact]
        public async Task ShouldReturnNullException()
        {
            var f = new TaskPlannerControllerFixture(Db);
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.GetTaskPlannerTabs(null));
        }

        [Fact]
        public void ShouldSearchBuilderViewDataMethod()
        {
            var f = new TaskPlannerControllerFixture(Db);
            var importanceLevels = new[] { "Normal", "Importance" }.Select(x => new KeyValuePair<string, string>(x, x));
            f.CaseSearchService.GetImportanceLevels().Returns(importanceLevels);
            var numberType1 = new NumberTypeBuilder { IssuedByIpOffice = true }.Build().In(Db);
            var numberType2 = new NumberTypeBuilder { IssuedByIpOffice = true }.Build().In(Db);
            var nameType1 = new NameTypeBuilder().Build().In(Db);
            var nameType2 = new NameTypeBuilder().Build().In(Db);
            f.UserFilteredTypes.NameTypes().Returns(new[] { nameType1, nameType2 }.AsQueryable());
            f.UserFilteredTypes.NumberTypes().Returns(new[] { numberType1, numberType2 }.AsQueryable());
            f.SiteControlReader.Read<bool>(SiteControls.DisplayCeasedNames).Returns(true);
            f.SecurityContext.User.Returns(new User("int\\user", false));

            var r = f.Subject.SearchBuilderViewData();
            Assert.Equal(importanceLevels, r.ImportanceLevels);
            Assert.True(r.ShowEventNoteType);
            Assert.NotNull(r.NumberTypes);
            Assert.NotNull(r.NameTypes);
            Assert.True(r.ShowCeasedNames);
        }

        [Fact]
        public async Task ShouldThrowArgumentNullExceptionGetFilterDataForColumnMethod()
        {
            var fixture = new TaskPlannerControllerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetFilterDataForColumn(null); });
        }

        [Fact]
        public async Task ShouldThrowArgumentNullExceptionRunSavedSearchMethod()
        {
            var fixture = new TaskPlannerControllerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.RunSavedSearch(null); });
        }

        [Fact]
        public async Task ShouldThrowArgumentNullExceptionSearchColumnsMethod()
        {
            var fixture = new TaskPlannerControllerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.SearchColumns(null); });
        }

        [Fact]
        public async Task ShouldThrowHttpResponseExceptionGetFilterDataForColumnMethod()
        {
            var fixture = new TaskPlannerControllerFixture();
            var filter = new ColumnFilterParams<TaskPlannerRequestFilter> { QueryContext = QueryContext.CaseSearch, QueryKey = Fixture.Integer() };
            await Assert.ThrowsAsync<HttpResponseException>(async () => { await fixture.Subject.GetFilterDataForColumn(filter); });
        }

        [Fact]
        public async Task ShouldCallExportMethodPassingSearchExportParameter()
        {
            var filter = new SearchExportParams<TaskPlannerRequestFilter> { QueryContext = QueryContext.TaskPlanner };
            var fixture = new TaskPlannerControllerFixture();

            await fixture.Subject.Export(filter);

            fixture.SearchExportService.Received(1).Export(filter)
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldCallExportMethodPassingDeselectedIds()
        {
            var fixture = new TaskPlannerControllerFixture();
            var deselectedIds = new[] { 1, 5, 6 };
            var filter = new SearchExportParams<TaskPlannerRequestFilter> { QueryContext = QueryContext.TaskPlanner, DeselectedIds = deselectedIds, Criteria = new TaskPlannerRequestFilter() };

            await fixture.Subject.Export(filter);

            var rowKeysFilter = filter.Criteria.SearchRequest.RowKeys;
            Assert.Equal(string.Join(",", deselectedIds), rowKeysFilter.Value);
            Assert.Equal((short)CollectionExtensions.FilterOperator.NotIn, rowKeysFilter.Operator);
            fixture.SearchExportService.Received(1).Export(filter)
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldThrowBadRequestExceptionIfQueryContextNotProvided()
        {
            var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                            async () =>
                                                                            {
                                                                                var fixture = new TaskPlannerControllerFixture();
                                                                                await fixture.Subject.Export(new SearchExportParams<TaskPlannerRequestFilter>());
                                                                            });

            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldCallDeferReminders()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var request = new DeferReminderRequest { TaskPlannerRowKeys = new[] { $"A^123^{fixture.Now().ToString(CultureInfo.CurrentCulture)}^12^323^78", "C^567^90^14^125^77" } };
            fixture.ReminderManager.Defer(request).Returns(new ReminderResult { Status = ReminderActionStatus.Success, UnprocessedRowKeys = new List<string>() });
            var result = await fixture.Subject.DeferReminders(request);
            Assert.Equal(0, result.UnprocessedRowKeys.Count);
            Assert.Equal(ReminderActionStatus.Success, result.Status);
        }

        [Fact]
        public async Task ShouldCallMarkReminderAsReadUnread()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var taskPlannerRowKeys = new[] { $"A^123^{fixture.Now().ToString(CultureInfo.CurrentCulture)}^12^323^99", "C^567^90^14^125^89" };
            var req = new ReminderReadUnReadRequest { TaskPlannerRowKeys = taskPlannerRowKeys, IsRead = true };
            fixture.ReminderManager.MarkAsReadOrUnread(req).Returns(req.TaskPlannerRowKeys.Length);
            fixture.TaskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(req).Returns(taskPlannerRowKeys);
            var result = await fixture.Subject.MarkReminderAsReadUnread(req);
            Assert.Equal(req.TaskPlannerRowKeys.Length, result);
        }

        [Fact]
        public async Task ShouldCallChangeDueDateResponsibility()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var req = new DueDateResponsibilityRequest { TaskPlannerRowKeys = new[] { "C^123^66^12^323", "C^567^44^14^125" }, ToNameId = 11 };
            fixture.ReminderManager.ChangeDueDateResponsibility(req).Returns(new ReminderResult { Status = ReminderActionStatus.Success, UnprocessedRowKeys = new List<string>() });
            var result = await fixture.Subject.ChangeDueDateResponsibility(req);
            Assert.Equal(0, result.UnprocessedRowKeys.Count);
            Assert.Equal(ReminderActionStatus.Success, result.Status);
        }

        [Fact]
        public async Task ShouldCallForwardReminders()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var req = new ForwardReminderRequest { TaskPlannerRowKeys = new[] { "C^123^66", "C^567^44" }, ToNameIds = new[] { 11 } };
            fixture.ReminderManager.ForwardReminders(req).Returns(new ReminderResult { Status = ReminderActionStatus.Success, UnprocessedRowKeys = new List<string>() });
            var result = await fixture.Subject.ForwardReminders(req);
            Assert.Equal(0, result.UnprocessedRowKeys.Count);
            Assert.Equal(ReminderActionStatus.Success, result.Status);
        }

        [Fact]
        public async Task VerifyGetUserPreferenceViewData()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var user = new User("internal", false)
            {
                Name = new InprotechKaizen.Model.Names.Name(Fixture.Integer())
                {
                    NameCode = Fixture.UniqueName()
                }
            };
            fixture.SecurityContext.User.Returns(user);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch).Returns(true);
            fixture.UserPreferenceManager.GetPreference<bool>(Arg.Any<int>(), Arg.Any<int>()).Returns(true);
            var result = await fixture.Subject.GetUserPreferenceViewData();
            Assert.True(result.MaintainTaskPlannerSearch);
            Assert.True(result.PreferenceData.AutoRefreshGrid);
        }

        [Fact]
        public async Task VerifySetUserPreference()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var user = new User("internal", false)
            {
                Name = new InprotechKaizen.Model.Names.Name(Fixture.Integer())
                {
                    NameCode = Fixture.UniqueName()
                }
            };
            fixture.SecurityContext.User.Returns(user);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch).Returns(true);

            var q1 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(Db);
            var q2 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(Db);
            var q3 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(Db);
            var request = new TaskPlannerPreferenceModel
            {
                AutoRefreshGrid = true,
                Tabs = new[]
                {
                    new TabData { TabSequence = 1, SavedSearch = new QueryData { Key = q1.Id } },
                    new TabData { TabSequence = 2, SavedSearch = new QueryData { Key = q2.Id } },
                    new TabData { TabSequence = 3, SavedSearch = new QueryData { Key = q3.Id } }
                }
            };
            await fixture.Subject.SetUserPreference(request);
            fixture.UserPreferenceManager.Received(1).SetPreference(user.Id, KnownSettingIds.AutomaticallyRefreshTaskPlannerResults, true);

            var tabs = fixture.DbContext.Set<TaskPlannerTab>()
                              .Where(x => x.IdentityId == user.Id)
                              .OrderBy(x => x.TabSequence).ToArray();
            Assert.Equal(q1.Id, tabs[0].QueryId);
            Assert.Equal(q2.Id, tabs[1].QueryId);
            Assert.Equal(q3.Id, tabs[2].QueryId);
        }

        [Fact]
        public async Task ShouldNotSaveTaskPlannerUserPreference()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var user = new User("internal", false)
            {
                Name = new InprotechKaizen.Model.Names.Name(Fixture.Integer())
                {
                    NameCode = Fixture.UniqueName()
                }
            };
            fixture.SecurityContext.User.Returns(user);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTaskPlannerSearch).Returns(false);

            var q1 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(Db);
            var request = new TaskPlannerPreferenceModel
            {
                AutoRefreshGrid = true,
                Tabs = new[]
                {
                    new TabData
                    {
                        TabSequence = 1,
                        SavedSearch = new QueryData
                        {
                            Key = q1.Id
                        }
                    },
                    new TabData
                    {
                        TabSequence = 2,
                        SavedSearch = new QueryData
                        {
                            Key = q1.Id
                        }
                    },
                    new TabData
                    {
                        TabSequence = 3,
                        SavedSearch = new QueryData
                        {
                            Key = q1.Id
                        }
                    }
                }
            };
            await fixture.Subject.SetUserPreference(request);
            fixture.UserPreferenceManager.Received(1).SetPreference(user.Id, KnownSettingIds.AutomaticallyRefreshTaskPlannerResults, true);

            var tabs = fixture.DbContext.Set<TaskPlannerTab>().Where(x => x.IdentityId == user.Id).OrderBy(x => x.TabSequence).ToArray();
            Assert.False(tabs.Any());
        }

        [Fact]
        public async Task VerifyGetEmailContent()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var req = new DeferReminderRequest { TaskPlannerRowKeys = new[] { "A^55^78" } };
            fixture.TaskPlannerRowSelectionService.GetSelectedTaskPlannerRowKeys(req).Returns(req.TaskPlannerRowKeys);
            await fixture.Subject.GetEmailContent(req);
            await fixture.ReminderManager.Received(1).GetEmailContent(req.TaskPlannerRowKeys);
        }

        [Fact]
        public async Task VerifyGetDueDateResponsibility()
        {
            var fixture = new TaskPlannerControllerFixture(Db);
            var rowKey = "C^55^78";
            var name = new Inprotech.Web.Picklists.Name { Key = Fixture.Integer() };
            fixture.ReminderManager.GetDueDateResponsibility(rowKey).Returns(name);

            var result = await fixture.Subject.GetDueDateResponsibility(rowKey);
            Assert.Equal(result.Key, name.Key);
        }
    }

    public class TaskPlannerControllerFixture : IFixture<TaskPlannerController>
    {
        public TaskPlannerControllerFixture(InMemoryDbContext db = null)
        {
            SearchService = Substitute.For<ISearchService>();
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            Now = Substitute.For<Func<DateTime>>();
            SecurityContext = Substitute.For<ISecurityContext>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            StaticTranslator = Substitute.For<IStaticTranslator>();
            LastWorkingDayFinder = Substitute.For<ILastWorkingDayFinder>();
            CaseSearchService = Substitute.For<ICaseSearchService>();
            UserFilteredTypes = Substitute.For<IUserFilteredTypes>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            ReminderComments = Substitute.For<IReminderComments>();
            SearchExportService = Substitute.For<ISearchExportService>();
            ReminderManager = Substitute.For<IReminderManager>();
            TaskPlannerRowSelectionService = Substitute.For<ITaskPlannerRowSelectionService>();
            AdHocDates = Substitute.For<IAdHocDates>();
            UserPreferenceManager = Substitute.For<IUserPreferenceManager>();
            SubjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();
            Bus = Substitute.For<IBus>();
            ContentHasher = Substitute.For<IContentHasher>();
            TaskPlannerTabResolver = Substitute.For<ITaskPlannerTabResolver>();
            Subject = new TaskPlannerController(
                                                DbContext,
                                                SecurityContext,
                                                SearchService,
                                                Now,
                                                PreferredCultureResolver,
                                                StaticTranslator,
                                                LastWorkingDayFinder,
                                                CaseSearchService,
                                                UserFilteredTypes,
                                                SiteControlReader,
                                                TaskSecurityProvider,
                                                ReminderComments,
                                                SearchExportService,
                                                ReminderManager,
                                                UserPreferenceManager,
                                                TaskPlannerRowSelectionService,
                                                AdHocDates,
                                                SubjectSecurityProvider,
                                                Bus,
                                                ContentHasher,
                                                TaskPlannerTabResolver);
        }

        public ITaskPlannerTabResolver TaskPlannerTabResolver { get; }

        public IContentHasher ContentHasher { get; }
        public IBus Bus { get; }
        public ISecurityContext SecurityContext { get; set; }
        public ISearchService SearchService { get; set; }
        public ISearchExportService SearchExportService { get; set; }
        public IDbContext DbContext { get; set; }
        public Func<DateTime> Now { get; set; }
        public ILastWorkingDayFinder LastWorkingDayFinder { get; set; }
        public ICaseSearchService CaseSearchService { get; set; }
        public IUserFilteredTypes UserFilteredTypes { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; }
        public IStaticTranslator StaticTranslator { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IReminderComments ReminderComments { get; set; }
        public IReminderManager ReminderManager { get; set; }
        public ITaskPlannerRowSelectionService TaskPlannerRowSelectionService { get; set; }
        public IAdHocDates AdHocDates { get; set; }
        public IUserPreferenceManager UserPreferenceManager { get; set; }
        public ISubjectSecurityProvider SubjectSecurityProvider { get; set; }
        public TaskPlannerController Subject { get; }

        public TaskPlannerControllerFixture WithTasks(params ApplicationTask[] tasks)
        {
            foreach (var t in tasks) TaskSecurityProvider.HasAccessTo(t).Returns(true);

            return this;
        }

        public TaskPlannerControllerFixture WithTasksFullPermissions(params ApplicationTask[] tasks)
        {
            foreach (var t in tasks) TaskSecurityProvider.HasAccessTo(t, Arg.Any<ApplicationTaskAccessLevel>()).Returns(true);

            return this;
        }
    }
}