using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Attachments;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ContactActivities
{
    class ActivityMaintenanceFixture : IFixture<ActivityMaintenance>
    {
        public ActivityMaintenanceFixture(InMemoryDbContext db)
        {
            LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
            LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Activity).Returns(1);
            AttachmentSettings = Substitute.For<IAttachmentSettings>();
            DmsSettingsProvider = Substitute.For<IDmsSettingsProvider>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Subject = new ActivityMaintenance(db, LastInternalCodeGenerator, AttachmentSettings, DmsSettingsProvider, TaskSecurityProvider);
        }

        public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
        public IAttachmentSettings AttachmentSettings { get; set; }
        public IDmsSettingsProvider DmsSettingsProvider { get; set; }
        ITaskSecurityProvider TaskSecurityProvider { get; }
        public ActivityMaintenance Subject { get; }

        public ActivityMaintenanceFixture WithAttachments()
        {
            DmsSettingsProvider.HasSettings().Returns(true);
            TaskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms).Returns(true);
            return this;
        }
    }
    public class ActivityMaintenanceFacts : FactBase
    {
        [Fact]
        public async Task ReturnsViewDetails()
        {
            new TableCode { TableTypeId = (short)TableTypes.ContactActivityType, Id = 1, Name = "Humpty" }.In(Db);
            new TableCode { TableTypeId = (short)TableTypes.ContactActivityType, Id = 2, Name = "Dumpty" }.In(Db);

            new TableCode { TableTypeId = (short)TableTypes.ContactActivityCategory, Id = 11, Name = "Cuddlepie" }.In(Db);
            new TableCode { TableTypeId = (short)TableTypes.ContactActivityCategory, Id = 12, Name = "Snugglepot" }.In(Db);

            var f = new ActivityMaintenanceFixture(Db).WithAttachments();
            var result = (IDictionary<string, object>)await f.Subject.ViewDetails();

            var activityTypes = ((IEnumerable<dynamic>)result["activityTypes"]).ToArray();
            Assert.Equal(2, activityTypes.Count());
            Assert.Equal(1, activityTypes.First().Id);
            Assert.Equal("Humpty", activityTypes.First().Description);
            Assert.Equal(2, activityTypes.Last().Id);
            Assert.Equal("Dumpty", activityTypes.Last().Description);

            var categories = ((IEnumerable<dynamic>)result["categories"]).ToArray();
            Assert.Equal(2, categories.Count());
            Assert.Equal(11, categories.First().Id);
            Assert.Equal("Cuddlepie", categories.First().Description);
            Assert.Equal(12, categories.Last().Id);
            Assert.Equal("Snugglepot", categories.Last().Description);

            Assert.True((bool)result["canBrowseDms"]);
        }

        [Fact]
        public async Task GetActivityReturnsNullIfNoData()
        {
            var f = new ActivityMaintenanceFixture(Db);
            Assert.Null(await f.Subject.GetActivity(10));
        }

        [Fact]
        public async Task GetActivityReturnsDetailsFromDb()
        {
            var activity = new Activity { Id = 10, ActivityCategory = new TableCode() { Id = 10 }, ActivityType = new TableCode() { Id = 100 }, ActivityDate = Fixture.Today(), CaseId = 88, ContactNameId = 8, EventId = -89, Cycle = 56 }.In(Db);

            var f = new ActivityMaintenanceFixture(Db);
            var result = await f.Subject.GetActivity(10);

            Assert.NotNull(activity);
            Assert.Equal(activity.Id, result.ActivityId);
            Assert.Equal(activity.ActivityCategory.Id, result.ActivityCategoryId);
            Assert.Equal(activity.ActivityType.Id, result.ActivityType);
            Assert.Equal(activity.ActivityDate, result.ActivityDate);
            Assert.Equal(activity.CaseId, result.ActivityCaseId);
            Assert.Equal(activity.ContactNameId, result.ActivityNameId);
            Assert.Equal(activity.EventId, result.EventId);
            Assert.Equal(activity.Cycle, result.EventCycle);
        }

        [Fact]
        public async Task InsertsActivity()
        {
            var category = new TableCode { Id = 8 }.In(Db);
            var activityType = new TableCode { Id = 9 }.In(Db);
            var data = new ActivityAttachmentModel { ActivityDate = Fixture.Today(), ActivityCategoryId = 8, ActivityType = 9, EventId = 88, EventCycle = 56, ActivityCaseId = 99 };

            var f = new ActivityMaintenanceFixture(Db);

            var result = await f.Subject.InsertActivity(null, data.ActivityCaseId, data);

            Assert.NotNull(result);
            Assert.Equal(data.ActivityCaseId, result.CaseId);
            Assert.Equal(1, result.Id);
            Assert.Equal(data.ActivityDate, result.ActivityDate);
            Assert.Equal(category, result.ActivityCategory);
            Assert.Equal(activityType, result.ActivityType);
            Assert.Equal(data.EventId, result.EventId);
            Assert.Equal(data.EventCycle, result.Cycle);
        }

        [Fact]
        public async Task UpdatesActivity()
        {
            var category = new TableCode { Id = 8 }.In(Db);
            var activityType = new TableCode { Id = 9 }.In(Db);
            new Activity { Id = 7 }.In(Db);
            var data = new ActivityAttachmentModel { ActivityDate = Fixture.Today(), ActivityCategoryId = 8, ActivityType = 9, EventId = 88, EventCycle = 56, ActivityId = 7 };

            var f = new ActivityMaintenanceFixture(Db);

            var result = await f.Subject.UpdateActivity(data.ActivityId.Value, data);

            Assert.NotNull(result);
            Assert.Equal(data.ActivityId, result.Id);
            Assert.Equal(data.ActivityDate, result.ActivityDate);
            Assert.Equal(category, result.ActivityCategory);
            Assert.Equal(activityType, result.ActivityType);
            Assert.Equal(data.EventId, result.EventId);
            Assert.Equal(data.EventCycle, result.Cycle);
        }

        [Fact]
        public async Task DeleteActivityDoesNotDeleteIfAttachmentsArePresent()
        {
            new Activity { Id = 7, Attachments = { new ActivityAttachment { ActivityId = 7, SequenceNo = 1 }.In(Db) } }.In(Db);

            var f = new ActivityMaintenanceFixture(Db);
            var result = await f.Subject.TryDelete(7);
            Assert.False(result);

            Assert.Equal(1, Db.Set<Activity>().Count());
        }

        [Fact]
        public async Task DeletesActivity()
        {
            new Activity { Id = 7 }.In(Db);

            var f = new ActivityMaintenanceFixture(Db);
            Assert.True(await f.Subject.TryDelete(7));

            Assert.Equal(0, Db.Set<Activity>().Count());
        }
    }
}