using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace Inprotech.Web.FinancialReports
{
    public static class DataTableExtensions
    {
        const string DateFormatInferrableInExcel = "yyyy-MM-ddTHH:mm:ss";

        public static XElement XmlDataForExcel(this DataTable dataTable, string name)
        {
            var dataTableCopy = dataTable.Copy();
            var excelDateColumns = new Dictionary<string, string>();

            var dateColumns = dataTableCopy.Columns
                                           .Cast<DataColumn>()
                                           .Where(dc => dc.DataType == typeof(DateTime)).ToList();

            var stringColumns = dataTableCopy.Columns
                                             .Cast<DataColumn>()
                                             .Where(dc => dc.DataType == typeof(string)).ToList();

            stringColumns.ForEach(c => c.ReadOnly = false);

            foreach(var col in dateColumns)
            {
                var dcExcel = new DataColumn(col.ColumnName + "_Excel", typeof(string));
                dataTableCopy.Columns.Add(dcExcel);
                dcExcel.SetOrdinal(col.Ordinal);
                excelDateColumns.Add(col.ColumnName, dcExcel.ColumnName);
            }

            foreach(DataRow row in dataTableCopy.Rows)
            {
                foreach(var col in stringColumns)
                    SetEmptyStringWhenNull(row, col);

                foreach(var col in excelDateColumns)
                    SetInferrableDateFormatWhenNotNull(
                                                       row,
                                                       dataTableCopy.Columns[col.Key],
                                                       dataTableCopy.Columns[col.Value]);
            }

            foreach(var excelDateColumn in excelDateColumns)
            {
                dataTableCopy.Columns.Remove(excelDateColumn.Key);
                dataTableCopy.Columns[excelDateColumn.Value].ColumnName = excelDateColumn.Key;
            }

            return dataTableCopy.ToXElement(name);
        }

        static void SetEmptyStringWhenNull(DataRow row, DataColumn col)
        {
            if(row.IsNull(col))
                row.SetField(col.ColumnName, string.Empty);
        }

        static void SetInferrableDateFormatWhenNotNull(
            DataRow row,
            DataColumn originalColumn,
            DataColumn excelDateColumn)
        {
            if(!row.IsNull(originalColumn))
                row.SetField(
                             excelDateColumn,
                             row.Field<DateTime>(originalColumn).ToString(DateFormatInferrableInExcel));
        }

        static XElement ToXElement(this DataTable dataTable, string name)
        {
            using(var stringWriter = new StringWriter())
            {
                dataTable.WriteXml(stringWriter);
                var doc = XDocument.Load(new StringReader(stringWriter.ToString())).Root;
                doc.Name = name;
                return doc;
            }
        }
    }
}