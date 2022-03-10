using System.Xml.Linq;
using InprotechKaizen.Model;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{

    public class RemindersTopicBuilder : ITaskPlannerTopicBuilder
    {
        public TaskPlannerSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new TaskPlannerSavedSearch.Topic("reminders");
            var formData = new RemindersSection();

            formData.ReminderMessage = new ReminderFormData
            {
                Operator = GetReminderMessageOperator(filterCriteria),
                Value = GetReminderMessageValue(filterCriteria)
            };
            if (filterCriteria.Element("IsReminderOnHold") != null)
            {
                formData.IsOnHold = filterCriteria.GetXPathBooleanValue("IsReminderOnHold");
                formData.IsNotOnHold = !filterCriteria.GetXPathBooleanValue("IsReminderOnHold");

            }
            if (filterCriteria.Element("IsReminderRead") != null)
            {
                formData.IsRead = filterCriteria.GetXPathBooleanValue("IsReminderRead");
                formData.IsNotRead = !filterCriteria.GetXPathBooleanValue("IsReminderRead");
            }
            topic.FormData = formData;
            return topic;
        }

        static string GetReminderMessageOperator(XElement filterCriteria)
        {
            var Operator = filterCriteria.Element("ReminderMessage")?.Attribute("Operator")?.Value;
            return Operator ?? filterCriteria.GetAttributeOperatorValue("ReminderMessage", "Operator", Operators.StartsWith);
        }

        dynamic GetReminderMessageValue(XElement filterCriteria)
        {
            if (filterCriteria.Element("ReminderMessage") == null) return null;
            var msg = filterCriteria.GetStringValue("ReminderMessage");
            return msg;
        }
    }
    public class RemindersSection
    {
        public RemindersSection()
        {
            this.IsOnHold = true;
            this.IsNotOnHold = true;
            this.IsRead = true;
            this.IsNotRead = true;
        }
        public ReminderFormData ReminderMessage { get; set; }
        public bool IsOnHold { get; set; }
        public bool IsNotOnHold { get; set; }
        public bool IsRead { get; set; }
        public bool IsNotRead { get; set; }
    }
    public class ReminderFormData
    {
        public string Operator { get; set; }
        public dynamic Value { get; set; }
    }
}
