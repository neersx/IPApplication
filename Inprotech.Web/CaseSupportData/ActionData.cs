namespace Inprotech.Web.CaseSupportData
{
    public class ActionData
    {
        public int Id { get; set; }

        short? _cycles;

        public string Code { get; set; }

        public string Name { get; set; }

        public string BaseName { get; set; }

        public decimal? ActionType { get; set; }

        public string ImportanceLevel { get; set; }

        public int IsDefaultJurisdiction { get; set; }

        public short? Cycles
        {
            get => _cycles.GetValueOrDefault(1);
            set => _cycles = value;
        }

        public short? Cycle { get; set; }

        public bool? IsOpen { get; set; }
        public bool? IsClosed { get; set; }

        public bool? IsPotential { get; set; }

        public bool? HasEventsWithNotes { get; set; }

        public string Status { get; set; }

        public int? CriteriaId { get; set; }
        public short? DisplaySequence { get; set; }

        public int? ImportanceLevelNumber
        {
            get
            {
                if (int.TryParse(ImportanceLevel, out int imp))
                    return imp;
                return null;
            }
        }

        public bool? HasEditableCriteria { get; set; }
    }
}