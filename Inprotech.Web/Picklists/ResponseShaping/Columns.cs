using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Reflection;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseShaping.Picklists;

namespace Inprotech.Web.Picklists.ResponseShaping
{
    public class Columns : IPicklistPayloadData
    {
        public void Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            var payloadType = actionExecutedContext.PicklistPayloadAttribute().PayloadType;
            
            var columns = payloadType
                .GetProperties()
                .Select(property => new Column
                                    {
                                        Key = property.IsKey(),
                                        Code = property.IsCode(),
                                        Description = property.IsDescription(),
                                        DisplayOrder = property.DisplayOrder(),
                                        Title = property.ResourceId(),
                                        Field = property.FieldName(),
                                        Hidden = property.IsHidden(),
                                        PreventCopy = property.PreventCopy(),
                                        Sortable = property.Sortable(),
                                        Filterable = property.Filterable(),
                                        FilterApi = property.FilterApi(),
                                        FilterType = property.FilterType(),
                                        Menu = property.Menu(),
                                        HideByDefault = property.HideByDefault(),
                                        DataType = property.DataType()
                                    }).OrderBy(c => c.DisplayOrder.GetValueOrDefault(int.MaxValue));

            enrichment.Add("Columns", columns);
        }
    }

    public static class ColumnsExtensions
    {
        public static bool? IsKey(this PropertyInfo p)
        {
            if (p.GetCustomAttribute<PicklistKeyAttribute>() != null)
                return true;

            return null;
        }

        public static bool? IsCode(this PropertyInfo p)
        {
            if (p.GetCustomAttribute<PicklistCodeAttribute>() != null)
                return true;

            return null;
        }

        public static bool? IsDescription(this PropertyInfo p)
        {
            if (p.GetCustomAttribute<PicklistDescriptionAttribute>() != null)
                return true;

            return null;
        }

        public static int? DisplayOrder(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<DisplayOrderAttribute>();

            return col?.Order;
        }

        public static bool? IsHidden(this PropertyInfo p)
        {
            return !IsDescription(p).GetValueOrDefault() && !p.GetCustomAttributes<DisplayNameAttribute>().Any();
        }

        public static string FieldName(this PropertyInfo p)
        {
            return p.Name.ToCamelCase();
        }

        public static string ResourceId(this PropertyInfo p)
        {
            if (IsHidden(p).GetValueOrDefault() || p.ReflectedType == null)
            {
                return null;
            }

            var attribute = p.GetCustomAttribute<DisplayNameAttribute>() ??
                            p.GetCustomAttribute<PicklistDescriptionAttribute>();

            return $"picklist.{p.ReflectedType.Name.ToLower()}.{attribute.DisplayName}";
        }

        public static bool? PreventCopy(this PropertyInfo p)
        {
            if (p.GetCustomAttribute<PreventCopyAttribute>() != null)
                return true;

            return null;
        }

        public static bool Sortable(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<PicklistColumnAttribute>();
            
            return col == null || col.Sortable;
        }

        public static bool Filterable(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<PicklistColumnAttribute>();

            return col?.Filterable ?? false;
        }

        public static string FilterApi(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<PicklistColumnAttribute>();
            return col == null ? string.Empty : col.FilterApi;
        }

        public static string FilterType(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<PicklistColumnAttribute>();
            return col == null ? string.Empty : col.FilterType;
        }

        public static bool Menu(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<PicklistColumnAttribute>();

            return col?.Menu ?? false;
        }

        public static bool HideByDefault(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<PicklistColumnAttribute>();

            return col?.HideByDefault ?? false;
        }

        public static string DataType(this PropertyInfo p)
        {
            var col = p.GetCustomAttribute<DataTypeAttribute>();

            return col?.CustomDataType;
        }
    }

    public class Column
    {
        public string Title { get; set; }

        public string Field { get; set; }

        public bool? Hidden { get; set; }

        public bool? Key { get; set; }

        public bool? Code { get; set; }

        public bool? Description { get; set; }

        public int? DisplayOrder { get; set; }

        public bool? PreventCopy { get; set; }

        public bool Sortable { get; set; }

        public bool Highlight { get; set; }

        public bool Filterable { get; set; }

        public string FilterApi { get; set; }
        public string FilterType { get; set; }

        public bool Menu { get; set; }

        public bool HideByDefault { get; set; }

        public string DataType { get; set; }
    }
}