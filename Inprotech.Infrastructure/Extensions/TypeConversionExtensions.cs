using System;

namespace Inprotech.Infrastructure.Extensions
{
    public static class TypeConversionExtensions
    {
        public static object GetValue(string value, Type type)
        {
            if (string.IsNullOrEmpty(value)) return GetDefault(type);

            return Convert.ChangeType(value, Nullable.GetUnderlyingType(type) ?? type);
        }
        public static T GetValue<T>(string value)
        {
            if (string.IsNullOrEmpty(value)) return default(T);

            var t = typeof(T);
            return (T)Convert.ChangeType(value, Nullable.GetUnderlyingType(t) ?? t);
        }
        public static object GetDefault(Type type)
        {
            if (type.IsValueType)
            {
                return Activator.CreateInstance(type);
            }
            return null;
        }
    }
}