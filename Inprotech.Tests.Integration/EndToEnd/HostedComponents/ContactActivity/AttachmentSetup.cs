using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.ContactActivity
{
    public static class AttachmentSetup
    {
        public static (string folder, string file) Setup()
        {
            var doc2 = StorageServiceSetup.MakeAvailable("doc.docx", "Docs");
            var settings = new AttachmentSetting
            {
                IsRestricted = true,
                NetworkDrives = new AttachmentSetting.NetworkDrive[0],
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf,docx", Name = "Documents-Docs", Path = doc2.folder}
                }
            };

            using (var db = new AttachmentsSettingsDb())
            {
                db.Setup(settings);
            }

            return doc2;
        }
    }
    public class NewAttachment : DbSetup
    {
        public (Activity activity, ActivityAttachment activityAttachment, dynamic newOption) Make()
        {
            var tableCodeId = DbContext.Set<TableCode>().Max(_ => _.Id) + 1;
            var tcActivityType = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityType, "tmpTableCodeActivityType");
            var tcActivityType2 = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityType, "tmpTableCodeActivityType2");
            var tcActivityCategory = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityCategory, "tmpTableCodeActivityCategory");
            var tcActivityCategory2 = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityCategory, "tmpTableCodeActivityCategory2");
            var tcAttachmentType = new TableCode(tableCodeId++, (short) TableTypes.AttachmentType, "tmpTableCodeAttachmentType");
            var tcLanguage = new TableCode(tableCodeId, (short) TableTypes.Language, "tmpTableCodeLanguage");

            DbContext.Set<TableCode>().Add(tcActivityType);
            DbContext.Set<TableCode>().Add(tcActivityType2);
            DbContext.Set<TableCode>().Add(tcActivityCategory);
            DbContext.Set<TableCode>().Add(tcActivityCategory2);
            DbContext.Set<TableCode>().Add(tcAttachmentType);
            DbContext.Set<TableCode>().Add(tcLanguage);

            var lastSequence = DbContext.Set<LastInternalCode>().SingleOrDefault(_ => _.TableName == KnownInternalCodeTable.Activity) ?? new LastInternalCode( KnownInternalCodeTable.Activity){InternalSequence = 0};
            var activityId = lastSequence.InternalSequence + 1;
            lastSequence.InternalSequence++;
            DbContext.SaveChanges();

            var activity = Insert(new Activity(activityId, "summary", tcActivityCategory, tcActivityType));
            var attachment = Insert(new ActivityAttachment(activity.Id, 0) {AttachmentName = "abcName", FileName = @"\\Server1\path1\file1.pdf", Language = tcLanguage, AttachmentType = null, PublicFlag = 0m});

            return (activity, attachment, new {ActivityType2 = tcActivityType2.Name, ActivityCategory2 = tcActivityCategory2.Name, language = tcLanguage.Name, attachmentType = tcAttachmentType.Name});
        }
    }
}