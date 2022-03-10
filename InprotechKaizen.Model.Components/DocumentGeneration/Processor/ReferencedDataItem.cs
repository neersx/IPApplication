using System;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public enum DataItemType
    {
        SqlStatement = 0,
        StoredProcedure = 1
    }

    public class ReferencedDataItem : IEquatable<ReferencedDataItem>
    {
        public int ItemKey { get; set; }
        public string ItemName { get; set; }
        public string ItemDescription { get; set; }
        public int? EntryPointUsage { get; set; }
        public string SqlQuery { get; set; }
        public DataItemType? ItemType { get; set; }

        public bool Equals(ReferencedDataItem other)
        {
            if (other == null)
            {
                return false;
            }
            return ItemName.Equals(other.ItemName, StringComparison.InvariantCulture);
        }
    }
}
