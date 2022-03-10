using System.Collections.Generic;

namespace Inprotech.Integration.Names.Consolidations
{
    public class NameConsolidationStatus
    {
        public NameConsolidationStatus()
        {
            NamesConsolidated = new HashSet<int>();
            Errors = new Dictionary<int, string>();
        }

        public bool IsCompleted { get; set; }

        public int NumberOfNamesToConsolidate { get; set; }

        public HashSet<int> NamesConsolidated { get; set; }

        public Dictionary<int, string> Errors { get; set; }
    }
}