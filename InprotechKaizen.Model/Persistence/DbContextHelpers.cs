using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Reflection;

namespace InprotechKaizen.Model.Persistence
{
    public static class DbContextHelpers
    {
        static IEnumerable<IModelBuilder> _cached = Enumerable.Empty<IModelBuilder>();

        internal static IEnumerable<IModelBuilder> ResolveModelBuilders()
        {
            if (!_cached.Any())
            {
                _cached = Assembly.GetExecutingAssembly()
                                  .GetExportedTypes()
                                  .Where(t => IsAssignableTo<IModelBuilder>(t) && t.IsClass && !t.IsAbstract)
                                  .Select(Activator.CreateInstance)
                                  .Cast<IModelBuilder>()
                                  .ToArray();
            }

            return _cached;
        }

        static bool IsAssignableTo<T>(Type @this)
        {
            if (@this == null) throw new ArgumentNullException(nameof(@this));

            return typeof(T).GetTypeInfo().IsAssignableFrom(@this.GetTypeInfo());
        }

        public static IEnumerable<T> ExecuteSqlQuery<T>(IDbContext dbContext, string command, params object[] arguments)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (command == null) throw new ArgumentNullException(nameof(command));

            var argumentNames = string.Join(", ", Enumerable.Range(0, arguments.Length).Select(i => "@p" + i));

            return dbContext.SqlQuery<T>($"EXEC {command} {argumentNames}", arguments).ToArray();
        }

        public static IEnumerable<T> ExecuteSqlQuery<T>(IDbContext dbContext, Func<IDataReader, T> map, string command, params object[] arguments)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (command == null) throw new ArgumentNullException(nameof(command));

            var argumentNames = string.Join(", ", Enumerable.Range(0, arguments.Length).Select(i => "@p" + i));
            var arguments2 = Enumerable.Range(0, arguments.Length).ToDictionary(i => "@p" + i, x => arguments[x] ?? DBNull.Value);

            using var dbCommand = dbContext.CreateSqlCommand($"EXEC {command} {argumentNames}", arguments2);
            using var reader = dbCommand.ExecuteReader();
            while (reader.Read()) yield return map(reader);
        }
    }

    public static class DataRecordExtension
    {
        public static T GetField<T>(this IDataRecord dataRecord, string name)
        {
            var ordinal = dataRecord.GetOrdinal(name);
            if (dataRecord.IsDBNull(ordinal)) return default;

            var o = dataRecord.GetValue(ordinal);

            return o is T t
                ? t
                : (T) Convert.ChangeType(o, typeof(T));
        }
    }
}