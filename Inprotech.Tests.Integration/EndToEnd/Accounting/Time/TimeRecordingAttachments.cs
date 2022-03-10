using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingAttachments : IntegrationTest
    {
        dynamic AddData()
        {
            return DbSetup.Do<dynamic>(setup =>
            {
                var today = DateTime.Now.Date;

                var staffName = new NameBuilder(setup.DbContext).CreateStaff();
                var userSetup = new Users(setup.DbContext) {Name = staffName}.WithSubjectPermission(ApplicationSubject.Attachments)
                                                                             .WithPermission(ApplicationTask.MaintainTimeViaTimeRecording)
                                                                             .WithPermission(ApplicationTask.AccessDocumentsfromDms);
                var user = userSetup.Create(staffName.FirstName, staffName);

                var wipActivity = new WipTemplateBuilder(setup.DbContext).Create("E2E");

                var @case = new CaseBuilder(setup.DbContext).Create("TimeRecording-" + Fixture.AlphaNumericString(5), null, user.Username);
                new DiaryBuilder(setup.DbContext).Create(user.NameId, 2, today.AddHours(11), @case.Id, null, wipActivity.WipCode, "short-narrative" + Fixture.String(254), "note2" + Fixture.String(249), null, 100, null, null);

                var tableCodeId = setup.DbContext.Set<TableCode>().Max(_ => _.Id) + 1;
                var tcActivityType = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityType, "tmpTableCodeActivityType");
                var tcActivityCategory = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityCategory, "tmpTableCodeActivityCategory");

                setup.DbContext.Set<TableCode>().Add(tcActivityType);
                setup.DbContext.Set<TableCode>().Add(tcActivityCategory);

                var lastSequence = setup.DbContext.Set<LastInternalCode>().SingleOrDefault(_ => _.TableName == KnownInternalCodeTable.Activity) ?? new LastInternalCode(KnownInternalCodeTable.Activity) {InternalSequence = 0};
                var activityId = lastSequence.InternalSequence + 1;
                lastSequence.InternalSequence++;
                var activity = setup.Insert(new Activity(activityId, "summary", tcActivityCategory, tcActivityType)
                {
                    CaseId = @case.Id,
                });

                var attachment = setup.Insert(new ActivityAttachment(activity.Id, 0) {AttachmentName = "abcName", FileName = "file1.pdf", AttachmentType = null, PublicFlag = 0m});

                return new
                {
                    User = user,
                    Case = @case,
                    Attachment = attachment
                };
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewingTimeEntryList(BrowserType browserType)
        {
            var data = AddData();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", data.User.Username, data.User.Password);

            var page = new TimeRecordingPage(driver);
            var timesheet = page.Timesheet;

            timesheet.OpenTaskMenuFor(0);
            page.ContextMenu.ViewCaseAttachments();

            var attachments = new AttachmentListObj(driver);
            Assert.AreEqual(1, attachments.AttachmentsGrid.Rows.Count);
            Assert.AreEqual(data.Attachment.AttachmentName, attachments.AttachmentName(0));
            attachments.Close();
        }
    }
}