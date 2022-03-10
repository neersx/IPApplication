using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Components.DocumentGeneration.Services;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public class ItemProcessor : IEquatable<ItemProcessor>
    {
        public string ID { get; set; }

        // request

        public List<Field> Fields { get; set; }
        public ReferencedDataItem ReferencedDataItem { get; set; }
        public string Separator { get; set; }
        public string Parameters { get; set; }
        public RowsReturnedMode RowsReturnedMode { get; set; }
        public string EntryPointValue { get; set; }

        // response

        public string EmptyValue { get; set; }
        public int DateStyle { get; set; }
        public List<TableResultSet> TableResultSets { get; set; }
        public Exception Exception { get; set; }

        public bool Equals(ItemProcessor other)
        {
            if (other == null)
            {
                return false;
            }

            if (ReferencedDataItem != null && other.ReferencedDataItem == null ||
                ReferencedDataItem == null && other.ReferencedDataItem != null)
            {
                return false;
            }

            if (!string.Equals(ReferencedDataItem?.ItemName, other.ReferencedDataItem?.ItemName))
            {
                return false;
            }

            if (!string.IsNullOrEmpty(Parameters) && string.IsNullOrEmpty(other.Parameters) || string.IsNullOrEmpty(Parameters) && !string.IsNullOrEmpty(other.Parameters))
            {
                return false;
            }

            if (RowsReturnedMode != other.RowsReturnedMode)
            {
                return false;
            }

            return Parameters.Equals(other.Parameters, StringComparison.InvariantCulture);
        }
    }
}