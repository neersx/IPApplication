using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules.Models;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;

namespace Inprotech.Web.Cases.EventRules
{
    public interface IRemindersService
    {
        IEnumerable<RemindersInfo> GetReminders(IEnumerable<ReminderDetails> details);
    }

    public class RemindersService : IRemindersService
    {
        const string RemindersTranslate = "caseview.eventRules.reminders.";
        readonly IEventRulesHelper _eventRuleHelper;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _translator;

        public RemindersService(
            IPreferredCultureResolver preferredCultureResolver,
            IStaticTranslator translator,
            IEventRulesHelper eventRuleHelper
        )
        {
            _preferredCultureResolver = preferredCultureResolver;
            _translator = translator;
            _eventRuleHelper = eventRuleHelper;
        }

        public IEnumerable<RemindersInfo> GetReminders(IEnumerable<ReminderDetails> details)
        {
            var remindersInfo = new List<RemindersInfo>();
            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();

            foreach (var rem in details)
            {
                var remindersInfoItem = new RemindersInfo();

                var formattedHeading = GetReminderHeading(rem, cultureResolver);
                remindersInfoItem.FormattedDescription = $"{formattedHeading}".MakeSentenceLike();

                var nameTypes = new List<string>();
                if (!string.IsNullOrEmpty(rem.EmployeeNameType)) nameTypes.Add(rem.EmployeeNameType);
                if (!string.IsNullOrEmpty(rem.SignatoryNameType)) nameTypes.Add(rem.SignatoryNameType);
                if (!string.IsNullOrEmpty(rem.InstructorNameType)) nameTypes.Add(rem.InstructorNameType);
                if (rem.CriticalFlag.GetValueOrDefault()) nameTypes.Add(_translator.Translate(RemindersTranslate + "criticalList", cultureResolver));
                if (!string.IsNullOrEmpty(rem.NameType)) nameTypes.Add(rem.NameType);
                if (nameTypes.Count > 0)
                {
                    remindersInfoItem.NameTypes = string.Join(", ", nameTypes.ToArray());
                }

                var names = new List<string>();

                if (!string.IsNullOrEmpty(rem.ReminderName)) names.Add(rem.ReminderName);
                if (!string.IsNullOrEmpty(rem.Relationship)) names.Add(rem.Relationship);

                if (names.Count > 0)
                {
                    remindersInfoItem.Names = string.Join(", ", names.ToArray());
                }

                remindersInfoItem.Subject = rem.EmailSubject;
                remindersInfoItem.MessageInfo = _translator.Translate(RemindersTranslate + (rem.UseBeforeDueDate.GetValueOrDefault() ? "messageBeforeDueDate" : "message"), cultureResolver);
                remindersInfoItem.Message = rem.Message1;
                remindersInfoItem.AlternateMessage = rem.Message2;

                remindersInfo.Add(remindersInfoItem);
            }

            return remindersInfo;
        }

        string GetReminderHeading(ReminderDetails rem, string[] cultureResolver)
        {
            var leadPeriod = !rem.LeadTime.HasValue || rem.LeadTime.GetValueOrDefault() == 0 ? string.Empty :
                _eventRuleHelper.PeriodTypeToLocalizedString(rem.LeadTime, rem.PeriodType, cultureResolver);

            var untilClause = !rem.StopTime.HasValue || rem.StopTime.GetValueOrDefault() == 0 ? string.Empty :
                string.Format(_translator.Translate(RemindersTranslate + "stopLiteral", cultureResolver), _eventRuleHelper.PeriodTypeToLocalizedString(rem.StopTime, rem.StopTimePeriodType, cultureResolver));

            var headingResource = rem.LeadTime.GetValueOrDefault() > 0 ? _translator.Translate(RemindersTranslate + "sendBeforeDueDate", cultureResolver) :
                _translator.Translate(RemindersTranslate + "sendOnDueDate", cultureResolver);

            var repeatClause = !rem.Frequency.HasValue || rem.Frequency.GetValueOrDefault() == 0
                ? string.Empty
                : $"{_translator.Translate(RemindersTranslate + "repeatLiteral", cultureResolver)} {_eventRuleHelper.PeriodTypeToLocalizedString(rem.Frequency, rem.FreqPeriodType, cultureResolver)}";

            return string.Format(headingResource, leadPeriod, repeatClause, untilClause);
        }
    }
}