using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingQueueControllerFacts
    {
        public class ColumnFilteringFacts
        {
            [Fact]
            public void ForwardsCorrectParametersForFiltering()
            {
                var field = Fixture.String();
                var byStatus = Fixture.String();
                var filters = new CodeDescription[0];
                var parameters = new CommonQueryParameters();

                var f = new PolicingQueueControllerFixture();

                f.PolicingQueue
                 .AllowableFilters(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CommonQueryParameters>())
                 .Returns(filters);

                var r = f.Subject.GetFilterDataForColumn(field, byStatus, parameters.Filters);

                Assert.Equal(filters, r);

                f.PolicingQueue.Received(1).AllowableFilters(byStatus, field, Arg.Is<CommonQueryParameters>(_ => _.Filters.Equals(parameters.Filters)));
            }
        }

        public class GetMethod : FactBase
        {
            [Theory]
            [InlineData("all")]
            [InlineData("waiting-to-start")]
            [InlineData("in-error")]
            [InlineData("in-progress")]
            [InlineData("on-hold")]
            public void ShouldCallPolicingQueueWithStatus(string byStatus)
            {
                var r = new[] {new PolicingQueueItem()};

                var f = new PolicingQueueControllerFixture().With(r);

                f.Subject.Get(byStatus, CommonQueryParameters.Default);

                f.PolicingQueue.Received().Retrieve(byStatus);
            }

            [Theory]
            [InlineData("all")]
            [InlineData("waiting-to-start")]
            [InlineData("in-error")]
            [InlineData("in-progress")]
            [InlineData("on-hold")]
            public void RemapsUserKeyWhenFilterByUser(string byStatus)
            {
                var r = new[] {new PolicingQueueItem()};

                var qp = new CommonQueryParameters
                {
                    Filters = new[]
                    {
                        new CommonQueryParameters.FilterValue
                        {
                            Field = "user"
                        }
                    }
                };

                var f = new PolicingQueueControllerFixture().With(r);

                f.Subject.Get(byStatus, qp);

                f.CommonQueryService
                 .Received(1)
                 .Filter(Arg.Any<IEnumerable<PolicingQueueItem>>(),
                         Arg.Is<CommonQueryParameters>(p => p.Filters.Single().Field == "userKey"));
            }

            [Fact]
            public void OnlyRequestsTop5Errors()
            {
                var f = new PolicingQueueControllerFixture();

                f.Subject.Get(Fixture.String(), CommonQueryParameters.Default);

                f.ErrorReader.Received(1).Read(Arg.Any<int[]>(), 5);
            }

            [Fact]
            public void ReturnsErrorsForQueueItems()
            {
                var queueItems = new[]
                {
                    new PolicingQueueItem
                    {
                        CaseId = 1
                    },
                    new PolicingQueueItem
                    {
                        CaseId = 2
                    }
                };

                var errors = new[]
                {
                    new QueueError
                    {
                        CaseId = 2,
                        ErrorItems = new PolicingErrorItem[0],
                        TotalErrorItemsCount = 45
                    }
                };

                var f = new PolicingQueueControllerFixture()
                        .With(queueItems)
                        .With(errors);

                var pr = f.Subject.Get(Fixture.String(), CommonQueryParameters.Default);

                Assert.Null(((PagedResults) pr.Items).Items<PolicingQueueItem>().First().Error);
                Assert.Equal(errors.Single(), ((PagedResults) pr.Items).Items<PolicingQueueItem>().Last().Error);
            }

            [Fact]
            public void ReturnsSpecifiedPageOnly()
            {
                var qp = new CommonQueryParameters
                {
                    Skip = 1,
                    Take = 2
                };

                var queueItems = new[]
                {
                    new PolicingQueueItem(),
                    new PolicingQueueItem(),
                    new PolicingQueueItem()
                };

                var f = new PolicingQueueControllerFixture()
                    .With(queueItems);

                var r = f.Subject.Get(Fixture.String(), qp);

                Assert.Equal(3, ((PagedResults) r.Items).Pagination.Total);
                Assert.Equal(2, ((PagedResults) r.Items).Items<PolicingQueueItem>().Count());
                Assert.DoesNotContain(queueItems.First(), ((PagedResults) r.Items).Items<PolicingQueueItem>());
            }
        }

        public class GetErrorsForMethod
        {
            const int CaseId = 100;

            [Fact]
            public void ReturnsErrorForCase()
            {
                var errorItems = new[]
                {
                    new PolicingErrorItem
                    {
                        CaseId = CaseId
                    },
                    new PolicingErrorItem
                    {
                        CaseId = CaseId
                    }
                };

                var f = new PolicingQueueControllerFixture()
                    .With(errorItems);

                var r = f.Subject.GetErrorsFor(CaseId);

                Assert.Equal(errorItems, r.Items<PolicingErrorItem>());
            }

            [Fact]
            public void ReturnsSpecifiedPageOnly()
            {
                var qp = new CommonQueryParameters
                {
                    Skip = 1,
                    Take = 2
                };

                var errorItems = new[]
                {
                    new PolicingErrorItem
                    {
                        CaseId = CaseId
                    },
                    new PolicingErrorItem
                    {
                        CaseId = CaseId
                    },
                    new PolicingErrorItem
                    {
                        CaseId = CaseId
                    }
                };

                var f = new PolicingQueueControllerFixture()
                    .With(errorItems);

                var r = f.Subject.GetErrorsFor(CaseId, qp);

                Assert.Equal(2, r.Items<PolicingErrorItem>().Count());
                Assert.DoesNotContain(errorItems.First(), r.Items<PolicingErrorItem>());
            }
        }

        public class GetViewDataMethod
        {
            [Fact]
            public void ReturnFalseIfNoAdministrationAcsess()
            {
                var f = new PolicingQueueControllerFixture().WithAdministrationTaskSecurity(false);
                var r = f.Subject.GetViewData();

                Assert.False(r.CanAdminister);
            }

            [Fact]
            public void ReturnTrueIfNoAdministrationAcsess()
            {
                var f = new PolicingQueueControllerFixture().WithAdministrationTaskSecurity(true);
                var r = f.Subject.GetViewData();

                Assert.True(r.CanAdminister);
            }
        }

        public class ControllerFacts
        {
            [Fact]
            public void RequiresPolicingAdministrationTask()
            {
                var r = TaskSecurity.Secures<PolicingQueueController>(ApplicationTask.PolicingAdministration);

                Assert.True(r);
            }

            [Fact]
            public void RequiresViewPolicingDashboardTask()
            {
                var r = TaskSecurity.Secures<PolicingQueueController>(ApplicationTask.ViewPolicingDashboard);

                Assert.True(r);
            }
        }

        public class PolicingQueueControllerFixture : IFixture<PolicingQueueController>
        {
            public PolicingQueueControllerFixture()
            {
                PolicingQueue = Substitute.For<IPolicingQueue>();

                ErrorReader = Substitute.For<IErrorReader>();

                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                DashboardDataProvider = Substitute.For<IDashboardDataProvider>();

                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.Filter(Arg.Any<IEnumerable<PolicingQueueItem>>(), Arg.Any<CommonQueryParameters>())
                                  .Returns(x => x[0]);

                DashboardDataProvider.Retrieve(RetrieveOption.Default)
                                     .Returns(new Dictionary<RetrieveOption, DashboardData>
                                     {
                                         {RetrieveOption.Default, new DashboardData()}
                                     });

                Subject = new PolicingQueueController(PolicingQueue, CommonQueryService, ErrorReader, TaskSecurityProvider, DashboardDataProvider);
            }

            public IPolicingQueue PolicingQueue { get; set; }

            public IErrorReader ErrorReader { get; set; }

            public ICommonQueryService CommonQueryService { get; set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public IDashboardDataProvider DashboardDataProvider { get; set; }

            public PolicingQueueController Subject { get; set; }

            public PolicingQueueControllerFixture WithAdministrationTaskSecurity(bool setTo)
            {
                TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(setTo);
                return this;
            }

            public PolicingQueueControllerFixture With(params PolicingQueueItem[] items)
            {
                PolicingQueue.Retrieve(Arg.Any<string>()).Returns(items);
                return this;
            }

            public PolicingQueueControllerFixture With(params QueueError[] items)
            {
                ErrorReader.Read(Arg.Any<int[]>(), Arg.Any<int>())
                           .Returns(items.ToDictionary(k => k.CaseId, v => v));
                return this;
            }

            public PolicingQueueControllerFixture With(params PolicingErrorItem[] items)
            {
                ErrorReader.For(Arg.Any<int>())
                           .Returns(items.AsQueryable());
                return this;
            }
        }
    }
}