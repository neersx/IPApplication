using System.Collections.Generic;

namespace Inprotech.Integration.Names.Consolidations
{
    public class NameConsolidationArgs
    {
        public NameConsolidationArgs()
        {
            NameIds = new int[0];
        }

        public int ExecuteAs { get; set; }

        public int TargetId { get; set; }

        public bool KeepTelecomHistory { get; set; }

        public bool KeepAddressHistory { get; set; }

        public bool KeepConsolidatedName { get; set; }

        public IEnumerable<int> NameIds { get; set; }
    }
}