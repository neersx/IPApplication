using System.Linq;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public static class ListEventViewRuleDetailsCommand
    {
        public static EventViewRuleDetails GetEventRuleDetails(this IDbContext dbContext, int userIdentityId, string culture, int caseId, int eventId, int cycle, string action)
        {
            var details = new EventViewRuleDetails {CaseId = caseId, EventId = eventId, Action = action, Cycle = cycle};
            using (var dbCommand = dbContext.CreateStoredProcedureCommand("apps_CaseEventRuleDetails"))
            {
                dbCommand.Parameters.AddWithValue("pnUserIdentityId", userIdentityId);
                dbCommand.Parameters.AddWithValue("psCulture", culture);
                dbCommand.Parameters.AddWithValue("pnCaseId", caseId);
                dbCommand.Parameters.AddWithValue("pnEventNo", eventId);
                dbCommand.Parameters.AddWithValue("pnCycle", cycle);
                dbCommand.Parameters.AddWithValue("psAction", action);

                using (var reader = dbCommand.ExecuteReader())
                {
                    details.EventControlDetails = reader.MapTo<EventControlDetails>().FirstOrDefault();

                    reader.NextResult();
                    details.DueDateCalculationDetails = reader.MapTo<DueDateCalculationDetails>();

                    reader.NextResult();
                    details.DateComparisonDetails = reader.MapTo<DateComparisonDetails>();

                    reader.NextResult();
                    details.RelatedEventDetails = reader.MapTo<RelatedEventDetails>();

                    reader.NextResult();
                    details.ReminderDetails = reader.MapTo<ReminderDetails>();

                    reader.NextResult();
                    details.DocumentsDetails = reader.MapTo<DocumentsDetails>();

                    reader.NextResult();
                    details.DatesLogicDetails = reader.MapTo<DatesLogicDetails>();

                    return details;
                }
            }
        }
    }
}