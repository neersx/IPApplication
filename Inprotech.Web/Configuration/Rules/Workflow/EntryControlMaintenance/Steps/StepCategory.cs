using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Configuration.Screens;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class StepCategory : ICloneable
    {
        public StepCategory(string code, dynamic value = null)
        {
            CategoryCode = code;
            CategoryValue = value;
        }

        public string CategoryCode { get; set; }

        public dynamic CategoryValue { get; set; }

        public object Clone()
        {
            return (StepCategory) MemberwiseClone();
        }
    }

    public static class StepCategoryExtension
    {
        static readonly Dictionary<string, string> KeyMap = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase)
                                                             {
                                                                 {"checklist", "key"},
                                                                 {"countryFlag", "key"},
                                                                 {"nameGroup", "key"},
                                                                 {"textType", "key"},
                                                                 {"nameType", "code"},
                                                                 {"action", "code"},
                                                                 {"relationship", "key"},
                                                                 {"numberType", "key"}
                                                             };

        public static string FilterName(this StepCategory category)
        {
            return category == null ? null : StepCategoryCodes.FilterName(category.CategoryCode);
        }

        public static string FilterValue(this StepCategory category)
        {
            if (category == null || category.CategoryValue == null)
                return null;

            var str = category.CategoryValue as string;
            if (str != null) return str;

            var keyToUse = KeyMap.Get(category.CategoryCode) ?? "key";

            return (string) JObject.FromObject(category.CategoryValue)[keyToUse];
        }

        public static TopicControlFilter ConvertToFilter(this StepCategory category)
        {
            return new TopicControlFilter(category.FilterName(), category.FilterValue());
        }
    }
}