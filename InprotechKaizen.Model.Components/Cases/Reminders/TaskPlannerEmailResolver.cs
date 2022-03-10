using System.Collections.Generic;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;

namespace InprotechKaizen.Model.Components.Cases.Reminders
{
    public interface ITaskPlannerEmailResolver
    {
        string Resolve(string taskPlannerRowKey, string subjectDocItem);
    }

    public class TaskPlannerEmailResolver : ITaskPlannerEmailResolver
    {
        readonly ISecurityContext _securityContext;
        readonly IDocItemRunner _docItemRunner;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public TaskPlannerEmailResolver(ISecurityContext securityContext, IDocItemRunner docItemRunner, IPreferredCultureResolver preferredCultureResolver)
        {
            _securityContext = securityContext;
            _docItemRunner = docItemRunner;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public string Resolve(string taskPlannerRowKey, string docItem)
        {
            var keys = taskPlannerRowKey.Split('^');
            var parameters = new Dictionary<string, object>
            {
                { "psEntryPoint", keys[0] },
                { "pnEventOrAlertId", keys[1] },
                { "pnUserIdentityId", _securityContext.User.Id },
                { "psCulture", _preferredCultureResolver.Resolve() }
            };
            if (!string.IsNullOrWhiteSpace(keys[2])) parameters.Add("pnEmployeeReminderId", keys[2]);

            return _docItemRunner.Run(docItem, parameters).ScalarValue<string>();
        }

    }
}
