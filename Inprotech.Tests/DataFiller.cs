using System;
using System.Reflection;

namespace Inprotech.Tests
{
    public static class DataFiller
    {
        public static void Fill<T>(T model)
        {
            var type = typeof(T);
            foreach (var prop in type.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty))
            {
                if (!prop.CanWrite || !prop.GetSetMethod(true).IsPublic) continue;

                var propertyType = prop.PropertyType;
                if (typeof(string).IsAssignableFrom(propertyType))
                {
                    prop.SetValue(model, Fixture.String());
                }
                else if (typeof(int).IsAssignableFrom(propertyType) || typeof(int?).IsAssignableFrom(propertyType))
                {
                    prop.SetValue(model, Fixture.Integer());
                }
                else if (typeof(short).IsAssignableFrom(propertyType) || typeof(short?).IsAssignableFrom(propertyType))
                {
                    prop.SetValue(model, Fixture.Short());
                }
                else if (typeof(bool).IsAssignableFrom(propertyType) || typeof(bool?).IsAssignableFrom(propertyType))
                {
                    prop.SetValue(model, Fixture.Boolean());
                }
                else if (typeof(decimal).IsAssignableFrom(propertyType) || typeof(decimal?).IsAssignableFrom(propertyType))
                {
                    prop.SetValue(model, Fixture.Decimal());
                }
                else if (typeof(DateTime).IsAssignableFrom(propertyType) || typeof(DateTime?).IsAssignableFrom(propertyType))
                {
                    prop.SetValue(model, Fixture.Today());
                }
                else if (typeof(byte[]).IsAssignableFrom(propertyType))
                {
                    prop.SetValue(model, Fixture.RandomBytes(Fixture.Short()));
                }
            }
        }
    }
}