using System.Collections.Generic;

namespace Inprotech.Integration.GoogleAnalytics.Parameters
{
    public class EventLabel : Parameter
    {
        public EventLabel(string value)
            : base(value)
        {
        }

        public override string Name => "el";

        public override List<string> SupportedHitTypes => new List<string> {HitTypes.Event};
    }
}