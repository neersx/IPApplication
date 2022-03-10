using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Translations
{
    interface ITidColumnLoader
    {
        IDictionary<object, IDictionary<string, int>> Load(
            IDictionary<Type, IEnumerable<object>> entitiesMap,
            IDictionary<Type, IEnumerable<string>> tidColumnsMap);
    }

    class TidColumnLoader : ITidColumnLoader
    {
        readonly IDbContext _dbContext;

        public TidColumnLoader(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public IDictionary<object, IDictionary<string, int>> Load(
            IDictionary<Type, IEnumerable<object>> entitiesMap,
            IDictionary<Type, IEnumerable<string>> tidColumnsMap)
        {
            var result = new Dictionary<object, IDictionary<string, int>>();
            var types = tidColumnsMap.Keys.ToList();
            if (!types.Any()) return result;

            var typeToKeyName = types.ToDictionary(a => a, Utilities.GetKeyColumnName);
            var typeToKeyParameters = types.ToDictionary(a => a, a => entitiesMap[a].Select((b, i) => "@" + Utilities.GetTableName(a) + i));
            var query = string.Join("\n", types.Select(a => BuildQuery(a, tidColumnsMap[a], typeToKeyParameters[a])));
            var keyToEntity = new Dictionary<Type, Dictionary<object, object>>();
            
            foreach (var type in types)
            {
                var entities = entitiesMap[type].ToArray();
                var map = new Dictionary<object, object>();
                foreach (var entity in entities)
                    map[Utilities.GetKeyValue(entity)] = entity;

                keyToEntity[type] = map;
            }

            var keyValues = types.SelectMany(type => typeToKeyParameters[type].Zip(entitiesMap[type], (s, o) => new { Key = s, Value = Utilities.GetKeyValue(o) }))
                .ToDictionary(a => a.Key, a => a.Value);

            using (var command = _dbContext.CreateSqlCommand(query, keyValues))
            using (var reader = command.ExecuteReader())
            {
                var iterator = types.GetEnumerator();
                while (reader.HasRows && iterator.MoveNext())
                {
                    var type = iterator.Current;

                    while (reader.Read())
                    {
                        var key = reader[typeToKeyName[type]];
                        var entity = keyToEntity[type][key];
                        var map = new Dictionary<string, int>();

                        foreach (var column in tidColumnsMap[type])
                        {
                            var tid = reader[column];
                            if (tid == null || tid == DBNull.Value) continue;

                            map[column] = (int) tid;
                        }

                        result[entity] = map;
                    }

                    reader.NextResult();
                }
            }

            return result;
        }

        static string BuildQuery(Type type, IEnumerable<string> tidColumns, IEnumerable<string> parameters)
        {
            var tableName = Utilities.GetTableName(type);
            var keyColumn = Utilities.GetKeyColumnName(type);

            return string.Format(
                "SELECT {0}, {1} FROM {2} WHERE {0} IN ({3});",
                keyColumn,
                string.Join(", ", tidColumns),
                tableName,
                string.Join(", ", parameters));
        }
    }
}