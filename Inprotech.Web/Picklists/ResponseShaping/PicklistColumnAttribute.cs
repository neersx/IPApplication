using System;

namespace Inprotech.Web.Picklists.ResponseShaping
{
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
    public class PicklistColumnAttribute : Attribute
    {
        public readonly bool Sortable;
        public readonly bool Filterable;
        public readonly bool Menu;
        public string FilterType { get; set; }
        public string FilterApi { get; set; }
        public readonly bool HideByDefault;

        public PicklistColumnAttribute(bool sortable = true, bool filterable = false, string filterApi = null, string filterType = FilterTypes.Default, bool menu = false, bool hideByDefault = false)
        {
            Sortable = sortable;
            Filterable = filterable;
            Menu = menu;
            FilterApi = filterApi;
            FilterType = filterType;
            HideByDefault = hideByDefault;
        }
        
    }

    public static class FilterTypes
    {
        public const string Default = "";
        public const string Text = "text";
        public const string Date = "date";
        public const string Object = "object";
    }
}
