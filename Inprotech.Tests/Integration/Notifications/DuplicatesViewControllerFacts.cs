using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class DuplicatesViewControllerFacts
    {
        [Fact]
        public void CallsApproperiateMethods()
        {
            const int forId = 1;
            var f = new DuplicatesViewControllerFixture();
            f.Subject.Get(Enum.GetName(typeof(DataSourceType), DataSourceType.IpOneData), forId).IgnoreAwaitForNSubstituteAssertion();

            f.TaskSecurityProvider.Received(1).HasAccessTo(ApplicationTask.SaveImportedCaseData);
            f.CaseNotificationsForDuplicates.Received(1).FetchDuplicatesFor(DataSourceType.IpOneData, forId);
        }

        [Fact]
        public async Task ThrowsArgumentExceptionIfInvalidDataSource()
        {
            var f = new DuplicatesViewControllerFixture();
            await Assert.ThrowsAsync<ArgumentException>(async () => await f.Subject.Get("something thats not there", Fixture.Integer()));
        }
    }

    public class DuplicatesViewControllerFixture : IFixture<DuplicatesViewController>
    {
        public DuplicatesViewControllerFixture()
        {
            CaseNotificationsForDuplicates = Substitute.For<ICaseNotificationsForDuplicates>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            Subject = new DuplicatesViewController(TaskSecurityProvider, CaseNotificationsForDuplicates);
        }

        public ICaseNotificationsForDuplicates CaseNotificationsForDuplicates { get; }

        public ITaskSecurityProvider TaskSecurityProvider { get; }

        public DuplicatesViewController Subject { get; }
    }
}