using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Extensions
{
    public static class DbContextExtensions
    {
        public static string GetDbIdentifier(this IDbContext dbContext)
        {
            return dbContext.SqlQuery<string>("select @@SERVERNAME + '.' + DB_NAME()").Single();
        }

        public static List<T> MapTo<T>(this SqlDataReader r) where T : new()
        {
            var result = new List<T>();

            var props = typeof(T).GetProperties(BindingFlags.Instance | BindingFlags.Public | BindingFlags.SetProperty);
            var map = new Dictionary<int, PropertyInfo>();

            while (r.Read())
            {
                var item = new T();

                for (int i = 0; i < r.FieldCount; i++)
                {
                    PropertyInfo prop;
                    if (!map.TryGetValue(i, out prop))
                    {
                        prop = props.FirstOrDefault(x => x.Name.Equals(r.GetName(i), StringComparison.InvariantCultureIgnoreCase));
                        map.Add(i, prop);
                    }

                    if (prop != null && r[i] != DBNull.Value)
                    {
                        var t = prop.PropertyType;
                        t = Nullable.GetUnderlyingType(t) ?? t;

                        prop.SetValue(item, Cast(r[i], t));
                    }
                }

                result.Add(item);
            }
            return result;
        }

        static object Cast(object val, Type t)
        {
            t = Nullable.GetUnderlyingType(t) ?? t;

            if (t.IsEnum && val is string)
            {
                var s = val.ToString();
                var names = t.GetEnumNames();
                var vals = t.GetEnumValues();

                for (int i = 0; i < names.Length; i++)
                {
                    if (string.Equals(names[i], s, StringComparison.CurrentCultureIgnoreCase))
                        return vals.GetValue(i);
                }

                if (s.Length == 1)
                {
                    // a bit of a stretch

                    for (int i = 0; i < names.Length; i++)
                    {
                        if (names[i].StartsWith(s))
                            return vals.GetValue(i);
                    }
                }
            }

            return Convert.ChangeType(val, t);
        }
    }
}
