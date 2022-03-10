using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing.Forecast;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingRequestLogControllerFacts
    {
        public class ColumnFilteringFacts
        {
            [Fact]
            public void ForwardsCorrectParametersForFiltering()
            {
                var field = Fixture.String();
                var filters = new CodeDescription[0];
                var parameters = new CommonQueryParameters();
                var db = Substitute.ForPartsOf<InMemoryDbContext>();
                var f = new PolicingRequestLogControllerFixture(db);

                f.PolicingRequestLogReader
                 .AllowableFilters(Arg.Any<string>(), Arg.Any<CommonQueryParameters>())
                 .Returns(filters);

                var r = f.Subject.GetFilterDataForColumn(field, parameters.Filters);

                Assert.Equal(filters, r);

                f.PolicingRequestLogReader.Received(1).AllowableFilters(field, Arg.Is<CommonQueryParameters>(_ => _.Filters.Equals(parameters.Filters)));
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ShouldCallPolicingQueueWithStatus()
            {
                var f = new PolicingRequestLogControllerFixture(Db);

                f.ErrorReader.Read(Arg.Any<DateTime[]>(), Arg.Any<int>())
                 .Returns(new Dictionary<DateTime, RequestLogError>());

                f.Subject.Get(CommonQueryParameters.Default);

                f.PolicingRequestLogReader.Received().Retrieve();
            }
        }

        public class ControllerFacts
        {
            [Fact]
            public void RequiresPolicingAdministrationTask()
            {
                var r = TaskSecurity.Secures<PolicingRequestLogController>(ApplicationTask.PolicingAdministration);

                Assert.True(r);
            }

            [Fact]
            public void RequiresViewPolicingDashboardTask()
            {
                var r = TaskSecurity.Secures<PolicingRequestLogController>(ApplicationTask.ViewPolicingDashboard);

                Assert.True(r);
            }
        }

        public class ViewMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnsCanViewOrMaintainRequestPermission(bool access)
            {
                var f = new PolicingRequestLogControllerFixture(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPolicingRequest)
                 .Returns(access);
                Assert.Equal(access, f.Subject.View().CanViewOrMaintainRequests);
            }
        }

        public class RecentMethod : FactBase
        {
            [Fact]
            public void ReturnsCanCalculateAffectedCases()
            {
                var f = new PolicingRequestLogControllerFixture(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPolicingRequest)
                 .Returns(true);

                f.Subject.Recent();
                f.PolicingRequestSps.Received(1).GetNoOfAffectedCases(0, true);
            }

            [Fact]
            public void ShouldCallPolicingQueueWithStatus()
            {
                var f = new PolicingRequestLogControllerFixture(Db);

                f.ErrorReader.Read(Arg.Any<DateTime[]>(), Arg.Any<int>())
                 .Returns(new Dictionary<DateTime, RequestLogError>());

                f.Subject.Get(CommonQueryParameters.Default);

                f.PolicingRequestLogReader.Received().Retrieve();
            }
        }
        
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldNotDeleteThePolicyLog()
            {
                int policyLogId = 1;
                var f = new PolicingRequestLogControllerFixture(Db);
                var result = f.Subject.DeletePolicingLog(policyLogId);

                Assert.Equal("error", result.Result.Status);
            }

            [Fact]
            public void ShouldDeleteThePolicyLog()
            {
                int policyLogId = 1;
                var f = new PolicingRequestLogControllerFixture(Db);
                new PolicingLog
                {
                    PolicingLogId = policyLogId,
                    FailMessage = null,
                    FinishDateTime = null,
                    SpId = Fixture.Short()
                }.In(Db);
               
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.PolicingAdministration)
                 .Returns(true);
                var result = f.Subject.DeletePolicingLog(policyLogId);
                Assert.Equal("success", result.Result.Status);
            }
        }

        public class PolicingRequestLogControllerFixture : IFixture<PolicingRequestLogController>
        {
            public PolicingRequestLogControllerFixture(InMemoryDbContext db)
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.Filter(Arg.Any<IEnumerable<PolicingRequestLogItem>>(), Arg.Any<CommonQueryParameters>())
                                  .Returns(x => x[0]);

                PolicingRequestLogReader = Substitute.For<IPolicingRequestLogReader>();
                PolicingRequestLogReader.Retrieve()
                                        .Returns(new[]
                                        {
                                            new PolicingRequestLogItem()
                                        }.AsQueryable());

                ErrorReader = Substitute.For<IRequestLogErrorReader>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                PolicingRequestSps = Substitute.For<IPolicingRequestSps>();
                InprotechVersionChecker = Substitute.For<IInprotechVersionChecker>();
                InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(true);

                Subject = new PolicingRequestLogController(PolicingRequestLogReader, TaskSecurityProvider, CommonQueryService, ErrorReader, PolicingRequestSps, InprotechVersionChecker, db);
            }

            public ICommonQueryService CommonQueryService { get; set; }

            public IPolicingRequestLogReader PolicingRequestLogReader { get; set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public IRequestLogErrorReader ErrorReader { get; set; }

            public PolicingRequestLogController Subject { get; set; }

            public IPolicingRequestSps PolicingRequestSps { get; set; }

            public IInprotechVersionChecker InprotechVersionChecker { get; set; }
        }
    }
}