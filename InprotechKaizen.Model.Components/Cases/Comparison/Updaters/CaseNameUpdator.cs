using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface ICaseNameUpdator
    {
        void UpdateNameReferences(Case @case, IEnumerable<Components.Cases.Comparison.Results.CaseName> updatedData);
    }

    public class CaseNameUpdator : ICaseNameUpdator
    {
        public void UpdateNameReferences(Case @case, IEnumerable<Components.Cases.Comparison.Results.CaseName> caseNames)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (caseNames == null) throw new ArgumentNullException(nameof(caseNames));

            foreach (var n in caseNames)
            {
                if(n.Reference == null || !n.Reference.Updated) continue;

                var existing = @case.CaseNames.SingleOrDefault(o => n.NameId != null && o.NameId == n.NameId);
                if (existing != null)
                {
                    existing.Reference = n.Reference.TheirValue;
                }
            }
        }
    }
}
