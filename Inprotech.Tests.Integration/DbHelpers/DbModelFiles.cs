using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

namespace Inprotech.Tests.Integration.DbHelpers
{
    static class DbModelFiles
    {
        const string includedTables = "IncludedTables.json";
        const string sorted = "Sorted.json";

        public static void Remove()
        {
            File.Delete(includedTables);
            File.Delete(sorted);

        }

        public static void WriteIncludedTables(List<string> IncludedTables)
        {
            File.WriteAllText(includedTables, JsonConvert.SerializeObject(IncludedTables));
        }

        public static void WriteSorted(List<string> Sorted)
        {
            File.WriteAllText(sorted, JsonConvert.SerializeObject(Sorted));
        }
        public static List<string> GetIncludedTables()
        {
            return JsonConvert.DeserializeObject<List<string>>(File.ReadAllText(includedTables));
        }

        public static List<string> GetSorted()
        {
            return JsonConvert.DeserializeObject<List<string>>(File.ReadAllText(sorted));
        }

        public static bool Exists()
        {
            return File.Exists(includedTables) && File.Exists(sorted);
        }
    }
}
