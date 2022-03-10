using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    public class CaseDetailsAttachmentSetup : DbSetup
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

        public (int CaseId, string CaseIrn, Activity activity, ActivityAttachment activityAttachment, CaseEvent caseEvent, ValidEvent validEvent, dynamic newOption) AttachmentSetup(bool withEvents = false)
        {
            var @case = new CaseBuilder(DbContext).Create();
            var tableCodeId = DbContext.Set<TableCode>().Max(_ => _.Id) + 1;
            var tcActivityType = new TableCode(tableCodeId++, (short)TableTypes.ContactActivityType, "tmpTableCodeActivityType");
            var tcActivityType2 = new TableCode(tableCodeId++, (short)TableTypes.ContactActivityType, "tmpTableCodeActivityType2");
            var tcActivityCategory = new TableCode(tableCodeId++, (short)TableTypes.ContactActivityCategory, "tmpTableCodeActivityCategory");
            var tcActivityCategory2 = new TableCode(tableCodeId++, (short)TableTypes.ContactActivityCategory, "tmpTableCodeActivityCategory2");
            var tcAttachmentType = new TableCode(tableCodeId++, (short)TableTypes.AttachmentType, "tmpTableCodeAttachmentType");
            var tcLanguage = new TableCode(tableCodeId, (short)TableTypes.Language, "tmpTableCodeLanguage");

            DbContext.Set<TableCode>().Add(tcActivityType);
            DbContext.Set<TableCode>().Add(tcActivityType2);
            DbContext.Set<TableCode>().Add(tcActivityCategory);
            DbContext.Set<TableCode>().Add(tcActivityCategory2);
            DbContext.Set<TableCode>().Add(tcAttachmentType);
            DbContext.Set<TableCode>().Add(tcLanguage);

            new ScreenCriteriaBuilder(DbContext).Create(@case, out _).WithTopicControl(withEvents ? KnownCaseScreenTopics.Events : KnownCaseScreenTopics.Actions);

            var criteria = new CriteriaBuilder(DbContext).Create();

            criteria.RuleInUse = 1;
            criteria.CaseTypeId = @case.TypeId;

            var importanceLevel = Insert(new Importance("91", Fixture.Prefix(Fixture.String(3))));
            var action = InsertWithNewId(new Action(Fixture.Prefix("action"), importanceLevel));
            Insert(new OpenAction(action, @case, 1, null, criteria, true));
            Insert(new ValidAction("ABC", action, @case.Country, @case.Type, @case.PropertyType) { DisplaySequence = 0 });
            var caseEvent = new EventBuilder(DbContext).Create();
            var validEvent = new ValidEventBuilder(DbContext).Create(criteria, caseEvent, importance: importanceLevel);
            var ce1 = Insert(new CaseEvent(@case.Id, caseEvent.Id, 1) { EventDueDate = Fixture.Today(), IsOccurredFlag = 0, CreatedByCriteriaKey = criteria.Id });

            var lastSequence = DbContext.Set<LastInternalCode>().SingleOrDefault(_ => _.TableName == KnownInternalCodeTable.Activity) ?? new LastInternalCode(KnownInternalCodeTable.Activity) { InternalSequence = 0 };
            var activityId = lastSequence.InternalSequence + 1;
            lastSequence.InternalSequence++;
            var activity = Insert(new Activity(activityId, "summary", tcActivityCategory, tcActivityType)
            {
                CaseId = @case.Id,
                Cycle = ce1.Cycle,
                EventId = caseEvent.Id
            });
            var attachment = Insert(new ActivityAttachment(activity.Id, 0) { AttachmentName = "abcName", FileName = @"\\Server1\path1\file1.pdf", Language = tcLanguage, AttachmentType = null, PublicFlag = 0m });

            DbContext.SaveChanges();
            return (@case.Id, @case.Irn, activity, attachment, ce1, validEvent, new { ActivityType2 = tcActivityType2.Name, ActivityCategory2 = tcActivityCategory2.Name, language = tcLanguage.Name, attachmentType = tcAttachmentType.Name });
        }

        public int CountAttachments(int caseId)
        {
            var activitySet = DbContext.Set<Activity>().Where(_ => _.CaseId == caseId);
            var attachmentSet = DbContext.Set<ActivityAttachment>();

            return activitySet.Join(attachmentSet, activity => activity.Id, attachment => attachment.ActivityId, (activity, attachment) => attachment)
                              .Count();
        }
    }
}