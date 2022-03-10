using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;

namespace InprotechKaizen.Model.Persistence
{
    public class Parameters : Dictionary<string, object>
    {
        public Parameters()
        {
        }

        public Parameters(IDictionary<string, object> dictionary) : base(dictionary)
        {
        }

        public Parameters(IEnumerable<KeyValuePair<string, object>> items)
            : base(items.ToDictionary(i => i.Key, i => i.Value))
        {

        }
    }

    public static class SqlParameterExtension
    {
        public static T GetValueOrDefault<T>(this SqlParameter parameter)
        {
            return (parameter.Value == null || parameter.Value is DBNull) ? default(T) : (T) parameter.Value;
        }
    }
}