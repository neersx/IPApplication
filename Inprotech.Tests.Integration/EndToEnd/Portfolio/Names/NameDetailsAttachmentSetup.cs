using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Names
{
    public class NameDetailsAttachmentSetup : DbSetup
    {
        public bool IsPoliceImmediately
        {
            get => DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PoliceImmediately).BooleanValue ?? false;
            set
            {
                DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PoliceImmediately).BooleanValue = value;
                DbContext.SaveChanges();
            }
        }

        public bool EventLinksToWorkflowWizard
        {
            get => DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EventLinktoWorkflowAllowed).BooleanValue ?? false;
            set
            {
                DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EventLinktoWorkflowAllowed).BooleanValue = value;
                DbContext.SaveChanges();
            }
        }

        public void ResetDataValidations(List<DataValidation> dataValidations)
        {
            foreach (var dataValidation in dataValidations) DbContext.Set<DataValidation>().Single(_ => _.Id == dataValidation.Id).InUseFlag = true;
            DbContext.SaveChanges();
        }

        public (int NameId, string displayName, Activity activity, ActivityAttachment activityAttachment, dynamic newOption) AttachmentSetup()
        {
            var name = new NameBuilder(DbContext).CreateClientIndividual("e2eAttach");
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

            var activity = Insert(new Activity(activityId, "summary", tcActivityCategory, tcActivityType)
            {
                ContactNameId = name.Id
            });
            var attachment = Insert(new ActivityAttachment(activity.Id, 0) {AttachmentName = "abcName", FileName = @"\\Server1\path1\file1.pdf", Language = tcLanguage, AttachmentType = null, PublicFlag = 0m});

            DbContext.SaveChanges();
            return (name.Id, "e2eAttach", activity, attachment, new {ActivityType2 = tcActivityType2.Name, ActivityCategory2 = tcActivityCategory2.Name}) ;
        }

        public int CountAttachments(int nameId)
        {
            var activitySet = DbContext.Set<Activity>().Where(_ => _.ContactNameId == nameId);
            var attachmentSet = DbContext.Set<ActivityAttachment>();

            return activitySet.Join(attachmentSet, activity => activity.Id, attachment => attachment.ActivityId, (activity, attachment) => attachment)
                              .Count();
        }
    }
}