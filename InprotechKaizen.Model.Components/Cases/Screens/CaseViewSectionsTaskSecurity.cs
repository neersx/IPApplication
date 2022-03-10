using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Components.Cases.Screens
{
    public interface ICaseViewSectionsTaskSecurity
    {
        ICollection<CaseViewSection> Filter(ICollection<CaseViewSection> sections);
    }

    internal class CaseViewSectionsTaskSecurity : ICaseViewSectionsTaskSecurity
    {
        readonly Dictionary<string, ApplicationTask> _map = new Dictionary<string, ApplicationTask>
        {
            {KnownCaseScreenTopics.Dms, ApplicationTask.AccessDocumentsfromDms}
        };

        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseViewSectionsTaskSecurity(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        public ICollection<CaseViewSection> Filter(ICollection<CaseViewSection> sections)
        {
            var noAccess = new List<string>();
            foreach (var caseViewSection in sections)
            {
                if (_map.ContainsKey(caseViewSection.TopicName) && !_taskSecurityProvider.HasAccessTo(_map[caseViewSection.TopicName]))
                {
                    noAccess.Add(caseViewSection.TopicName);
                }
            }

            return sections.Where(_ => !noAccess.Contains(_.TopicName)).ToList();
        }
    }
}