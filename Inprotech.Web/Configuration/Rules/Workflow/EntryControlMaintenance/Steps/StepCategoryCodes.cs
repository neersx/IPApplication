using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class StepCategoryCodes
    {
        public const string ChecklistTypeKey = "ChecklistTypeKey";
        public const string CountryFlag = "CountryFlag";
        public const string NameGroupKey = "NameGroupKey";
        public const string TextTypeKey = "TextTypeKey";
        public const string NameTypeKey = "NameTypeKey";
        public const string CreateActionKey = "CreateActionKey";
        public const string CaseRelationKey = "CaseRelationKey";
        public const string NumberTypeKeys = "NumberTypeKeys";

        public static readonly string[] FilterOptional = {"M", "O", "F"};

        static Dictionary<string, string> PickerMap { get; } = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase)
                                                               {
                                                                   {ChecklistTypeKey, "checklist"},
                                                                   {CountryFlag, "designationStage"},
                                                                   {NameGroupKey, "nameTypeGroup"},
                                                                   {TextTypeKey, "textType"},
                                                                   {NameTypeKey, "nameType"},
                                                                   {CreateActionKey, "action"},
                                                                   {CaseRelationKey, "relationship"},
                                                                   {NumberTypeKeys, "numberType"}
                                                               };

        static Dictionary<string, string> FilterNameMap { get; } = PickerMap.ToDictionary(k => k.Value, v => v.Key, StringComparer.InvariantCultureIgnoreCase);

        public static string PickerName(string filterName)
        {
            return PickerMap.Get(filterName);
        }

        public static string FilterName(string pickerName)
        {
            return FilterNameMap.Get(pickerName);
        }
    }
}