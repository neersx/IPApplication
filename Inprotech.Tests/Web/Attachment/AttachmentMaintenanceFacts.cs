using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using Xunit;

namespace Inprotech.Tests.Web.Attachment
{
    public class AttachmentMaintenanceFacts : FactBase
    {
        [Fact]
        public async Task InsertAttachment()
        {
            new Activity {Id = 1, Attachments = {new ActivityAttachment {ActivityId = 1, SequenceNo = 5}.In(Db)}}.In(Db);
            new TableCode {Id = 99, TableTypeId = (short)TableTypes.AttachmentType, Name = "SomeName"}.In(Db);
            new TableCode {Id = 9, TableTypeId = (short)TableTypes.Language, Name = "La la"}.In(Db);

            var data = new ActivityAttachmentModel {ActivityId = 1, AttachmentName = "A", AttachmentType = 99, FilePath = "Abcd.docx", AttachmentDescription = "Ha ha", IsPublic = true, Language = 9, PageCount = 100};
            var f = new AttachmentMaintenance(Db);

            var result = await f.InsertAttachment(data);
            Assert.Equal(data.ActivityId, result.ActivityId);
            Assert.Equal(6, result.SequenceNo);
            Assert.Equal(data.AttachmentName, result.AttachmentName);
            Assert.Equal(data.AttachmentType, result.AttachmentType);
            Assert.Equal("SomeName", result.AttachmentTypeDescription);
            Assert.Equal(data.FilePath, result.FilePath);
            Assert.Equal(data.IsPublic, result.IsPublic);
            Assert.Equal(data.Language, result.Language);
            Assert.Equal("La la", result.LanguageDescription);
            Assert.Equal(data.PageCount, result.PageCount);
            Assert.Equal(data.AttachmentDescription, result.AttachmentDescription);
        }

        [Fact]
        public async Task InsertThrowsExceptionOnInvalidData()
        {
            var f = new AttachmentMaintenance(Db);
            await Assert.ThrowsAsync<ArgumentNullException>(() => f.InsertAttachment(null));
            await Assert.ThrowsAsync<ArgumentNullException>(() => f.InsertAttachment(new ActivityAttachmentModel() {SequenceNo = 0, ActivityId = null}));
        }

        [Fact]
        public async Task UpdateAttachment()
        {
            new Activity {Id = 1, Attachments = {new ActivityAttachment {ActivityId = 1, SequenceNo = 1}.In(Db)}}.In(Db);
            new TableCode {Id = 99, TableTypeId = (short)TableTypes.AttachmentType, Name = "SomeName"}.In(Db);
            new TableCode {Id = 9, TableTypeId = (short)TableTypes.Language, Name = "La la"}.In(Db);

            var data = new ActivityAttachmentModel {ActivityId = 1, SequenceNo = 1, AttachmentName = "A", AttachmentType = 99, FilePath = "Abcd.docx", AttachmentDescription = "Ha ha", IsPublic = true, Language = 9, PageCount = 100};
            var f = new AttachmentMaintenance(Db);
            var result = await f.UpdateAttachment(data);

            Assert.Equal(data.ActivityId, result.ActivityId);
            Assert.Equal(1, result.SequenceNo);
            Assert.Equal(data.ActivityCategoryId, result.ActivityCategoryId);
            Assert.Equal(data.ActivityType, result.ActivityType);
            Assert.Equal(data.AttachmentName, result.AttachmentName);
            Assert.Equal(data.AttachmentType, result.AttachmentType);
            Assert.Equal("SomeName", result.AttachmentTypeDescription);
            Assert.Equal(data.FilePath, result.FilePath);
            Assert.Equal(data.IsPublic, result.IsPublic);
            Assert.Equal(data.Language, result.Language);
            Assert.Equal("La la", result.LanguageDescription);
            Assert.Equal(data.PageCount, result.PageCount);
            Assert.Equal(data.AttachmentDescription, result.AttachmentDescription);
        }

        [Fact]
        public async Task UpdateThrowsExceptionOnInvalidData()
        {
            var f = new AttachmentMaintenance(Db);
            await Assert.ThrowsAsync<ArgumentNullException>(() => f.UpdateAttachment(null));
        }

        [Fact]
        public async Task DeleteAttachment()
        {
            new Activity {Id = 1, Attachments = {new ActivityAttachment {ActivityId = 1, SequenceNo = 1}.In(Db),new ActivityAttachment {ActivityId = 1, SequenceNo = 2}.In(Db)}}.In(Db);
            var f = new AttachmentMaintenance(Db);

            var result = await f.DeleteAttachment(new ActivityAttachmentModel {ActivityId = 1, SequenceNo = 1});
            Assert.True(result);

            var totalRemainingAttachments = Db.Set<Activity>().Include(_ => _.Attachments).Count();
            Assert.Equal(1, totalRemainingAttachments);
        }

        [Fact]
        public async Task DeleteReturnsIfNoDataFound()
        {
            var f = new AttachmentMaintenance(Db);
            Assert.False(await f.DeleteAttachment(new ActivityAttachmentModel {ActivityId = 1, SequenceNo = 1}));
        }
    }
}