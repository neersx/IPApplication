using Inprotech.Infrastructure.Web;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Excel
{
    public interface ISimpleExcelExporter
    {
        HttpResponseMessage Export(PagedResults pagedResults, string fileName);

        Stream Export(IEnumerable<object> data);
    }

    public interface IDataConverter
    {
        object Convert(object o);
    }

    public class EnumToStringConverter : IDataConverter
    {
        public object Convert(object o)
        {
            if (o == null)
            {
                return null;
            }

            return Enum.GetName(o.GetType(), o);
        }
    }
}