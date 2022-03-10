using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingErrorLogControllerFacts : FactBase
    {
        readonly IPolicingErrorLog _policingErrorLog = Substitute.For<IPolicingErrorLog>();
        readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

        PolicingErrorLogController CreateSubject()
        {
            return new PolicingErrorLogController(_taskSecurityProvider, _policingErrorLog, Db);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public void ShouldReturnCanAdministerPermission(bool accessAvailability, bool expectedResult)
        {
            _taskSecurityProvider.HasAccessTo(ApplicationTask.PolicingAdministration)
                                 .Returns(accessAvailability);

            var subject = CreateSubject();

            Assert.Equal(expectedResult, subject.View().Permissions.CanAdminister);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(false, false)]
        public void ShouldReturnCanMaintainWorkflowPermission(bool accessAvailability, bool expectedResult)
        {
            _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules)
                                 .Returns(accessAvailability);

            var subject = CreateSubject();

            Assert.Equal(expectedResult, subject.View().Permissions.CanMaintainWorkflow);
        }

        [Fact]
        public void ShouldReturnPagedResultsFromErrorLog()
        {
            _policingErrorLog.Retrieve(Arg.Any<CommonQueryParameters>())
                             .Returns(new[]
                             {
                                 new PolicingErrorLogItem(),
                                 new PolicingErrorLogItem()
                             }.AsQueryable());

            _policingErrorLog.SetInProgressFlag(Arg.Any<IEnumerable<PolicingErrorLogItem>>())
                             .Returns(x => x[0]);

            var subject = CreateSubject();

            var r = subject.Errors();

            Assert.Equal(2, r.Pagination.Total);
            Assert.Equal(2, r.Data.Count());
        }

        [Fact]
        public async Task ShouldDeleteErrorItemsAsRequested()
        {
            var a = new PolicingError { PolicingErrorsId = 1 }.In(Db);
            var b = new PolicingError { PolicingErrorsId = 2 }.In(Db);
            var c = new PolicingError { PolicingErrorsId = 3 }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Delete(new[] {a.PolicingErrorsId, c.PolicingErrorsId});

            Assert.Equal(b, Db.Set<PolicingError>().Single());

            Assert.Equal("success", r.Status);
        }
    }
}