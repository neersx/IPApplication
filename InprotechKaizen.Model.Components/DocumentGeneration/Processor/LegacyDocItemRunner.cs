using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor.RunMappers;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public interface ILegacyDocItemRunner
    {
        IEnumerable<TableResultSet> Execute(ReferencedDataItem referencedDataItem, string parameters, string entryPointValue, RowsReturnedMode rowsReturnedMode);
        RunDocItemParams GetDocItemSiteControls();
    }

    public class LegacyDocItemRunner : ILegacyDocItemRunner
    {
        readonly RunQueryMapper _runQueryMapper;
        readonly RunStoredProcedureMapper _runStoredProcedureMapper;
        readonly ISiteControlReader _siteControls;

        public LegacyDocItemRunner(RunQueryMapper runQueryMapper,
                                    RunStoredProcedureMapper runStoredProcedureMapper,
                                    ISiteControlReader siteControls)
        {
            _runQueryMapper = runQueryMapper;
            _runStoredProcedureMapper = runStoredProcedureMapper;
            _siteControls = siteControls;
        }

        public IEnumerable<TableResultSet> Execute(ReferencedDataItem referencedDataItem, string parameters, string entryPointValue, RowsReturnedMode rowsReturnedMode)
        {
            if (!referencedDataItem.ItemType.HasValue)
            {
                return Enumerable.Empty<TableResultSet>();
            }

            var docItemParams = GetDocItemSiteControls();
            
            DataSet dataSet = null;
            if (referencedDataItem.ItemType == (int) DataItemType.SqlStatement)
            {
                dataSet = _runQueryMapper.Execute(referencedDataItem.SqlQuery, parameters, entryPointValue, docItemParams);
            }
            else if (referencedDataItem.ItemType == DataItemType.StoredProcedure)
            {
                dataSet = _runStoredProcedureMapper.Execute(referencedDataItem.SqlQuery, parameters, entryPointValue, docItemParams);
            }

            return ConvertToTableResultSet(docItemParams, dataSet, rowsReturnedMode);
        }

        public RunDocItemParams GetDocItemSiteControls()
        {
            var asNull = _siteControls.Read<int?>(SiteControls.DocItemSetNullIntoBookmark);

            return new RunDocItemParams
            {
                DateStyle = _siteControls.Read<int>(SiteControls.DateStyle),
                EmptyParamsAsNulls = _siteControls.Read<bool>(SiteControls.DocItemEmptyParamsAsNulls),
                SingleSpaceBookmarksAsNull = !asNull.HasValue || asNull.Value == 1,
                CommandTimeout = _siteControls.Read<int>(SiteControls.DocItemsCommandTimeout),
                ConcatNullYieldsNull = _siteControls.Read<bool>(SiteControls.DocItemConcatNull)
            };
        }

        IEnumerable<TableResultSet> ConvertToTableResultSet(RunDocItemParams docItemParams, DataSet dataSet, RowsReturnedMode rowsReturnedMode)
        {
            if (dataSet == null || dataSet.Tables.Count == 0)
            {
                yield break;
            }

            foreach (DataTable dataTable in dataSet.Tables)
            {
                var tableResultSet = new TableResultSet
                {
                    Name = dataTable.TableName,
                    ColumnResultSets = new List<ColumnResultSet>(),
                    RowResultSets = new List<RowResultSet>()
                };

                foreach (DataColumn dataColumn in dataTable.Columns)
                {
                    var columnResultSet = new ColumnResultSet
                    {
                        Name = dataColumn.ColumnName,
                        Type = dataColumn.DataType.ToString()
                    };
                    tableResultSet.ColumnResultSets.Add(columnResultSet);
                }

                foreach (DataRow dataRow in dataTable.Rows)
                {
                    var rowResultSet = new RowResultSet {Values = new List<object>()};
                    foreach (var value in dataRow.ItemArray)
                    {
                        if (!(value is DBNull) && value != null)
                        {
                            rowResultSet.Values.Add(value);
                        }
                        else
                        {
                            rowResultSet.Values.Add(docItemParams.SingleSpaceBookmarksAsNull ? string.Empty : " ");
                        }
                    }

                    tableResultSet.RowResultSets.Add(rowResultSet);

                    if (rowsReturnedMode == RowsReturnedMode.Single)
                    {
                        break;
                    }
                }

                yield return tableResultSet;
            }
        }
    }
}