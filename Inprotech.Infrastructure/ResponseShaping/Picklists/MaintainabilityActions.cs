using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Infrastructure.ResponseShaping.Picklists
{
    public class MaintainabilityActions : IPicklistPayloadData
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public MaintainabilityActions(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider ?? throw new ArgumentNullException(nameof(taskSecurityProvider));
        }

        public void Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            var t = actionExecutedContext.PicklistMaintainabilityActionsAttribute();
             
            var ma = Resolve(t);
            enrichment.Add("MaintainabilityActions", ma);
        }

        dynamic Resolve(PicklistMaintainabilityActionsAttribute attribute)
        {
            var allowView = true;
            var task = attribute?.Task;
            if (task != null && task != ApplicationTask.NotDefined)
            {
                var t = _taskSecurityProvider.ListAvailableTasks().FirstOrDefault(f => f.TaskId == (short) task);
                if (t == null)
                    allowView = false;
            }
            if (attribute == null)
            {
                return new
                {
                    AllowAdd = true,
                    AllowEdit = true,
                    AllowDelete = true,
                    AllowDuplicate = true,
                    AllowView = true
                };
            }

            return new
            {
                attribute.AllowAdd,
                attribute.AllowEdit,
                attribute.AllowDelete,
                attribute.AllowDuplicate,
                allowView
            };
        }
    }
}
