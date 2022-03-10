using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Entity.Core.Objects;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;

namespace InprotechKaizen.Model.Components.Translations
{
    static class Utilities
    {
        static readonly IDictionary<Type, string> TypeToKeyColumnName = new ConcurrentDictionary<Type, string>();
        static readonly IDictionary<Type, string> TypeToTableName = new ConcurrentDictionary<Type, string>();
        static readonly IDictionary<Type, PropertyInfo> TypeToKeyProperty = new ConcurrentDictionary<Type, PropertyInfo>();
        static readonly IDictionary<string, string> TypePropertyToColumnName = new ConcurrentDictionary<string, string>();

        public static object GetPropertyValue(object obj, string propertyName)
        {
            if (obj == null) throw new ArgumentNullException("obj");
            if (propertyName == null) throw new ArgumentNullException("propertyName");

            return obj.GetType().GetProperty(propertyName).GetValue(obj);
        }

        public static string ResolvePropertyName<TEntity>(Expression<Func<TEntity, string>> propertySelector)
        {
            if (propertySelector == null) throw new ArgumentNullException("propertySelector");

            return ((MemberExpression)propertySelector.Body).Member.Name;
        }

        public static string GetColumnName(Type type, string propertyName)
        {
            if (type == null) throw new ArgumentNullException("type");
            if (propertyName == null) throw new ArgumentNullException("propertyName");

            var property = type.GetProperty(propertyName);
            if(property == null)
                throw new ArgumentException("Property not found: " + propertyName);
            
            string result;
            string key = type.FullName + "+" + propertyName;
            if (TypePropertyToColumnName.TryGetValue(key, out result)) return result;

            var column = property.GetCustomAttributes(false).OfType<ColumnAttribute>().SingleOrDefault();

            return TypePropertyToColumnName[key] = (column != null ? column.Name : propertyName).ToUpper();
        }

        public static string GetKeyColumnName(Type type)
        {
            if (type == null) throw new ArgumentNullException("type");

            string result;
            if (TypeToKeyColumnName.TryGetValue(type, out result)) return result;

            var key = GetKeyProperty(type);

            var column = key.GetCustomAttributes(false).OfType<ColumnAttribute>().SingleOrDefault();
            
            return TypeToKeyColumnName[type] = (column != null ? column.Name : key.Name).ToUpper();
        }

        public static object GetKeyValue(object obj)
        {
            if (obj == null) throw new ArgumentNullException("obj");

            var type = obj.GetType();
            var key = GetKeyProperty(type);            

            return key.GetValue(obj);
        }

        public static string GetTableName(Type type)
        {
            if (type == null) throw new ArgumentNullException("type");

            string result;
            if (TypeToTableName.TryGetValue(type, out result)) return result;

            var table = type.GetCustomAttributes(false).OfType<TableAttribute>().SingleOrDefault();

            return TypeToTableName[type] = (table != null ? table.Name : type.Name).ToUpper();
        }

        public static Type GetEntityType(object obj)
        {
            if (obj == null) throw new ArgumentNullException("obj");

            return ObjectContext.GetObjectType( obj.GetType());
        }

        public static string GetUniqueId(object obj)
        {
            if (obj == null) throw new ArgumentNullException("obj");

            return GetEntityType(obj).FullName + "+" + GetKeyValue(obj);
        }

        public static PropertyInfo GetKeyProperty(Type type)
        {
            if (type == null) throw new ArgumentNullException("type");

            PropertyInfo property;
            if (TypeToKeyProperty.TryGetValue(type, out property)) return property;

            var r = type.GetProperties().SingleOrDefault(a => a.GetCustomAttributes(false).OfType<KeyAttribute>().Any())
                                            ?? type.GetProperty("Id")
                                            ?? type.GetProperty(type.Name + "Id");

            if(r == null) throw new Exception("Unable to find appropriate key property");

            return TypeToKeyProperty[type] = r;
        }
    }
}