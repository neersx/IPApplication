using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ContactActivities
{
    public class ActivityAttachmentMaintenanceViewFacts : FactBase
    {
        [Fact]
        public void ViewDetailsReturnsActivityViewDetails()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);
            f.Subject.ViewDetails(10);

            f.ActivityMaintenance.Received(1).ViewDetails();
        }
    }

    public class ActivityAttachmentMaintenanceDeleteFacts : FactBase
    {
        [Fact]
        public async Task DeleteAttachmentCallsToDeletesAttachmentOnly()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);
            f.AttachmentMaintenance.DeleteAttachment(Arg.Any<ActivityAttachmentModel>()).ReturnsForAnyArgs(true);

            var data = new ActivityAttachmentModel {ActivityId = 10, SequenceNo = 1};
            var deleted = await f.Subject.DeleteAttachment(data);

            f.AttachmentMaintenance.Received(1).DeleteAttachment(Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();
            f.ActivityMaintenance.Received(0).TryDelete(Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();

            Assert.True(deleted);
        }
    }

    public class ActivityAttachmentMaintenanceFixture : IFixture<ActivityAttachmentMaintenance>
    {
        public ActivityAttachmentMaintenanceFixture(InMemoryDbContext db)
        {
            ActivityMaintenance = Substitute.For<IActivityMaintenance>();
            AttachmentMaintenance = Substitute.For<IAttachmentMaintenance>();
            TransactionRecordal = Substitute.For<ITransactionRecordal>();

            Subject = new ActivityAttachmentMaintenance(AttachmentMaintenance, ActivityMaintenance, db, Substitute.For<IAttachmentContentLoader>(), TransactionRecordal);
        }

        public IActivityMaintenance ActivityMaintenance { get; }

        public IAttachmentMaintenance AttachmentMaintenance { get; }

        public ITransactionRecordal TransactionRecordal { get; }

        public ActivityAttachmentMaintenance Subject { get; }
    }
}