using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using InprotechKaizen.Model;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations
{
    public class Generator
    {
        IEnumerable<Update> GetUpdate()
        {
            var scripts = File.ReadAllLines(@"c:\temp\temp.txt");

            var update = new Update();

            foreach (var line in scripts)
            {
                if (string.IsNullOrWhiteSpace(update.Table) && line.Contains("update "))
                {
                    update.Table = Regex.Replace(line.Replace("update", ""), "[^a-zA-Z0-9]", "");
                    continue;
                }

                if (string.IsNullOrWhiteSpace(update.Column) && line.Contains("@pnNameNoConsolidateTo"))
                {
                    update.Column = Regex.Replace(line.Replace("set ", "").Replace("=@pnNameNoConsolidateTo", ""), "[^a-zA-Z0-9]", "");
                    continue;
                }

                if (!string.IsNullOrWhiteSpace(update.Table) && !string.IsNullOrWhiteSpace(update.Column))
                {
                    yield return update;
                }

                update = new Update();
            }
        }

        public class Update
        {
            public string Table { get; set; }
            public string Column { get; set; }

            public bool AllGood => !string.IsNullOrWhiteSpace(Table) && !string.IsNullOrWhiteSpace(Column);
        }

        [Fact]
        public void GenerateStatements()
        {
            var modelTypes = typeof(MainModule).Assembly.GetTypes().Where(_ => CustomAttributeExtensions.GetCustomAttributes<TableAttribute>((MemberInfo) _).Any())
                                               .OrderBy(k => k.GetCustomAttribute<TableAttribute>().Name)
                                               .ToDictionary(k => k.GetCustomAttribute<TableAttribute>().Name, v => v);

            var list = new List<string>();

            var list2 = new List<string>();
            var missingTable = new List<Update>();
            var missingColumn = new List<Update>();

            foreach (var update in GetUpdate())
            {
                if (!modelTypes.TryGetValue(update.Table, out var table))
                {
                    missingTable.Add(update);
                    continue;
                    //Assert.Equal(update.Table, null);
                }

                var columnTypes = table.GetProperties()
                                       .Where(_ => _.GetCustomAttributes<ColumnAttribute>().Any())
                                       .ToDictionary(k => k.GetCustomAttribute<ColumnAttribute>().Name, v => v.Name);

                if (!columnTypes.TryGetValue(update.Column, out var propertyName))
                {
                    missingColumn.Add(update);
                    continue;
                    //Assert.Equal(update.Table + "." + update.Column, null);
                }

                var propertyNameForMethod = propertyName;
                if (propertyName.EndsWith("Id"))
                {
                    propertyNameForMethod = propertyNameForMethod.TrimEnd('d').TrimEnd('I');
                }

                if (propertyName.EndsWith("No"))
                {
                    propertyNameForMethod = propertyNameForMethod.TrimEnd('o').TrimEnd('N');
                }

                var methodName = $"Update{table.Name}{propertyNameForMethod}";

                list.Add($"async Task {methodName}(Name to, Name from)");
                list.Add("{");
                list.Add($"await _dbContext.UpdateAsync(from _ in _dbContext.Set<{table.Name}>() where _.{propertyName} == @from.Id select _, _ => new {table.Name} {{ {propertyName} = to.Id }});");
                list.Add("}");
                list.Add("");

                list2.Add($"await {methodName}(to, from);");
                list2.Add("");
            }

            File.WriteAllText(@"c:\temp\missingtable.json", JsonConvert.SerializeObject(missingTable, Formatting.Indented));
            File.WriteAllText(@"c:\temp\missingcolumn.json", JsonConvert.SerializeObject(missingColumn, Formatting.Indented));

            File.WriteAllLines(@"c:\temp\output.txt", list);
            File.WriteAllLines(@"c:\temp\output2.txt", list2);
        }

        [Fact]
        public void GenerateFacts()
        {
            var modelTypes = typeof(MainModule).Assembly.GetTypes().Where(_ => CustomAttributeExtensions.GetCustomAttributes<TableAttribute>((MemberInfo)_).Any())
                                               .OrderBy(k => k.GetCustomAttribute<TableAttribute>().Name)
                                               .ToDictionary(k => k.GetCustomAttribute<TableAttribute>().Name, v => v);

            var list = new List<string>();
            
            foreach (var update in GetUpdate())
            {
                var table = modelTypes[update.Table];

                var columnTypes = table.GetProperties()
                                       .Where(_ => _.GetCustomAttributes<ColumnAttribute>().Any())
                                       .ToDictionary(k => k.GetCustomAttribute<ColumnAttribute>().Name, v => v.Name);

                var propertyName = columnTypes[update.Column];
                var propertyNameForMethod = propertyName;
                if (propertyName.EndsWith("Id"))
                {
                    propertyNameForMethod = propertyNameForMethod.TrimEnd('d').TrimEnd('I');
                }

                if (propertyName.EndsWith("No"))
                {
                    propertyNameForMethod = propertyNameForMethod.TrimEnd('o').TrimEnd('N');
                }

                var methodName = $"{table.Name}{propertyNameForMethod}";

                list.Add("[Fact]");
                list.Add($"public async Task ShouldUpdate{methodName}()");
                list.Add("{");
                list.Add("");
                list.Add($"   var a = new {table.Name} {{ {propertyName} = from.Id }}.In(Db);");
                list.Add("");
                list.Add($"   await _subject.Consolidate(to, from, _option);");
                list.Add("");
                list.Add($"   Assert.Equal(to.Id, a.{propertyName});");
                list.Add("}");
                list.Add("");
            }

            File.WriteAllLines(@"c:\temp\output.txt", list);
        }
    }
}