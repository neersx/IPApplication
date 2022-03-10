using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Security
{
    public interface IAuthorizeCriteriaPurposeCodeTaskSecurity
    {
        bool Authorize(string purposeCode);
    }

    public class AuthorizeCriteriaPurposeCodeTaskSecurity : IAuthorizeCriteriaPurposeCodeTaskSecurity
    {
        internal static class CriteriaPurposeCodes
        {
            public const string EventsAndEntries = "E";
            public const string WindowControl = "W";
            public const string CaseLinks = "L";
            public const string Checklists = "C";
            public const string SanityCheck = "S";
        }

        ITaskSecurityProvider _taskSecurityProvider;

        public AuthorizeCriteriaPurposeCodeTaskSecurity(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        IEnumerable<ApplicationTask> Resolve(string purposeCode)
        {
            switch (purposeCode)
            {
                case CriteriaPurposeCodes.EventsAndEntries:
                    return new[] {ApplicationTask.MaintainWorkflowRules, ApplicationTask.MaintainWorkflowRulesProtected};
                case CriteriaPurposeCodes.WindowControl:
                    return new[] {ApplicationTask.MaintainRules, ApplicationTask.MaintainCpassRules};
                case CriteriaPurposeCodes.Checklists:
                    return new[] {ApplicationTask.MaintainRules, ApplicationTask.MaintainCpassRules, ApplicationTask.MaintainQuestion};
                case CriteriaPurposeCodes.SanityCheck:
                    return new[] {ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTask.MaintainSanityCheckRulesForNames};
            }

            return null;
        }

        public bool Authorize(string purposeCode)
        {
            var tasks = Resolve(purposeCode);
            if (tasks != null)
            {
                return tasks.Any(_taskSecurityProvider.HasAccessTo);
            }

            return false;
        }
    }
}