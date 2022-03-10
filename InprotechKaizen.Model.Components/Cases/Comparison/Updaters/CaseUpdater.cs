using System;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using Case = InprotechKaizen.Model.Cases.Case;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface ICaseUpdater
    {
        void UpdateTitle(Case @case, Components.Cases.Comparison.Results.Case comparedCase);
        void UpdateTypeOfMark(Case @case, Components.Cases.Comparison.Results.Case comparedCase);
    }

    public class CaseUpdater : ICaseUpdater
    {
        public void UpdateTitle(Case @case, Components.Cases.Comparison.Results.Case comparedCase)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparedCase == null) throw new ArgumentNullException(nameof(comparedCase));

            @case.Title = ValueExt.UpdatedOrDefault(comparedCase.Title, @case.Title);
        }

        public void UpdateTypeOfMark(Case @case, Components.Cases.Comparison.Results.Case comparedCase)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparedCase == null) throw new ArgumentNullException(nameof(comparedCase));

            @case.TypeOfMarkId = int.TryParse(ValueExt.UpdatedOrDefault(comparedCase.TypeOfMark, @case.TypeOfMarkId?.ToString()), out int v) ? (int?) v : null;
        }
    }
}