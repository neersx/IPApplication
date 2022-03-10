using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Extensions;

namespace InprotechKaizen.Model.Components.Queries
{
    public class QueryResultIdCreator
    {
        static readonly Dictionary<string, Action<int, IDictionary<string, object>>> IdCreatorMap
            = new Dictionary<string, Action<int, IDictionary<string, object>>>(StringComparer.CurrentCultureIgnoreCase)
            {
                {"csw_ListCase", CaseSearchResultIdCreator}
            };

        static void CaseSearchResultIdCreator(int current, IDictionary<string, object> row)
        {
            if (!row.ContainsKey("CaseKey")) return;
            if (!row.ContainsKey("RowKey")) return;

            row["Id"] = $"{row["CaseKey"]}_{row["RowKey"]}";
        }

        static void GenericIdCreator(int current, IDictionary<string, object> row)
        {
            if (row.ContainsKey("RowKey")) return;

            row["RowKey"] = current;
        }

        public static Action<int, Dictionary<string,object>> Resolve(string procedureName)
        {
            if (string.IsNullOrWhiteSpace(procedureName)) throw new ArgumentNullException(nameof(procedureName));

            return IdCreatorMap.Get(procedureName) ?? GenericIdCreator;
        }
    }
}