using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.TaskPlanner
{
    public class TaskPlannerFilterableColumnsMap : IFilterableColumnsMap
    {
        public TaskPlannerFilterableColumnsMap()
        {
            Columns = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase)
            {
                {"CaseReference", "CaseKey"},
                {"Owner", "OwnerKey"},
                {"Signatory", "SignatoryKey"},
                {"StaffMember", "StaffMemberKey"},
                {"EventDescription", "EventKey"},
                {"CaseTypeDescription", "CaseTypeKey"},
                {"PropertyTypeDescription", "PropertyTypeKey"},
                {"CountryName", "CountryKey"},
                {"ReminderFor", "ReminderForNameKey"},
                {"ImportanceDescription", "ImportanceLevelKey"},
                {"DueDateResponsibility", "DueDateResponsibilityNameKey"},
                {"Instructor", "InstructorKey"},
                {"StatusDescription", "StatusKey"},
                {"ShortTitle", "ShortTitle"}
            });

            XmlCriteriaFields = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase)
            {
                {"CaseKey", "CaseKeys"},
                {"OwnerKey", "OwnerKeys"},
                {"SignatoryKey", "SignatoryKeys"},
                {"StaffMemberKey", "StaffMemberKeys"},
                {"EventKey", "EventKeys"},
                {"CaseTypeKey", "CaseTypeKeys"},
                {"PropertyTypeKey", "PropertyTypeKeys"},
                {"CountryKey", "CountryKeys"},
                {"ReminderForNameKey", "ReminderForNameKeys"},
                {"ImportanceLevelKey", "ImportanceLevelKeys"},
                {"DueDateResponsibilityNameKey", "DueDateResponsibilityNameKeys"},
                {"InstructorKey", "InstructorKeys"},
                {"StatusKey", "StatusKeys"},
                {"ShortTitle", "ShortTitles"}
            });
        }

        public IReadOnlyDictionary<string, string> Columns { get; }

        public IReadOnlyDictionary<string, string> XmlCriteriaFields { get; }
    }
}