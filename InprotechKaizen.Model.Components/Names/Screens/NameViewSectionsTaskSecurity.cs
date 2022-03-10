using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Components.Names.Screens
{
    public interface INameViewSectionsTaskSecurity
    {
        ICollection<NameViewSection> Filter(ICollection<NameViewSection> sections);
    }

    internal class NameViewSectionsTaskSecurity : INameViewSectionsTaskSecurity
    {
        readonly Dictionary<string, ApplicationTask> _map = new Dictionary<string, ApplicationTask>
        {
            {KnownCaseScreenTopics.Dms, ApplicationTask.AccessDocumentsfromDms}
        };

        readonly ITaskSecurityProvider _taskSecurityProvider;

        public NameViewSectionsTaskSecurity(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        public ICollection<NameViewSection> Filter(ICollection<NameViewSection> sections)
        {
            var noAccess = new List<string>();
            foreach (var nameViewSection in sections)
            {
                if (_map.ContainsKey(nameViewSection.TopicName) && !_taskSecurityProvider.HasAccessTo(_map[nameViewSection.TopicName]))
                {
                    noAccess.Add(nameViewSection.TopicName);
                }
            }

            return sections.Where(_ => !noAccess.Contains(_.TopicName)).ToList();
        }
    }
}