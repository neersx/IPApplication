using System;
using System.Collections.Generic;
using System.Dynamic;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ContactActivities
{
    public class ActivityAttachmentMaintenanceBaseGetAttachmentFacts : FactBase
    {
        [Fact]
        public async Task GetAttachmentThrowsExceptionIfDataNotFound()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);
            await Assert.ThrowsAsync<InvalidDataException>(() => f.Subject.GetAttachment(10, 1));
        }

        [Fact]
        public async Task GetAttachmentReturnsAttachmentData()
        {
            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);
            var activity = new Activity
            {
                Id = 1,
                ActivityCategory = new TableCode {Id = 1},
                ActivityDate = Fixture.Today(),
                ActivityType = new TableCode {Id = 9},
                CaseId = 10,
                ContactNameId = 100,
                EventId = 87,
                Cycle = 4
            }.In(Db);

            var attachment = new ActivityAttachment
            {
                Activity = activity,
                ActivityId = activity.Id,
                SequenceNo = 1,
                AttachmentName = "Old MacDonald",
                AttachmentType = new TableCode {Id = 4, Name = "Quack Quack"},
                FileName = "C:\\ABCD\\A.docx",
                PublicFlag = 1,
                Language = new TableCode {Id = 190, Name = "German"},
                PageCount = 10,
                AttachmentDescription = "And on his farm he had some ducks"
            }.In(Db);

            var data = await f.Subject.GetAttachment(1, 1);

            Assert.Equal(activity.Id, data.ActivityId);
            Assert.Equal(activity.CaseId, data.ActivityCaseId);
            Assert.Equal(activity.ContactNameId, data.ActivityNameId);
            Assert.Equal(activity.ActivityCategory.Id, data.ActivityCategoryId);
            Assert.Equal(activity.ActivityType.Id, data.ActivityType);
            Assert.Equal(activity.ActivityDate, data.ActivityDate);
            Assert.Equal(activity.EventId, data.EventId);
            Assert.Equal(activity.EventId, data.EventId);

            Assert.Equal(attachment.SequenceNo, data.SequenceNo);
            Assert.Equal(attachment.AttachmentName, data.AttachmentName);
            Assert.Equal(attachment.AttachmentType.Id, data.AttachmentType);
            Assert.Equal(attachment.AttachmentType.Name, data.AttachmentTypeDescription);
            Assert.Equal(attachment.FileName, data.FilePath);
            Assert.Equal(attachment.PublicFlag == 1, data.IsPublic);
            Assert.Equal(attachment.Language.Id, data.Language);
            Assert.Equal(attachment.Language.Name, data.LanguageDescription);
            Assert.Equal(attachment.PageCount, data.PageCount);
            Assert.Equal(attachment.AttachmentDescription, data.AttachmentDescription);
        }
    }

    public class ActivityAttachmentMaintenanceBaseInsertAttachmentFacts : FactBase
    {
        [Fact]
        public async Task ThrowsExceptionIfNoDataProvided()
        {
            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);

            await Assert.ThrowsAsync<ArgumentNullException>(() => f.Subject.InsertAttachment(null));
        }

        [Fact]
        public async Task DoesNotInsertActivityIfPresent()
        {
            var data = new ActivityAttachmentModel {ActivityId = 1, ActivityCaseId = 10};

            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);
            f.AttachmentMaintenance.InsertAttachment(Arg.Any<ActivityAttachmentModel>()).ReturnsForAnyArgs(data);

            var result = await f.Subject.InsertAttachment(data);
            
            f.ActivityMaintenance.Received(0).InsertActivity(Arg.Any<int?>(), Arg.Any<int>(), Arg.Any<dynamic>());
            f.AttachmentMaintenance.Received(1).InsertAttachment(Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();
            Assert.Equal(data, result);
        }

        [Fact]
        public async Task InsertActivityIfAbsent()
        {
            var data = new ActivityAttachmentModel {ActivityNameId = 10, ActivityCaseId = 100};

            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);
            f.ActivityMaintenance.InsertActivity(Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<ActivityAttachmentModel>()).Returns(new Activity {Id = 10});
            f.AttachmentMaintenance.InsertAttachment(Arg.Any<ActivityAttachmentModel>()).ReturnsForAnyArgs(data);

            var result = await f.Subject.InsertAttachment(data);
            
            f.ActivityMaintenance.Received(1).InsertActivity(Arg.Is<int?>(_ => _ == 10), Arg.Is<int?>(_ => _ == 100), Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();
            f.AttachmentMaintenance.Received(1).InsertAttachment(Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(data, result);
        }
    }

    public class ActivityAttachmentMaintenanceBaseUpdateAttachmentFacts : FactBase
    {
        [Fact]
        public async Task ThrowsExceptionIfNoDataProvided()
        {
            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);

            await Assert.ThrowsAsync<ArgumentNullException>(() => f.Subject.UpdateAttachment(null));
            await Assert.ThrowsAsync<ArgumentNullException>(() => f.Subject.UpdateAttachment(new ActivityAttachmentModel {ActivityId = null}));
        }

        [Fact]
        public async Task UpdateActivityAndAttachment()
        {
            var data = new ActivityAttachmentModel {ActivityNameId = 10, ActivityCaseId = 100, SequenceNo = 1, ActivityId = 1};
            var expectedResult = new ActivityAttachmentModel();

            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);
            f.AttachmentMaintenance.UpdateAttachment(Arg.Any<ActivityAttachmentModel>()).ReturnsForAnyArgs(expectedResult);

            var result = await f.Subject.UpdateAttachment(data);
            
            f.ActivityMaintenance.Received(1).UpdateActivity(Arg.Is<int>(_ => _ == data.ActivityId), Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();
            f.AttachmentMaintenance.Received(1).UpdateAttachment(Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();
            Assert.Equal(expectedResult, result);
        }
    }

    public class ActivityAttachmentMaintenanceBaseDeleteAttachmentFacts : FactBase
    {
        [Fact]
        public async Task DeleteAttachmentThrowsExceptionIfParameterNotProvided()
        {
            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);
            await Assert.ThrowsAsync<ArgumentNullException>(() => f.Subject.DeleteAttachment(null));
        }

        [Fact]
        public async Task DeleteAttachmentCallsToDeletesAttachmentOnly()
        {
            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);
            f.AttachmentMaintenance.DeleteAttachment(Arg.Any<ActivityAttachmentModel>()).ReturnsForAnyArgs(true);

            var data = new ActivityAttachmentModel {ActivityId = 10, SequenceNo = 1};
            var deleted = await f.Subject.DeleteAttachment(data, false);

            f.TransactionRecordal.Received(0).RecordTransactionForCase(Arg.Any<int>(), CaseTransactionMessageIdentifier.AmendedCase);
            f.AttachmentMaintenance.Received(1).DeleteAttachment(Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();
            f.ActivityMaintenance.Received(0).TryDelete(Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();

            Assert.True(deleted);
        }

        [Fact]
        public async Task DeleteAttachmentCallsToDeleteActivityAsWell()
        {
            var f = new ActivityAttachmentMaintenanceBaseFakeFixture(Db);
            f.AttachmentMaintenance.DeleteAttachment(Arg.Any<ActivityAttachmentModel>()).ReturnsForAnyArgs(true);

            var data = new ActivityAttachmentModel {ActivityId = 10, SequenceNo = 1};
            var deleted = await f.Subject.DeleteAttachment(data, true);

            f.AttachmentMaintenance.Received(1).DeleteAttachment(Arg.Is<ActivityAttachmentModel>(_ => _ == data)).IgnoreAwaitForNSubstituteAssertion();
            f.ActivityMaintenance.Received(1).TryDelete(Arg.Is<int>(_ => _ == 10)).IgnoreAwaitForNSubstituteAssertion();

            Assert.True(deleted);
        }
    }

    public class ActivityAttachmentMaintenanceBaseFake : ActivityAttachmentMaintenanceBase
    {
        public ActivityAttachmentMaintenanceBaseFake(AttachmentFor attachmentFor, IAttachmentMaintenance attachmentMaintenance, IActivityMaintenance activityMaintenance, IDbContext dbContext, IAttachmentContentLoader attachmentContentLoader, ITransactionRecordal transactionRecordal) : base(attachmentFor, attachmentMaintenance, activityMaintenance, dbContext, attachmentContentLoader, transactionRecordal)
        {
        }

        public override Task<ExpandoObject> ViewDetails(int? id, int? eventId = null, string actionKey = null)
        {
            throw new NotImplementedException();
        }

        public override Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            throw new NotImplementedException();
        }

        public override Task<IEnumerable<ActivityAttachmentModel>> GetAttachments(int caseOrNameId, CommonQueryParameters param)
        {
            throw new NotImplementedException();
        }
    }

    public class ActivityAttachmentMaintenanceBaseFakeFixture : IFixture<IActivityAttachmentMaintenance>
    {
        public ActivityAttachmentMaintenanceBaseFakeFixture(InMemoryDbContext db)
        {
            ActivityMaintenance = Substitute.For<IActivityMaintenance>();
            AttachmentMaintenance = Substitute.For<IAttachmentMaintenance>();
            TransactionRecordal = Substitute.For<ITransactionRecordal>();

            Subject = new ActivityAttachmentMaintenanceBaseFake(AttachmentFor.ContactActivity, AttachmentMaintenance, ActivityMaintenance, db, Substitute.For<IAttachmentContentLoader>(), TransactionRecordal);
        }

        public IActivityMaintenance ActivityMaintenance { get; }
        public IAttachmentMaintenance AttachmentMaintenance { get; }
        public ITransactionRecordal TransactionRecordal { get; }
        public IActivityAttachmentMaintenance Subject { get; }
    }
}