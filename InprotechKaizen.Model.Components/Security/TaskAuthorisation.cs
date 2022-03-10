using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public class TaskAuthorisation : ITaskAuthorisation
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public TaskAuthorisation(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        public bool Authorize(
            IEnumerable<RequiresAccessToAttribute> actionAttributes,
            IEnumerable<RequiresAccessToAttribute> controllerAttributes)
        {
            if(actionAttributes == null) throw new ArgumentNullException(nameof(actionAttributes));
            if(controllerAttributes == null) throw new ArgumentNullException(nameof(controllerAttributes));

            var actionAttributesArray = actionAttributes.ToArray();
            var controllerAttributesArray = controllerAttributes.ToArray();

            if(!actionAttributesArray.Any() && !controllerAttributesArray.Any())
                return true;

            var commonAttributes = actionAttributesArray.Join(
                                                              controllerAttributesArray,
                                                              o => o.Task,
                                                              i => i.Task,
                                                              (i, o) => o);

            var attributes =
                actionAttributesArray.Concat(
                                             controllerAttributesArray.Where(
                                                                             a =>
                                                                             commonAttributes.All(
                                                                                                  ca =>
                                                                                                  ca.Task != a.Task)));

            var allowedTasks = _taskSecurityProvider.ListAvailableTasks();

            var requiresAccessToAttributes = attributes as RequiresAccessToAttribute[] ?? attributes.ToArray();
            return requiresAccessToAttributes.All(_ => _ is RequiresAccessToAllOfAttribute) 
                ? requiresAccessToAttributes.All(a => allowedTasks.Any(t => t.TaskId == (int)a.Task && HasAccess(t, a)))
                : requiresAccessToAttributes.Any(a => allowedTasks.Any(t => t.TaskId == (int)a.Task && HasAccess(t, a)));
        }

        static bool HasAccess(ValidSecurityTask task, RequiresAccessToAttribute attribute)
        {
            var hasAccess = true;

            hasAccess &= (attribute.Level & ApplicationTaskAccessLevel.Create) != ApplicationTaskAccessLevel.Create ||
                         task.CanInsert;
            hasAccess &= (attribute.Level & ApplicationTaskAccessLevel.Modify) != ApplicationTaskAccessLevel.Modify ||
                         task.CanUpdate;
            hasAccess &= (attribute.Level & ApplicationTaskAccessLevel.Delete) != ApplicationTaskAccessLevel.Delete ||
                         task.CanDelete;
            hasAccess &= (attribute.Level & ApplicationTaskAccessLevel.Execute) != ApplicationTaskAccessLevel.Execute ||
                         task.CanExecute;

            return hasAccess;
        }
    }
}