using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Cases.Restrictions
{
    public class CaseNameRestriction
    {
        public CaseNameRestriction(CaseName caseName, DebtorStatus status)
        {
            CaseName = caseName;
            Status = status;
        }

        public CaseName CaseName { get; private set; }
        public DebtorStatus Status { get; private set; }
    }
}