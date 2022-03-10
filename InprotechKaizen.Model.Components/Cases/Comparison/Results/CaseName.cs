namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class CaseName
    {
        public string NameTypeId { get; set; }

        public int? NameId { get; set; }

        public short? Sequence { get; set; }

        public string NameType { get; set; }

        public Value<string> Name { get; set; }

        public Value<string> Address { get; set; }

        public Value<string> Reference { get; set; }
    }
}