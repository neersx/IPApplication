using System.Collections.Generic;

namespace Inprotech.Integration.DmsIntegration.Component.Domain
{
    public class DmsSearchCriteria
    {
        public DmsSearchCriteria()
        {
            NameEntity = new DmsNameEntity();
            CaseNameEntities = new List<DmsNameEntity>();
        }

        public int? CaseKey { get; set; }

        public string CaseReference { get; set; }

        public DmsNameEntity NameEntity { get; set; }

        public IList<DmsNameEntity> CaseNameEntities { get; set; }
    }
}
