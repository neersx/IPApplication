using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Components.Configuration.Extensions
{
    public static class TableCodesExtension
    {
        public static IEnumerable<TableCode> For(this IEnumerable<TableCode> tableCodes, TableTypes tableType)
        {
            return tableCodes.Where(tc => tc.TableTypeId == (int)tableType);
        }
    }
}