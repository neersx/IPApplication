using System.Dynamic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using Inprotech.Web.Names.Details;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Details
{
    public class NameActivityAttachmentMaintenanceFacts : FactBase
    {
        Name CreateNewName(int nameId)
        {
            return new Name(nameId) {LastName = "L", FirstName = "F"}.In(Db);
        }

        [Fact]
        public async Task ReturnsViewDetails()
        {
            var nameId = Fixture.Integer();
            var name = CreateNewName(nameId);

            var f = new ActivityAttachmentMaintenanceFixture(Db);
            f.ActivityMaintenance.ViewDetails().ReturnsForAnyArgs(new ExpandoObject());

            dynamic result = await f.Subject.ViewDetails(nameId);
            f.ActivityMaintenance.Received(1).ViewDetails().IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(nameId, result.nameId);
            Assert.Equal(name.FormattedNameOrNull(), result.displayName);
        }

        [Fact]
        public async Task GetAttachmentsReturnsData()
        {
            var nameId = Fixture.Integer();

            var activity1 = new Activity {Id = 1, ContactNameId = nameId, ActivityCategory = new TableCode(), ActivityType = new TableCode()}.In(Db);
            new ActivityAttachment {ActivityId = 1, SequenceNo = 1, Activity = activity1}.In(Db);

            var activity2 = new Activity {Id = 2, ContactNameId = nameId, ActivityCategory = new TableCode(), ActivityType = new TableCode()}.In(Db);
            new ActivityAttachment {ActivityId = 2, SequenceNo = 1, Activity = activity2}.In(Db);
            new ActivityAttachment {ActivityId = 2, SequenceNo = 2, Activity = activity2}.In(Db);

            var f = new ActivityAttachmentMaintenanceFixture(Db);

            var result = await f.Subject.GetAttachments(nameId, new CommonQueryParameters());

            Assert.Equal(3, result.Count());
        }

        [Fact]
        public async Task InsertAttachmentCallsTransactionRecordal()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await f.Subject.InsertAttachment(new ActivityAttachmentModel {ActivityNameId = 10, ActivityId = 1});

            f.TransactionRecordal.Received(1).RecordTransactionForName(10, NameTransactionMessageIdentifier.AmendedName);
        }

        [Fact]
        public async Task UpdateAttachmentCallsTransactionRecordal()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await f.Subject.UpdateAttachment(new ActivityAttachmentModel {ActivityNameId = 10, ActivityId = 1});

            f.TransactionRecordal.Received(1).RecordTransactionForName(10, NameTransactionMessageIdentifier.AmendedName);
        }

        [Fact]
        public async Task DeleteAttachmentCallsTransactionRecordal()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await f.Subject.DeleteAttachment(new ActivityAttachmentModel {ActivityNameId = 10, ActivityId = 1});

            f.TransactionRecordal.Received(1).RecordTransactionForName(10, NameTransactionMessageIdentifier.AmendedName);
        }
    }

    public class ActivityAttachmentMaintenanceFixture : IFixture<IActivityAttachmentMaintenance>
    {
        public ActivityAttachmentMaintenanceFixture(InMemoryDbContext db)
        {
            ActivityMaintenance = Substitute.For<IActivityMaintenance>();
            AttachmentMaintenance = Substitute.For<IAttachmentMaintenance>();
            TransactionRecordal = Substitute.For<ITransactionRecordal>();

            Subject = new NameActivityAttachmentMaintenance(db, AttachmentMaintenance, ActivityMaintenance, Substitute.For<IAttachmentContentLoader>(), TransactionRecordal);
        }

        public IActivityMaintenance ActivityMaintenance { get; set; }
        public IAttachmentMaintenance AttachmentMaintenance { get; set; }
        public ITransactionRecordal TransactionRecordal { get; set; }
        public IActivityAttachmentMaintenance Subject { get; }
    }
}