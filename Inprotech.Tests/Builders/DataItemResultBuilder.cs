using System.Data;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.Builders
{
    public class DataItemResultBuilder<T> : IBuilder<DataSet>
    {
        public T ScalarResult { get; set; }

        public DataItemResultBuilder()
        {
            
        }

        public DataItemResultBuilder(T scalarResult)
        {
            ScalarResult = scalarResult;
        }

        public DataSet Build()
        {
            var dataSet = new DataSet();
            var dataTable = new DataTable();
            dataTable.Columns.Add(new DataColumn());
            dataTable.Rows.Add(ScalarResult);
            dataSet.Tables.Add(dataTable);
            return dataSet;
        }
    }
}