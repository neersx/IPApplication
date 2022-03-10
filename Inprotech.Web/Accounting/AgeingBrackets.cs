using System;
using Newtonsoft.Json;

namespace Inprotech.Web.Accounting
{
    public class AgeingBrackets
    {
        public DateTime? BaseDate { get; set; }

        [JsonIgnore]
        public int? Bracket0 { get; set; }

        [JsonIgnore]
        public int? Bracket1 { get; set; }

        [JsonIgnore]
        public int? Bracket2 { get; set; }

        public int Current => Bracket0 ?? 30;
        public int Previous => Bracket1 ?? Current * 2;
        public int Last => Bracket2 ?? Previous + Previous - Current;
    }
}