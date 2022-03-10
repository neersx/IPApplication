using System;
using System.Collections.Generic;
using System.Reflection;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Infrastructure.ResponseShaping.Picklists
{
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Method)]
    public class PicklistDataNameAttribute : Attribute
    {
        public string Name { get; private set; }

        public PicklistDataNameAttribute(string name)
        {
            Name = name;
        }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Method)]
    public class PicklistMaintainabilityActionsAttribute : Attribute
    {
        public PicklistMaintainabilityActionsAttribute(ApplicationTask task = ApplicationTask.NotDefined, bool allowAdd = true, bool allowEdit = true, bool allowDelete = true, bool allowDuplicate = true)
        {
            AllowAdd = allowAdd;
            AllowEdit = allowEdit;
            AllowDelete = allowDelete;
            AllowDuplicate = allowDuplicate;
            Task = task;
        }

        public bool AllowAdd { get; set; }
        public bool AllowEdit { get; set; }
        public bool AllowDelete { get; set; }
        public bool AllowDuplicate { get; set; }
        public ApplicationTask Task { get; private set; }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Method)]
    public class PicklistPayloadAttribute : Attribute
    {
        public string Name => ResolveFromType(PayloadType);

        public string PluralName
        {
            get
            {
                var typeName = ResolveFromType(PayloadType);
                return Pluralize(typeName);
            }
        }

        public Type PayloadType { get; private set; }

        public ApplicationTask Task { get; private set; }

        public List<ApplicationTask> Tasks { get; set; } = new List<ApplicationTask>();

        public bool? DuplicateFromServer { get; set; }

        public PicklistPayloadAttribute(Type payloadType, ApplicationTask task = ApplicationTask.NotDefined, bool duplicateFromServer = false)
        {
            PayloadType = payloadType;
            Task = task;
            DuplicateFromServer = duplicateFromServer;
        }
        
        public PicklistPayloadAttribute(Type type, ApplicationTask task1, ApplicationTask task2, bool duplicateFromServer = false)
        {
            PayloadType = type;
            Tasks.Add(task1);
            Tasks.Add(task2);
            DuplicateFromServer = duplicateFromServer;
        }

        static string ResolveFromType(Type t)
        {
            var attribute = t.GetCustomAttribute<PicklistDataNameAttribute>();
            return attribute == null ? t.Name : attribute.Name;
        }

        static string Pluralize(string name)
        {
            return name + "s";
        }
    }
    
}