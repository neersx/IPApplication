using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.Entity.Core.Metadata.Edm;
using System.Data.Entity.Infrastructure;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers
{
    internal static class AutoDbCleaner
    {
        static readonly List<string> IncludedTables;
        static readonly List<string> Sorted;

        static readonly IEnumerable<string> IgnoredTables = new[]
                                                            {
                                                                "EVENTUPDATEPROFILE",
                                                                "TABLETYPE",
                                                                "CASEEVENT_ILOG"
                                                            }.Select(_ => _.ToLower());

        static readonly IEnumerable<string> DelayedTables = new[]
        {
            "WIPTEMPLATE",
            "WIPCATEGORY",
            "WIPTYPE"
        }.Select(_ => _.ToLower());

        static AutoDbCleaner()
        {
            if (Env.UseDevelopmentHost && DbModelFiles.Exists())
            {
                IncludedTables = DbModelFiles.GetIncludedTables();
                Sorted = DbModelFiles.GetSorted();
                return;
            }
            IncludedTables = GetAllTablesInDbContext()
                             .Where(x => !IgnoredTables.Contains(x.ToLower()) && !DelayedTables.Contains(x.ToLower()))
                                                      .ToList();
            var dependencyTrees = LoadTables();
            Sorted = new TopologicalSort().Sort(dependencyTrees)
                                              .OfType<Table>()
                                              .Select(x => x.Name)
                                              .ToList();

            Sorted.AddRange(DelayedTables);
        }

        public static void Assm()
        {
            DbModelFiles.WriteIncludedTables(IncludedTables);
            DbModelFiles.WriteSorted(Sorted);
        }

        public static void Cleanup()
        {
            Delete(Sorted);
        }

        static void Delete(IEnumerable<string> tables)
        {
            const int chunks = 20;
            var watch = Stopwatch.StartNew();

            while (tables.Any())
            {
                try
                {
                    BulkDelete(tables.Take(chunks));
                }
                catch (SqlException ex) when (ex.Message.StartsWith("Timeout expired"))
                {
                    watch.Stop();
                    throw new AutoDbCleanupTimeoutException(watch.ElapsedMilliseconds, ex);
                }
                tables = tables.Skip(chunks);
            }
        }

        static void BulkDelete(IEnumerable<string> tables)
        {
            var deletes = new List<string>();
            foreach (var table in tables)
                deletes.Add($"DELETE {table} WHERE CreatedByE2E = 1");

            var sql = string.Join("\n", deletes);
            ExecuteSql(sql, command => { command.ExecuteNonQuery(); });
        }

        static List<Table> LoadTables()
        {
            var sql =
                @"SELECT 
    DISTINCT a.name AS [Table], object_name(k.referenced_object_id) as [ReferencedTable]
	FROM sys.tables AS a
	LEFT JOIN sys.foreign_keys AS k
	ON a.object_id = k.parent_object_id
    WHERE EXISTS (
	    SELECT * FROM sys.columns AS b
	    WHERE a.object_id = b.object_id AND b.name = 'LOGDATETIMESTAMP')
	ORDER BY a.name";

            var list = new List<Tuple<string, string>>();
            ExecuteSql(sql, command =>
                            {
                                using (var reader = command.ExecuteReader())
                                {
                                    while (reader.Read())
                                    {
                                        var table = NormalizeTableName((string) reader["Table"]);
                                        var referenced = reader["ReferencedTable"] == DBNull.Value ? null : NormalizeTableName((string) reader["ReferencedTable"]);

                                        list.Add(Tuple.Create(table, referenced));
                                    }
                                }
                            });

            var allTableNames = list.Select(x => x.Item1)
                                    .Union(list.Select(x => x.Item2))
                                    .Where(x => x != null)
                                    .Distinct()
                                    .ToList();

            var tablesByName = allTableNames.ToDictionary(x => x, x => new Table {Name = x});

            foreach (var parent in list.Where(x => x.Item2 != null).Select(x => x.Item2).Distinct())
            {
                var parentTable = tablesByName[parent];

                foreach (var child in list.Where(x => x.Item2 == parent).Select(x => x.Item1))
                {
                    var childTable = tablesByName[child];
                    parentTable.ReferencedTables.Add(childTable);
                }
            }

            return (from t in tablesByName
                    join a in IncludedTables on t.Key equals a
                    select t.Value).ToList();
        }

        static string NormalizeTableName(string tableName)
        {
            return tableName.ToUpper();
        }

        static SqlConnection GetConnection()
        {
            var connStr = GetConnectionString();

            return new SqlConnection(connStr);
        }

        static string GetConnectionString()
        {
            return ConfigurationManager.ConnectionStrings["Inprotech"].ConnectionString;
        }

        [SuppressMessage("Microsoft.Security", "CA2100:Review SQL queries for security vulnerabilities")]
        static void ExecuteSql(string sql, Action<SqlCommand> action)
        {
            using (var connection = GetConnection())
            using (var command = new SqlCommand(sql, connection))
            {
                connection.Open();
                action(command);
            }
        }

        static IEnumerable<string> GetAllTablesInDbContext()
        {
            //https://romiller.com/2012/04/20/what-tables-are-in-my-ef-model-and-my-database/
            var context = new SqlDbContext();
            var metadata = ((IObjectContextAdapter) context).ObjectContext.MetadataWorkspace;

            var tables = metadata.GetItemCollection(DataSpace.SSpace)
                                 .GetItems<EntityContainer>()
                                 .Single()
                                 .BaseEntitySets
                                 .OfType<EntitySet>()
                                 .Where(s => !s.MetadataProperties.Contains("Type")
                                             || s.MetadataProperties["Type"].ToString() == "Tables");

            var result = new List<string>();
            foreach (var table in tables)
            {
                var tableName = table.MetadataProperties.Contains("Table")
                                && table.MetadataProperties["Table"].Value != null
                    ? table.MetadataProperties["Table"].Value.ToString()
                    : table.Name;

                result.Add(NormalizeTableName(tableName));
            }

            return result;
        }

        class Table : ITopoSortable
        {
            public string Name { get; set; }

            public List<Table> ReferencedTables { get; }

            public Table()
            {
                ReferencedTables = new List<Table>();
            }

            public IEnumerable<ITopoSortable> Dependencies => ReferencedTables;

            public override string ToString()
            {
                return Name;
            }
        }
    }

    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class AutoDbCleanupTimeoutException : Exception
    {
        public AutoDbCleanupTimeoutException(long milliseconds, SqlException ex) : base($"Operation timed out after {milliseconds} milliseconds.", ex)
        {
        }
    }
}