using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Picklists.ResponseShaping
{
    public class Maintainability : IPicklistPayloadData
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public Maintainability(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider ?? throw new ArgumentNullException(nameof(taskSecurityProvider));
        }

        public void Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            var t = actionExecutedContext.PicklistPayloadAttribute();
            if (t.Tasks.Any())
            {
                enrichment.Add("Maintainability", ResolveMultiple(t.Tasks));
                return;
            }

            var m = Resolve(t.Task);
            enrichment.Add("Maintainability", m);
        }

        MaintainabilityDetail Resolve(ApplicationTask? task = null)
        {
            if (task == null || task == ApplicationTask.NotDefined) return new MaintainabilityDetail();

            if (task == ApplicationTask.AllowedAccessAlways)
            {
                return new MaintainabilityDetail
                {
                    CanAdd = true,
                    CanDelete = true,
                    CanEdit = true
                };
            }

            var t = _taskSecurityProvider.ListAvailableTasks().FirstOrDefault(f => f.TaskId == (short)task);
            if (t == null) return new MaintainabilityDetail();

            return new MaintainabilityDetail
            {
                CanAdd = t.CanExecute || t.CanInsert,
                CanEdit = t.CanExecute || t.CanUpdate,
                CanDelete = t.CanExecute || t.CanDelete
            };
        }

        MaintainabilityDetail ResolveMultiple(IEnumerable<ApplicationTask> tasks)
        {
            var m = new MaintainabilityDetail();
            foreach (var t in tasks)
            {
                var p = _taskSecurityProvider.ListAvailableTasks().FirstOrDefault(f => f.TaskId == (short)t);
                if (p == null) continue;
                m.CanAdd = m.CanAdd || (p.CanExecute || p.CanInsert);
                m.CanEdit = m.CanEdit || (p.CanExecute || p.CanUpdate);
                m.CanDelete = m.CanDelete || (p.CanExecute || p.CanDelete);
            }
            return m;
        }
    }

    public class MaintainabilityDetail
    {
        public bool CanAdd { get; set; }

        public bool CanEdit { get; set; }

        public bool CanDelete { get; set; }
       
    }
    
}